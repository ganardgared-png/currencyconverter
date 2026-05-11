import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/data/models/payment_plan_model.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/empty_state.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_expenses_plan/bloc/home/home_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smart_expenses_plan/core/utils/currency_formatter.dart';
import 'package:smart_expenses_plan/services/payment_status_service.dart';
import 'package:smart_expenses_plan/bloc/payment/payment_bloc.dart';

class PaymentListScreen extends StatefulWidget {
  final String? filter;
  
  const PaymentListScreen({super.key, this.filter});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<PaymentBloc>().add(LoadPayments());
    _searchController.addListener(() {
      setState(() {}); // Refresh to apply search filter
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PaymentPlanModel> _getFilteredPayments(List<PaymentPlanModel> payments) {
    List<PaymentPlanModel> filtered;
    
    switch (widget.filter) {
      case 'upcoming':
        filtered = payments.where((p) => p.status == 'upcoming' && p.paymentDate.isAfter(DateTime.now())).toList();
        break;
      case 'paid':
        filtered = payments.where((p) => p.status == 'paid').toList();
        break;
      case 'missed':
        filtered = payments.where((p) => p.status == 'missed' || (p.status == 'upcoming' && p.paymentDate.isBefore(DateTime.now()))).toList();
        break;
      default:
        filtered = List.from(payments);
    }

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((payment) {
        return payment.payName.toLowerCase().contains(query) ||
               payment.billType.toLowerCase().contains(query) ||
               (payment.notes?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search payments...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : Colors.grey[100],
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<PaymentBloc, PaymentState>(
        builder: (context, state) {
          if (state is PaymentLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PaymentsLoaded) {
            final filteredPayments = _getFilteredPayments(state.payments);
            
            if (filteredPayments.isEmpty) {
              return EmptyState(
                icon: Icons.payment,
                message: 'No payments found',
              );
            }

            return Column(
              children: [
                // Summary Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: isDark ? AppColors.darkSurface : Colors.grey[100],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filteredPayments.length} payments',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                      Text(
                        'Total: ${CurrencyFormatter.format(filteredPayments.fold(0.0, (sum, p) => sum + p.amount))}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Payments List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredPayments.length,
                    itemBuilder: (context, index) {
                      final payment = filteredPayments[index];
                      return _buildPaymentCard(payment);
                    },
                  ),
                ),
              ],
            );
          } else if (state is PaymentError) {
            return Center(child: Text(state.message));
          }
          return const Center(child: Text('Loading payments...'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/add-payment');
          if (result == true && context.mounted) {
            context.read<PaymentBloc>().add(LoadPayments());
            context.read<HomeBloc>().add(RefreshHomeData());
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getTitle() {
    switch (widget.filter) {
      case 'upcoming':
        return 'Upcoming Payments';
      case 'paid':
        return 'Paid Payments';
      case 'missed':
        return 'Missed Payments';
      default:
        return 'All Payments';
    }
  }

  Widget _buildPaymentCard(PaymentPlanModel payment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverdue = payment.status != 'paid' && payment.paymentDate.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? AppColors.error.withOpacity(0.3)
              : Colors.transparent,
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
            color: _getStatusColor(payment.status).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getPaymentIcon(payment.billType),
            color: _getStatusColor(payment.status),
            size: 24,
          ),
        ),
        title: Text(
          payment.payName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${payment.currency == 'TZS' ? 'TZS' : '\$'} ${NumberFormat('#,###').format(payment.amount)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('dd MMM yyyy').format(payment.paymentDate),
              style: TextStyle(
                fontSize: 12,
                color: isOverdue
                    ? AppColors.error
                    : Colors.grey,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handlePaymentAction(payment, value),
          itemBuilder: (context) => _buildPopupMenuItems(payment),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(payment.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  payment.status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(payment.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.more_vert,
                  size: 16,
                  color: _getStatusColor(payment.status),
                ),
              ],
            ),
          ),
        ),
        onTap: () {
          context.push('/payment-detail/${payment.id}');
        },
      ),
    );
  }

  void _handlePaymentAction(PaymentPlanModel payment, String action) async {
    final paymentStatusService = PaymentStatusService();
    
    try {
      switch (action) {
        case 'mark_paid':
          await paymentStatusService.markPaymentAsPaid(payment.id!);
          _showSnackBar('Payment marked as paid');
          break;
        case 'mark_missed':
          await paymentStatusService.markPaymentAsMissed(payment.id!);
          _showSnackBar('Payment marked as missed');
          break;
        case 'reset_upcoming':
          await paymentStatusService.resetPaymentToUpcoming(payment.id!);
          _showSnackBar('Payment reset to upcoming');
          break;
        case 'edit':
          final result = await context.push('/edit-payment/${payment.id}');
          if (result == true && context.mounted) {
            context.read<PaymentBloc>().add(LoadPayments());
            context.read<HomeBloc>().add(RefreshHomeData());
          }
          return;
        case 'delete':
          await _showDeleteConfirmation(payment);
          return;
      }
      
      // Reload and refresh home
      if (mounted) {
        context.read<PaymentBloc>().add(LoadPayments());
        context.read<HomeBloc>().add(RefreshHomeData());
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    }
  }

  List<PopupMenuEntry<String>> _buildPopupMenuItems(PaymentPlanModel payment) {
    final items = <PopupMenuEntry<String>>[];
    
    // Mark as paid (only for upcoming or missed payments)
    if (payment.status != 'paid') {
      items.add(const PopupMenuItem<String>(
        value: 'mark_paid',
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Mark as Paid'),
          ],
        ),
      ));
    }
    
    // Mark as missed (only for upcoming payments)
    if (payment.status == 'upcoming') {
      items.add(const PopupMenuItem<String>(
        value: 'mark_missed',
        child: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text('Mark as Missed'),
          ],
        ),
      ));
    }
    
    // Reset to upcoming (only for missed payments)
    if (payment.status == 'missed') {
      items.add(const PopupMenuItem<String>(
        value: 'reset_upcoming',
        child: Row(
          children: [
            Icon(Icons.refresh, color: Colors.orange),
            SizedBox(width: 8),
            Text('Reset to Upcoming'),
          ],
        ),
      ));
    }
    
    // Edit option
    items.add(const PopupMenuItem<String>(
      value: 'edit',
      child: Row(
        children: [
          Icon(Icons.edit),
          SizedBox(width: 8),
          Text('Edit'),
        ],
      ),
    ));
    
    // Delete option
    items.add(const PopupMenuItem<String>(
      value: 'delete',
      child: Row(
        children: [
          Icon(Icons.delete, color: Colors.red),
          SizedBox(width: 8),
          Text('Delete'),
        ],
      ),
    ));
    
    return items;
  }

  Future<void> _showDeleteConfirmation(PaymentPlanModel payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: Text('Are you sure you want to delete "${payment.payName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      context.read<PaymentBloc>().add(DeletePayment(paymentId: payment.id!));
      context.read<HomeBloc>().add(RefreshHomeData());
      _showSnackBar('Payment deleted successfully');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.success;
      case 'upcoming':
        return AppColors.warning;
      default:
        return AppColors.error;
    }
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