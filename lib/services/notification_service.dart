import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_expenses_plan/core/constants/app_constants.dart';
import 'package:smart_expenses_plan/data/models/payment_plan_model.dart';
import 'package:smart_expenses_plan/data/models/expense_model.dart';
import 'package:smart_expenses_plan/data/repositories/payment_repository.dart';
import 'package:smart_expenses_plan/data/repositories/expense_repository.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();
    
    // Request permissions
    await requestPermissions();
    
    // Android settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    // Create notification channels
    await _createNotificationChannels();
  }

  static Future<void> requestPermissions() async {
    try {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
          
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } catch (e) {
      print('NotificationService: Failed to request permissions: $e');
      // Continue without permissions if request fails
    }
  }

  static Future<void> _createNotificationChannels() async {
    final prefs = await SharedPreferences.getInstance();
    final bool soundEnabled = prefs.getBool('sound_enabled') ?? true;
    final bool vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;

    // Payment reminders channel
    final AndroidNotificationChannel paymentChannel = AndroidNotificationChannel(
      AppConstants.paymentChannelId,
      AppConstants.paymentChannelName,
      description: 'Notifications for payment reminders',
      importance: Importance.high,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
    );
    
    // Expense reminders channel
    final AndroidNotificationChannel expenseChannel = AndroidNotificationChannel(
      AppConstants.expenseChannelId,
      AppConstants.expenseChannelName,
      description: 'Notifications for expense reminders',
      importance: Importance.high,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
    );
    
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(paymentChannel);
        
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(expenseChannel);
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
  }

  static Future<void> schedulePaymentReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final bool soundEnabled = prefs.getBool('sound_enabled') ?? true;
    final bool vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;

    final androidDetails = AndroidNotificationDetails(
      AppConstants.paymentChannelId,
      AppConstants.paymentChannelName,
      importance: Importance.high,
      priority: Priority.high,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> scheduleExpenseReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final bool soundEnabled = prefs.getBool('sound_enabled') ?? true;
    final bool vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;

    final androidDetails = AndroidNotificationDetails(
      AppConstants.expenseChannelId,
      AppConstants.expenseChannelName,
      importance: Importance.high,
      priority: Priority.high,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  static Future<void> scheduleAutoPaymentReminder(PaymentPlanModel payment) async {
    if (!payment.reminderEnabled || payment.id == null || payment.status == 'paid') return;

    final prefs = await SharedPreferences.getInstance();
    final bool paymentEnabled = prefs.getBool('payment_reminders') ?? true;
    if (!paymentEnabled) return;

    final int hoursBefore = prefs.getInt('reminder_time') ?? 1;
    DateTime scheduledDate = payment.paymentDate.subtract(Duration(hours: hoursBefore));

    // If scheduled date is in the past
    if (scheduledDate.isBefore(DateTime.now())) {
      // If the actual payment date is still in the future, schedule for 1 minute from now
      if (payment.paymentDate.isAfter(DateTime.now())) {
        scheduledDate = DateTime.now().add(const Duration(minutes: 1));
        print('NotificationService: Reminder time passed for ${payment.payName}, scheduling for immediate reminder');
      } else {
        print('NotificationService: Both reminder and payment date passed for ${payment.payName}, skipping');
        return;
      }
    }

    await schedulePaymentReminder(
      id: payment.id!,
      title: 'Upcoming Payment: ${payment.payName}',
      body: 'You have a payment of ${payment.currency} ${payment.amount} due soon.',
      scheduledDate: scheduledDate,
    );
  }

  static Future<void> scheduleAutoExpenseReminder(ExpenseModel expense) async {
    if (!expense.reminderEnabled || expense.id == null) return;

    final prefs = await SharedPreferences.getInstance();
    final bool expenseEnabled = prefs.getBool('expense_reminders') ?? true;
    if (!expenseEnabled) return;

    final int hoursBefore = prefs.getInt('reminder_time') ?? 1;
    DateTime scheduledDate = expense.expenseDate.subtract(Duration(hours: hoursBefore));

    // If scheduled date is in the past
    if (scheduledDate.isBefore(DateTime.now())) {
      // If the actual expense date is still in the future, schedule for 1 minute from now
      if (expense.expenseDate.isAfter(DateTime.now())) {
        scheduledDate = DateTime.now().add(const Duration(minutes: 1));
        print('NotificationService: Reminder time passed for ${expense.name}, scheduling for immediate reminder');
      } else {
        print('NotificationService: Both reminder and expense date passed for ${expense.name}, skipping');
        return;
      }
    }

    await scheduleExpenseReminder(
      id: expense.id! + 20000, // Offset for expenses
      title: 'Upcoming Expense: ${expense.name}',
      body: 'Your expense "${expense.name}" for TZS ${expense.amount} is coming up.',
      scheduledDate: scheduledDate,
    );
  }

  static Future<void> rescheduleAllReminders() async {
    await cancelAll();
    
    final paymentRepo = PaymentRepository();
    final expenseRepo = ExpenseRepository();
    
    final upcomingPayments = await paymentRepo.getUpcomingPayments();
    final allExpenses = await expenseRepo.getAllExpenses();
    
    for (var payment in upcomingPayments) {
      await scheduleAutoPaymentReminder(payment);
    }
    
    for (var expense in allExpenses) {
      // Only for future expenses
      if (expense.expenseDate.isAfter(DateTime.now())) {
        await scheduleAutoExpenseReminder(expense);
      }
    }
  }

  static Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      AppConstants.paymentChannelId,
      AppConstants.paymentChannelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }
}