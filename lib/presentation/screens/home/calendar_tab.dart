import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/data/repositories/payment_repository.dart';
import 'package:smart_expenses_plan/data/models/payment_plan_model.dart';
import 'package:intl/intl.dart';
import 'package:smart_expenses_plan/core/utils/currency_formatter.dart';
import 'package:smart_expenses_plan/core/utils/date_formatter.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> with WidgetsBindingObserver {
  late final PaymentRepository _paymentRepository;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<PaymentPlanModel>> _events = {};
  List<PaymentPlanModel> _selectedEvents = [];
  List<PaymentPlanModel> _upcomingPayments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _paymentRepository = PaymentRepository();
    _loadPayments();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPayments();
    }
  }

  Future<void> _loadPayments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final payments = await _paymentRepository.getAllPayments();
      _processEvents(payments);
      _loadUpcomingPayments(payments);
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadUpcomingPayments(List<PaymentPlanModel> payments) {
    final now = DateTime.now();
    final upcoming = payments
        .where((p) => p.paymentDate.isAfter(now) && p.status != 'paid')
        .toList();
    upcoming.sort((a, b) => a.paymentDate.compareTo(b.paymentDate));
    setState(() => _upcomingPayments = upcoming);
  }

  void _processEvents(List<PaymentPlanModel> payments) {
    final events = <DateTime, List<PaymentPlanModel>>{};
    for (var payment in payments) {
      final date = DateTime(payment.paymentDate.year, payment.paymentDate.month, payment.paymentDate.day);
      if (events[date] == null) events[date] = [];
      events[date]!.add(payment);
    }
    setState(() {
      _events = events;
      if (_selectedDay != null) {
        _selectedEvents = events[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)] ?? [];
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildCalendar(isDark),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDay != null ? 'Daily Reminders' : 'Upcoming Payments',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_selectedDay != null)
                    TextButton(
                      onPressed: () => setState(() => _selectedDay = null),
                      child: const Text('Show All Upcoming'),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final items = _selectedDay != null ? _selectedEvents : _upcomingPayments;
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: _buildEmptyState(isDark),
                    );
                  }
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 20.0,
                      child: FadeInAnimation(
                        child: _buildReminderCard(items[index], isDark),
                      ),
                    ),
                  );
                },
                childCount: (_selectedDay != null ? _selectedEvents : _upcomingPayments).length.clamp(1, 999),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildCalendar(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: (day) => _events[DateTime(day.year, day.month, day.day)] ?? [],
        onFormatChanged: (format) => setState(() => _calendarFormat = format),
        onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
            _selectedEvents = _events[DateTime(selectedDay.year, selectedDay.month, selectedDay.day)] ?? [];
          });
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), shape: BoxShape.circle),
          todayTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          selectedDecoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
          markerDecoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
          markerSize: 6,
          outsideDaysVisible: false,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonDecoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          formatButtonTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildReminderCard(PaymentPlanModel payment, bool isDark) {
    final statusColor = payment.status == 'paid' ? AppColors.success : (payment.paymentDate.isBefore(DateTime.now()) ? AppColors.error : AppColors.warning);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(_getPaymentIcon(payment.billType), color: statusColor),
        ),
        title: Text(payment.payName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${CurrencyFormatter.format(payment.amount).split('.')[0]} • ${DateFormat('dd MMM').format(payment.paymentDate)}',
          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkSubtext : Colors.grey[600]),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Text(
            payment.status.toUpperCase(),
            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        onTap: () => Navigator.pushNamed(context, '/payment-detail', arguments: payment.id),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.event_available_rounded, size: 64, color: isDark ? Colors.white10 : Colors.grey[200]),
          const SizedBox(height: 16),
          Text('No payments found', style: TextStyle(color: isDark ? AppColors.darkSubtext : Colors.grey)),
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String billType) {
    switch (billType.toLowerCase()) {
      case 'electricity': return Icons.bolt;
      case 'water': return Icons.water_drop;
      case 'internet': return Icons.wifi;
      case 'rent': return Icons.home;
      case 'loan': return Icons.account_balance;
      default: return Icons.payment;
    }
  }
}