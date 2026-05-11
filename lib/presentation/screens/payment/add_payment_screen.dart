import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/core/utils/fee_calculator.dart';
import 'package:smart_expenses_plan/services/ad_service.dart';
import 'package:smart_expenses_plan/services/fee_calculation_service.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/custom_button.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/custom_text_field.dart';
import 'package:intl/intl.dart';
import 'package:smart_expenses_plan/data/repositories/payment_repository.dart';
import 'package:smart_expenses_plan/data/models/payment_plan_model.dart';
import 'package:smart_expenses_plan/bloc/payment/payment_bloc.dart';
import 'package:smart_expenses_plan/bloc/home/home_bloc.dart';

class AddPaymentScreen extends StatefulWidget {
  const AddPaymentScreen({super.key});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _payNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _payerNameController = TextEditingController();
  final _payeeNameController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedCurrency = 'TZS';
  String _selectedBillType = 'Electricity';
  String _selectedReferenceType = 'Monthly';
  DateTime _selectedDate = DateTime.now();
  String _selectedPaymentMethod = 'Mobile';
  String? _selectedPayerService;
  String? _selectedPayeeService;
  double _calculatedFees = 0;
  double _totalAmount = 0;
  bool _reminderEnabled = true;
  bool _isLoading = false;
  
  final PaymentRepository _paymentRepository = PaymentRepository();
  
  final List<String> _billTypes = [
    'Electricity',
    'Water',
    'Internet',
    'TV Subscription',
    'Rent',
    'Loan',
    'Insurance',
    'School Fees',
    'Health Insurance',
    'Phone Bill',
    'Gas',
    'Custom',
  ];
  
  final List<String> _referenceTypes = [
    'Monthly',
    'Weekly',
    'Daily',
    'One Time',
    'Custom',
  ];
  
  final List<String> _paymentMethods = [
    'Mobile',
    'Bank',
    'Card',
    'Cash',
  ];
  
  final List<String> _mobileServices = [
    'M-Pesa',
    'Airtel Money',
    'Halopesa',
    'Mixx by Yas',
  ];
  
  final List<String> _banks = [
    'CRDB',
    'NMB',
    'Azania',
  ];
  
  @override
  void dispose() {
    _payNameController.dispose();
    _amountController.dispose();
    _payerNameController.dispose();
    _payeeNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  void _calculateFees() {
    if (_amountController.text.isEmpty) return;
    
    final normalizedAmount = _amountController.text.replaceAll(',', '');
    double amount = double.tryParse(normalizedAmount) ?? 0;
    
    if (_selectedPaymentMethod == 'Mobile' && 
        _selectedPayerService != null && 
        _selectedPayeeService != null) {
      
      _calculatedFees = FeeCalculationService.calculateMobileFee(
        amount,
        _selectedPayerService!,
        _selectedPayeeService!,
        'transfer', // or 'payment' based on context
      );
      
    } else if (_selectedPaymentMethod == 'Bank' && 
        _selectedPayerService != null && 
        _selectedPayeeService != null) {
      
      _calculatedFees = FeeCalculationService.calculateBankFee(
        amount,
        _selectedPayerService!,
        _selectedPayeeService!,
        'transfer',
      );
    }
    
    _totalAmount = amount + _calculatedFees;
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Payment Plan'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Pay Name
            CustomTextField(
              controller: _payNameController,
              label: 'Payment Name',
              hint: 'Enter payment name',
              prefixIcon: Icons.payment,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter payment name';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Amount and Currency
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: CustomTextField(
                    controller: _amountController,
                    label: 'Amount',
                    hint: 'Enter amount',
                    prefixIcon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    formatAsCurrency: true,
                    onChanged: (_) => _calculateFees(),
                    validator: (value) {
                      if (value == null || value.isEmpty || value.replaceAll(',', '').trim().isEmpty) {
                        return 'Please enter amount';
                      }
                      final normalized = value.replaceAll(',', '').trim();
                      if (double.tryParse(normalized) == null) {
                        return 'Please enter valid amount';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: ['TZS', 'USD'].map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCurrency = value!);
                      _calculateFees();
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Bill Type
            DropdownButtonFormField<String>(
              value: _selectedBillType,
              decoration: InputDecoration(
                labelText: 'Bill Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.category),
              ),
              items: _billTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                if (value == 'Custom') {
                  _showCustomInputDialog('Bill Type', (custom) {
                    setState(() => _selectedBillType = custom);
                  });
                } else {
                  setState(() => _selectedBillType = value!);
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Reference Type
            DropdownButtonFormField<String>(
              value: _selectedReferenceType,
              decoration: InputDecoration(
                labelText: 'Reference',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.repeat),
              ),
              items: _referenceTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                if (value == 'Custom') {
                  _showCustomInputDialog('Reference', (custom) {
                    setState(() => _selectedReferenceType = custom);
                  });
                } else {
                  setState(() => _selectedReferenceType = value!);
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Payment Date
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Payment Date',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMMM yyyy').format(_selectedDate),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Payer Name (Optional)
            CustomTextField(
              controller: _payerNameController,
              label: 'Payer Name (Optional)',
              hint: 'Enter payer name',
              prefixIcon: Icons.person_outline,
            ),
            
            const SizedBox(height: 16),
            
            // Payee Name (Optional)
            CustomTextField(
              controller: _payeeNameController,
              label: 'Payee Name (Optional)',
              hint: 'Enter payee name',
              prefixIcon: Icons.person_outline,
            ),
            
            const SizedBox(height: 16),
            
            // Payment Method
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              decoration: InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.payment),
              ),
              items: _paymentMethods.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(method),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                  _selectedPayerService = null;
                  _selectedPayeeService = null;
                });
                _calculateFees();
              },
            ),
            
            const SizedBox(height: 16),
            
            // Payer Service (if mobile or bank)
            if (_selectedPaymentMethod == 'Mobile' || _selectedPaymentMethod == 'Bank')
              DropdownButtonFormField<String>(
                value: _selectedPayerService,
                decoration: InputDecoration(
                  labelText: 'Payer ${_selectedPaymentMethod} Service',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(
                    _selectedPaymentMethod == 'Mobile' 
                        ? Icons.phone_android 
                        : Icons.account_balance,
                  ),
                ),
                items: (_selectedPaymentMethod == 'Mobile' ? _mobileServices : _banks).map((service) {
                  return DropdownMenuItem(
                    value: service,
                    child: Text(service),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedPayerService = value);
                  _calculateFees();
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select payer service';
                  }
                  return null;
                },
              ),
            
            const SizedBox(height: 16),
            
            // Payee Service (if mobile or bank)
            if (_selectedPaymentMethod == 'Mobile' || _selectedPaymentMethod == 'Bank')
              DropdownButtonFormField<String>(
                value: _selectedPayeeService,
                decoration: InputDecoration(
                  labelText: 'Payee ${_selectedPaymentMethod} Service',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(
                    _selectedPaymentMethod == 'Mobile' 
                        ? Icons.phone_android 
                        : Icons.account_balance,
                  ),
                ),
                items: (_selectedPaymentMethod == 'Mobile' ? _mobileServices : _banks).map((service) {
                  return DropdownMenuItem(
                    value: service,
                    child: Text(service),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedPayeeService = value);
                  _calculateFees();
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select payee service';
                  }
                  return null;
                },
              ),
            
            // Fees Display
            if (_calculatedFees > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transaction Fees:',
                          style: TextStyle(
                            color: isDark ? AppColors.darkSubtext : Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${_selectedCurrency == 'TZS' ? 'TZS' : '\$'} ${NumberFormat('#,###').format(_calculatedFees)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${_selectedCurrency == 'TZS' ? 'TZS' : '\$'} ${NumberFormat('#,###').format(_totalAmount)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Reminder Switch
            SwitchListTile(
              title: const Text('Enable Reminder'),
              subtitle: const Text('Get notified before payment date'),
              value: _reminderEnabled,
              activeColor: AppColors.primary,
              onChanged: (value) {
                setState(() => _reminderEnabled = value);
              },
            ),
            
            const SizedBox(height: 16),
            
            // Notes
            CustomTextField(
              controller: _notesController,
              label: 'Notes (Optional)',
              hint: 'Add additional information',
              prefixIcon: Icons.note,
              maxLines: 3,
            ),
            
            const SizedBox(height: 24),
            
            // Save Button
            CustomButton(
              text: 'Save Payment Plan',
              onPressed: _savePaymentPlan,
              isLoading: _isLoading,
              isFullWidth: true,
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  void _showCustomInputDialog(String title, Function(String) onSave) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Custom $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter custom $title',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onSave(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _savePaymentPlan() async {
    if (_formKey.currentState!.validate()) {
      if (_amountController.text.isEmpty || _amountController.text.replaceAll(',', '').trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter amount'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      
      setState(() => _isLoading = true);
      try {
        final paymentPlan = PaymentPlanModel(
          payName: _payNameController.text,
          amount: double.parse(_amountController.text.replaceAll(',', '')),
          currency: _selectedCurrency,
          billType: _selectedBillType,
          referenceType: _selectedReferenceType,
          paymentDate: _selectedDate,
          payerName: _payerNameController.text.isEmpty ? null : _payerNameController.text,
          payeeName: _payeeNameController.text.isEmpty ? null : _payeeNameController.text,
          paymentMethod: _selectedPaymentMethod,
          payerService: _selectedPayerService,
          payeeService: _selectedPayeeService,
          fees: _calculatedFees,
          totalAmount: _totalAmount,
          reminderEnabled: _reminderEnabled,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          status: 'upcoming',
        );

        context.read<PaymentBloc>().add(AddPayment(payment: paymentPlan));
        await AdService.instance.registerAddOperation();

        if (mounted) {
          context.read<HomeBloc>().add(RefreshHomeData());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment plan saved successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = 'Error saving payment plan';
          if (e is FormatException) {
            errorMessage = 'Please enter a valid numeric amount';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}