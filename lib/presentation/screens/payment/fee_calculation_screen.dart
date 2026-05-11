import 'package:flutter/material.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/services/fee_calculation_service.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/custom_button.dart';
import 'package:intl/intl.dart';

class FeeCalculationScreen extends StatefulWidget {
  final double amount;
  final String paymentMethod;
  final String? payerService;
  final String? payeeService;
  
  const FeeCalculationScreen({
    super.key,
    required this.amount,
    required this.paymentMethod,
    this.payerService,
    this.payeeService,
  });

  @override
  State<FeeCalculationScreen> createState() => _FeeCalculationScreenState();
}

class _FeeCalculationScreenState extends State<FeeCalculationScreen> {
  double _fee = 0;
  double _total = 0;
  Map<String, dynamic>? _breakdown;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateFees();
  }

  void _calculateFees() {
    setState(() => _isLoading = true);

    try {
      if (widget.paymentMethod == 'Mobile' && 
          widget.payerService != null && 
          widget.payeeService != null) {
        
        _fee = FeeCalculationService.calculateMobileFee(
          widget.amount,
          widget.payerService!,
          widget.payeeService!,
          'transfer',
        );
        
      } else if (widget.paymentMethod == 'Bank' && 
          widget.payerService != null && 
          widget.payeeService != null) {
        
        _fee = FeeCalculationService.calculateBankFee(
          widget.amount,
          widget.payerService!,
          widget.payeeService!,
          'transfer',
        );
        
      } else if (widget.paymentMethod == 'Card') {
        _fee = widget.amount * 0.015; // 1.5% card fee
      }

      _total = widget.amount + _fee;
      
      _breakdown = {
        'amount': widget.amount,
        'fee': _fee,
        'total': _total,
        'feeType': _getFeeType(),
        'feePercentage': _fee > 0 ? (_fee / widget.amount * 100).toStringAsFixed(2) : '0',
      };

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getFeeType() {
    if (widget.paymentMethod == 'Cash') {
      return 'No fees for cash transactions';
    } else if (widget.paymentMethod == 'Mobile') {
      if (widget.payerService == widget.payeeService) {
        return 'Same network transfer fee';
      } else {
        return 'Cross network transfer fee';
      }
    } else if (widget.paymentMethod == 'Bank') {
      if (widget.payerService == widget.payeeService) {
        return 'Same bank transfer fee';
      } else {
        return 'Different bank transfer fee';
      }
    } else if (widget.paymentMethod == 'Card') {
      return 'Card processing fee (1.5%)';
    }
    return 'Transaction fee';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Calculation'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Amount Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Transaction Amount',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'TZS ${NumberFormat('#,###').format(widget.amount)}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Fee Breakdown Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Fee Type:',
                                style: TextStyle(fontSize: 16),
                              ),
                              Expanded(
                                child: Text(
                                  _breakdown!['feeType'],
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Fee Amount:',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                'TZS ${NumberFormat('#,###').format(_fee)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                          if (_breakdown!['feePercentage'] != '0') ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '(${_breakdown!['feePercentage']}% of amount)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkSubtext : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Amount:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'TZS ${NumberFormat('#,###').format(_total)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Payment Method Details
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
                            'Payment Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Method',
                            widget.paymentMethod,
                            Icons.payment,
                          ),
                          if (widget.payerService != null) ...[
                            const Divider(),
                            _buildDetailRow(
                              'From',
                              widget.payerService!,
                              Icons.account_balance,
                            ),
                          ],
                          if (widget.payeeService != null) ...[
                            const Divider(),
                            _buildDetailRow(
                              'To',
                              widget.payeeService!,
                              Icons.account_balance,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Cancel',
                          onPressed: () => Navigator.pop(context),
                          isOutlined: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Confirm',
                          onPressed: () {
                            Navigator.pop(context, {
                              'fee': _fee,
                              'total': _total,
                              'confirmed': true,
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(label),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}