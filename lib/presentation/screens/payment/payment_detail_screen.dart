import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/data/repositories/payment_repository.dart';
import 'package:smart_expenses_plan/data/models/payment_plan_model.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/custom_button.dart';
import 'package:intl/intl.dart';

class PaymentDetailScreen extends StatefulWidget {
  final String paymentId;
  
  const PaymentDetailScreen({super.key, required this.paymentId});

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  late PaymentRepository _paymentRepository;
  PaymentPlanModel? _payment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _paymentRepository = PaymentRepository();
    _loadPayment();
  }

  Future<void> _loadPayment() async {
    setState(() => _isLoading = true);
    try {
      final payment = await _paymentRepository.getPaymentById(int.parse(widget.paymentId));
      setState(() {
        _payment = payment;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editPayment,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: AppColors.error),
            onPressed: _deletePayment,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payment == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: isDark ? AppColors.darkSubtext : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Payment not found',
                        style: TextStyle(
                          color: isDark ? AppColors.darkSubtext : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Status Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: _getStatusGradient(_payment!.status),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Status',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _payment!.status.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _payment!.payName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _payment!.currency == 'TZS'
                                  ? 'TZS ${NumberFormat('#,###').format(_payment!.amount)}'
                                  : '\$${NumberFormat('#,###').format(_payment!.amount)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_payment!.fees > 0) ...[
                              const SizedBox(height: 8),
                              Text(
                                '+ Fees: ${_payment!.currency == 'TZS' ? 'TZS' : '\$'} ${NumberFormat('#,###').format(_payment!.fees)}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Total: ${_payment!.currency == 'TZS' ? 'TZS' : '\$'} ${NumberFormat('#,###').format(_payment!.totalAmount)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Details Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildDetailRow(
                                'Bill Type',
                                _payment!.billType,
                                Icons.category,
                              ),
                              const Divider(),
                              _buildDetailRow(
                                'Reference',
                                _payment!.referenceType,
                                Icons.repeat,
                              ),
                              const Divider(),
                              _buildDetailRow(
                                'Payment Date',
                                DateFormat('dd MMMM yyyy').format(_payment!.paymentDate),
                                Icons.calendar_today,
                              ),
                              const Divider(),
                              _buildDetailRow(
                                'Payment Method',
                                _payment!.paymentMethod,
                                Icons.payment,
                              ),
                              if (_payment!.payerService != null) ...[
                                const Divider(),
                                _buildDetailRow(
                                  'Payer Service',
                                  _payment!.payerService!,
                                  Icons.account_balance,
                                ),
                              ],
                              if (_payment!.payeeService != null) ...[
                                const Divider(),
                                _buildDetailRow(
                                  'Payee Service',
                                  _payment!.payeeService!,
                                  Icons.account_balance,
                                ),
                              ],
                              if (_payment!.payerName != null && _payment!.payerName!.isNotEmpty) ...[
                                const Divider(),
                                _buildDetailRow(
                                  'Payer Name',
                                  _payment!.payerName!,
                                  Icons.person,
                                ),
                              ],
                              if (_payment!.payeeName != null && _payment!.payeeName!.isNotEmpty) ...[
                                const Divider(),
                                _buildDetailRow(
                                  'Payee Name',
                                  _payment!.payeeName!,
                                  Icons.person_outline,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Additional Info Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Additional Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildDetailRow(
                                'Reminder',
                                _payment!.reminderEnabled ? 'Enabled' : 'Disabled',
                                Icons.notifications,
                                valueColor: _payment!.reminderEnabled
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                              const Divider(),
                              _buildDetailRow(
                                'Created',
                                DateFormat('dd MMM yyyy HH:mm').format(_payment!.createdAt),
                                Icons.access_time,
                              ),
                              if (_payment!.notes != null && _payment!.notes!.isNotEmpty) ...[
                                const Divider(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(Icons.note, size: 20, color: AppColors.primary),
                                        SizedBox(width: 8),
                                        Text(
                                          'Notes',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkSurface : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(_payment!.notes!),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      if (_payment!.status != 'paid')
                        CustomButton(
                          text: 'Mark as Paid',
                          onPressed: _markAsPaid,
                          icon: Icons.check_circle,
                          isFullWidth: true,
                        ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSubtext
                    : Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getStatusGradient(String status) {
    switch (status) {
      case 'paid':
        return const LinearGradient(
          colors: [AppColors.success, Color(0xFF00B894)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'upcoming':
        return const LinearGradient(
          colors: [AppColors.warning, Color(0xFFFDCB6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [AppColors.error, Color(0xFFFF7675)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  void _editPayment() {
    // Navigate to edit payment screen
    Navigator.pushNamed(
      context,
      '/add-payment',
      arguments: {'payment': _payment},
    );
  }

  void _deletePayment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text('Are you sure you want to delete this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _paymentRepository.deletePayment(_payment!.id!);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _markAsPaid() async {
    await _paymentRepository.markAsPaid(_payment!.id!);
    _loadPayment();
  }
}