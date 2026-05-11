import 'package:flutter/material.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/core/constants/app_constants.dart';
import 'package:smart_expenses_plan/services/fee_calculation_service.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/custom_button.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/custom_text_field.dart';
import 'package:intl/intl.dart';

class CostBreakdown extends StatefulWidget {
  const CostBreakdown({super.key});

  @override
  State<CostBreakdown> createState() => _CostBreakdownState();
}

class _CostBreakdownState extends State<CostBreakdown> {
  final TextEditingController _amountController = TextEditingController();
  
  String _transactionType = 'transfer';
  String? _fromType;
  String? _fromService;
  String? _toType;
  String? _toService;
  
  double _fee = 0;
  double _total = 0;
  bool _showResult = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _calculateFee() {
    if (_amountController.text.isEmpty) return;
    
    double amount = double.tryParse(_amountController.text) ?? 0;
    
    if (_fromType == 'Mobile' && _toType == 'Mobile' && 
        _fromService != null && _toService != null) {
      
      _fee = FeeCalculationService.calculateMobileFee(
        amount,
        _fromService!,
        _toService!,
        _transactionType,
      );
      
    } else if (_fromType == 'Bank' && _toType == 'Bank' && 
        _fromService != null && _toService != null) {
      
      _fee = FeeCalculationService.calculateBankFee(
        amount,
        _fromService!,
        _toService!,
        _transactionType,
      );
      
    } else if (_fromType == 'Mobile' && _toType == 'Bank' && _fromService != null) {
      // Mobile to Bank transfer
      _fee = FeeCalculationService.calculateMobileFee(
        amount,
        _fromService!,
        'Bank',
        _transactionType,
      );
      
    } else if (_fromType == 'Bank' && _toType == 'Mobile' && _toService != null) {
      // Bank to Mobile transfer
      _fee = FeeCalculationService.calculateBankFee(
        amount,
        _fromService ?? 'CRDB',
        _toService!,
        _transactionType,
      );
    }
    
    _total = amount + _fee;
    setState(() {
      _showResult = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.darkBackground : Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Transaction Type
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
                    'Transaction Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeChip('Transfer', 'transfer'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTypeChip('Payment', 'payment'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Amount Input
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
                    'Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _amountController,
                    hint: 'Enter amount',
                    prefixIcon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      setState(() => _showResult = false);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // From Section
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.output,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'From',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // From Type
                  Row(
                    children: [
                      Expanded(
                        child: _buildServiceTypeChip('Mobile', 'from'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildServiceTypeChip('Bank', 'from'),
                      ),
                    ],
                  ),
                  
                  if (_fromType != null) ...[
                    const SizedBox(height: 12),
                    // From Service
                    DropdownButtonFormField<String>(
                      value: _fromService,
                      decoration: InputDecoration(
                        labelText: 'Select Service',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _getServices(_fromType!).map((service) {
                        return DropdownMenuItem(
                          value: service,
                          child: Text(service),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _fromService = value;
                          _showResult = false;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // To Section
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.input,
                          color: AppColors.warning,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'To',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // To Type
                  Row(
                    children: [
                      Expanded(
                        child: _buildServiceTypeChip('Mobile', 'to'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildServiceTypeChip('Bank', 'to'),
                      ),
                    ],
                  ),
                  
                  if (_toType != null) ...[
                    const SizedBox(height: 12),
                    // To Service
                    DropdownButtonFormField<String>(
                      value: _toService,
                      decoration: InputDecoration(
                        labelText: 'Select Service',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _getServices(_toType!).map((service) {
                        return DropdownMenuItem(
                          value: service,
                          child: Text(service),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _toService = value;
                          _showResult = false;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Calculate Button
          CustomButton(
            text: 'Calculate Fees',
            onPressed: _calculateFee,
            icon: Icons.calculate,
            isFullWidth: true,
          ),

          const SizedBox(height: 24),

          // Result
          if (_showResult)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Total Cost Breakdown',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildResultRow(
                      'Principal Amount',
                      'TZS ${NumberFormat('#,###').format(double.parse(_amountController.text))}',
                    ),
                    const Divider(color: Colors.white30),
                    _buildResultRow(
                      'Transaction Fee',
                      'TZS ${NumberFormat('#,###').format(_fee)}',
                    ),
                    const Divider(color: Colors.white30),
                    _buildResultRow(
                      'Total Amount',
                      'TZS ${NumberFormat('#,###').format(_total)}',
                      isTotal: true,
                    ),
                    if (_fee > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Fee Percentage: ${(_fee / double.parse(_amountController.text) * 100).toStringAsFixed(2)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, String value) {
    final isSelected = _transactionType == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _transactionType = value;
          _showResult = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkText
                      : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTypeChip(String label, String target) {
    final isSelected = target == 'from'
        ? _fromType == label
        : _toType == label;
    
    return InkWell(
      onTap: () {
        setState(() {
          if (target == 'from') {
            _fromType = label;
            _fromService = null;
          } else {
            _toType = label;
            _toService = null;
          }
          _showResult = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkText
                      : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  List<String> _getServices(String type) {
    if (type == 'Mobile') {
      return AppConstants.mobileServices;
    } else {
      return AppConstants.banks;
    }
  }

  Widget _buildResultRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}