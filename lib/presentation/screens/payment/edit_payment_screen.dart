import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/core/utils/fee_calculator.dart';
import 'package:smart_expenses_plan/services/fee_calculation_service.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/custom_button.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/custom_text_field.dart';
import 'package:intl/intl.dart';
import 'package:smart_expenses_plan/data/repositories/payment_repository.dart';
import 'package:smart_expenses_plan/data/models/payment_plan_model.dart';

class EditPaymentScreen extends StatefulWidget {
  final String paymentId;

  const EditPaymentScreen({super.key, required this.paymentId});

  @override
  State<EditPaymentScreen> createState() => _EditPaymentScreenState();
}

class _EditPaymentScreenState extends State<EditPaymentScreen> {
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
  bool _isLoading = true;
  bool _isSaving = false;
  
  final PaymentRepository _paymentRepository = PaymentRepository();
  PaymentPlanModel? _payment;
  
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
  void initState() {
    super.initState();
    _loadPayment();
  }
  
  @override
  void dispose() {
    _payNameController.dispose();
    _amountController.dispose();
    _payerNameController.dispose();
    _payeeNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadPayment() async {
    try {
      final payment = await _paymentRepository.getPaymentById(int.parse(widget.paymentId));
      if (payment != null) {
        setState(() {
          _payment = payment;
          _payNameController.text = payment.payName;
          _amountController.text = payment.amount.toString();
          _payerNameController.text = payment.payerName ?? '';
          _payeeNameController.text = payment.payeeName ?? '';
          _notesController.text = payment.notes ?? '';
          _selectedCurrency = payment.currency;
          _selectedBillType = payment.billType;
          _selectedReferenceType = payment.referenceType;
          _selectedDate = payment.paymentDate;
          _selectedPaymentMethod = payment.paymentMethod;
          _selectedPayerService = payment.payerService;
          _selectedPayeeService = payment.payeeService;
          _calculatedFees = payment.fees;
          _totalAmount = payment.totalAmount;
          _reminderEnabled = payment.reminderEnabled;
          _isLoading = false;
        });
        _calculateFees();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading payment: $e')),
      );
      Navigator.of(context).pop();
    }
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
        'transfer',
      );
    } else {
      _calculatedFees = 0;
    }
    
    _totalAmount = amount + _calculatedFees;
    setState(() {});
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final updatedPayment = _payment!.copyWith(
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
      );
      
      await _paymentRepository.updatePayment(updatedPayment);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment updated successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating payment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Payment'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Payment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => _savePayment(),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Name
              CustomTextField(
                controller: _payNameController,
                label: 'Payment Name',
                hint: 'Enter payment name',
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
                    child: CustomTextField(
                      controller: _amountController,
                      label: 'Amount',
                      hint: '0.00',
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _calculateFees(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter valid amount';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedCurrency,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: ['TZS', 'USD'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCurrency = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Bill Type and Reference Type
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bill Type',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedBillType,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: _billTypes.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedBillType = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reference Type',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedReferenceType,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: _referenceTypes.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedReferenceType = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Payment Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Date',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy').format(_selectedDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Payment Method
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Method',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedPaymentMethod,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: _paymentMethods.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                          _selectedPayerService = null;
                          _selectedPayeeService = null;
                          _calculateFees();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Mobile Services (if Mobile payment method selected)
              if (_selectedPaymentMethod == 'Mobile') ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'From Service',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedPayerService,
                              isExpanded: true,
                              underline: const SizedBox(),
                              hint: const Text('Select service'),
                              items: _mobileServices.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPayerService = value;
                                  _calculateFees();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'To Service',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedPayeeService,
                              isExpanded: true,
                              underline: const SizedBox(),
                              hint: const Text('Select service'),
                              items: _mobileServices.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPayeeService = value;
                                  _calculateFees();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              // Bank (if Bank payment method selected)
              if (_selectedPaymentMethod == 'Bank') ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bank',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedPayerService,
                        isExpanded: true,
                        underline: const SizedBox(),
                        hint: const Text('Select bank'),
                        items: _banks.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPayerService = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              // Payer and Payee Names
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _payerNameController,
                      label: 'Payer Name (Optional)',
                      hint: 'Enter payer name',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _payeeNameController,
                      label: 'Payee Name (Optional)',
                      hint: 'Enter payee name',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Notes
              CustomTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                hint: 'Enter any additional notes',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Reminder Toggle
              SwitchListTile(
                title: const Text('Enable Reminder'),
                value: _reminderEnabled,
                onChanged: (value) {
                  setState(() {
                    _reminderEnabled = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Fee Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount:'),
                        Text('${_selectedCurrency == 'TZS' ? 'TZS' : '\$'} ${NumberFormat('#,###.00').format(double.tryParse(_amountController.text) ?? 0)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Fees:'),
                        Text('${_selectedCurrency == 'TZS' ? 'TZS' : '\$'} ${NumberFormat('#,###.00').format(_calculatedFees)}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_selectedCurrency == 'TZS' ? 'TZS' : '\$'} ${NumberFormat('#,###.00').format(_totalAmount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Save Button
              CustomButton(
                text: 'Update Payment',
                onPressed: _isSaving ? null : () => _savePayment(),
                isLoading: _isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}