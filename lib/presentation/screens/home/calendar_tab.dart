import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/data/repositories/payment_repository.dart';
import 'package:smart_expenses_plan/data/models/payment_plan_model.dart';
import 'package:intl/intl.dart';
import 'package:smart_expenses_plan/core/utils/date_formatter.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final PaymentRepository _paymentRepository;
  late TabController _tabController;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<PaymentPlanModel>> _events = {};
  List<PaymentPlanModel> _selectedEvents = [];
  List<PaymentPlanModel> _upcomingPayments = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _paymentRepository = PaymentRepository();
    _tabController = TabController(length: 2, vsync: this);
    _loadPayments();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPayments(); // Refresh data when app resumes
    }
  }

  Future<void> _loadPayments() async {
    if (!mounted) return;
    final payments = await _paymentRepository.getAllPayments();
    _processEvents(payments);
    _loadUpcomingPayments(payments);
  }

  void _loadUpcomingPayments(List<PaymentPlanModel> payments) {
    final now = DateTime.now();
    final upcoming = payments
        .where((p) => p.paymentDate.isAfter(now) && p.status != 'paid')
        .toList();
    upcoming.sort((a, b) => a.paymentDate.compareTo(b.paymentDate));
    
    setState(() {
      _upcomingPayments = upcoming;
    });
  }

  void _processEvents(List<PaymentPlanModel> payments) {
    final events = <DateTime, List<PaymentPlanModel>>{};
    
    for (var payment in payments) {
      final date = DateTime(
        payment.paymentDate.year,
        payment.paymentDate.month,
        payment.paymentDate.day,
      );
      
      if (events[date] == null) {
        events[date] = [];
      }
      events[date]!.add(payment);
    }
    
    setState(() {
      _events = events;
      // Set default to show upcoming reminders if no specific day is selected
      if (_selectedDay == null) {
        _selectedDay = DateTime.now();
      }
      _selectedEvents = events[_selectedDay ?? _focusedDay] ?? [];
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar & Reminders'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkSubtext : Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_today), text: 'Calendar'),
            Tab(icon: Icon(Icons.alarm), text: 'Upcoming'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarTab(isDark),
          _buildUpcomingTab(isDark),
        ],
      ),
    );
  }

  Widget _buildCalendarTab(bool isDark) {
    return Column(
      children: [
        // Calendar
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            eventLoader: (day) {
              return _events[day] ?? [];
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedEvents = _events[selectedDay] ?? [];
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              markerSize: 8,
              markersMaxCount: 3,
              weekendTextStyle: TextStyle(
                color: isDark ? Colors.grey : Colors.black,
              ),
              holidayTextStyle: TextStyle(
                color: isDark ? Colors.grey : Colors.black,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonDecoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              formatButtonTextStyle: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: isDark ? Colors.white : Colors.black,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Events List Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedDay == null
                    ? 'Today\'s Reminders'
                    : 'Reminders for ${DateFormat('dd MMM yyyy').format(_selectedDay!)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_selectedEvents.isNotEmpty)
                Text(
                  '${_selectedEvents.length} items',
                  style: TextStyle(
                    color: isDark ? AppColors.darkSubtext : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Events List
        Expanded(
          child: _selectedEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 60,
                        color: isDark ? AppColors.darkSubtext : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No reminders for this day',
                        style: TextStyle(
                          color: isDark ? AppColors.darkSubtext : Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _selectedEvents.length,
                  itemBuilder: (context, index) {
                    final payment = _selectedEvents[index];
                    return _buildReminderItem(payment);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUpcomingTab(bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.notifications_active),
              const SizedBox(width: 8),
              Text(
                'Upcoming Payments',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_upcomingPayments.isNotEmpty)
                Text(
                  '${_upcomingPayments.length} reminders',
                  style: TextStyle(
                    color: isDark ? AppColors.darkSubtext : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _upcomingPayments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 60,
                        color: AppColors.success.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No upcoming payments',
                        style: TextStyle(
                          color: isDark ? AppColors.darkSubtext : Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _upcomingPayments.length,
                  itemBuilder: (context, index) {
                    final payment = _upcomingPayments[index];
                    return _buildReminderItem(payment);
                  },
                ),
        ),
      ],
    );
  }

  @override

  Widget _buildReminderItem(PaymentPlanModel payment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isToday = DateFormatter.isToday(payment.paymentDate);
    final isTomorrow = DateFormatter.isTomorrow(payment.paymentDate);

    String statusText;
    Color statusColor;
    
    if (payment.status == 'paid') {
      statusText = 'Paid';
      statusColor = AppColors.success;
    } else if (payment.paymentDate.isBefore(DateTime.now())) {
      statusText = 'Overdue';
      statusColor = AppColors.error;
    } else {
      statusText = 'Upcoming';
      statusColor = AppColors.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getPaymentIcon(payment.billType),
            color: statusColor,
            size: 24,
          ),
        ),
        title: Text(
          payment.payName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${payment.currency == 'TZS' ? 'TZS' : '\$'} ${NumberFormat('#,###').format(payment.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isToday
                  ? 'Today'
                  : isTomorrow
                      ? 'Tomorrow'
                      : DateFormat('dd MMM yyyy').format(payment.paymentDate),
              style: TextStyle(
                fontSize: 12,
                color: isToday ? AppColors.primary : Colors.grey,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/payment-detail',
            arguments: payment.id,
          );
        },
      ),
    );
  }

  IconData _getPaymentIcon(String billType) {
    switch (billType.toLowerCase()) {
      case 'electricity':
        return Icons.bolt;
      case 'water':
        return Icons.water_drop;
      case 'internet':
        return Icons.wifi;
      case 'rent':
        return Icons.home;
      case 'loan':
        return Icons.attach_money;
      default:
        return Icons.payment;
    }
  }
}