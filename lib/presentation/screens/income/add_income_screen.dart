import 'package:flutter/material.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/data/repositories/income_repository.dart';
import 'package:smart_expenses_plan/data/models/income_model.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/custom_button.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/custom_text_field.dart';
import 'package:smart_expenses_plan/services/ad_service.dart';
import 'package:smart_expenses_plan/bloc/home/home_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddIncomeScreen extends StatefulWidget {
  final String? incomeId;
  final IncomeModel? income;
  
  const AddIncomeScreen({super.key, this.incomeId, this.income});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sourceController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late IncomeRepository _incomeRepository;
  String _selectedCategory = 'Salary';
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  String _frequency = 'monthly';
  bool _isLoading = false;

  final List<String> _categories = [
    'Salary',
    'Business',
    'Freelance',
    'Investment',
    'Gift',
    'Other'
  ];

  final List<String> _frequencies = [
    'daily',
    'weekly',
    'monthly',
    'yearly'
  ];

  @override
  void initState() {
    super.initState();
    _incomeRepository = IncomeRepository();
    
    if (widget.income != null) {
      _sourceController.text = widget.income!.source;
      _amountController.text = widget.income!.amount.toString();
      _selectedCategory = widget.income!.category;
      _selectedDate = widget.income!.incomeDate;
      _isRecurring = widget.income!.recurring;
      _frequency = widget.income!.frequency ?? 'monthly';
      _notesController.text = widget.income!.notes ?? '';
    } else if (widget.incomeId != null) {
      _loadIncome();
    }
  }

  Future<void> _loadIncome() async {
    setState(() => _isLoading = true);
    try {
      final income = await _incomeRepository.getIncomeById(int.parse(widget.incomeId!));
      if (income != null) {
        setState(() {
          _sourceController.text = income.source;
          _amountController.text = income.amount.toString();
          _selectedCategory = income.category;
          _selectedDate = income.incomeDate;
          _isRecurring = income.recurring;
          _frequency = income.frequency ?? 'monthly';
          _notesController.text = income.notes ?? '';
        });
      }
    } catch (e) {
      print('AddIncomeScreen: Error loading income: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load income')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;

    if (_amountController.text.isEmpty || _amountController.text.replaceAll(',', '').trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final normalizedAmount = _amountController.text.replaceAll(',', '');
      final amount = double.parse(normalizedAmount);
      final income = IncomeModel(
        id: widget.incomeId != null ? int.parse(widget.incomeId!) : null,
        source: _selectedCategory == 'Other' ? _sourceController.text.trim() : _selectedCategory,
        amount: amount,
        category: _selectedCategory,
        incomeDate: _selectedDate,
        recurring: _isRecurring,
        frequency: _isRecurring ? _frequency : null,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (widget.income == null) {
        await _incomeRepository.insertIncome(income);
        await AdService.instance.registerAddOperation();
      } else {
        await _incomeRepository.updateIncome(income);
      }

      if (mounted) {
        context.read<HomeBloc>().add(RefreshHomeData());
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.income == null ? 'Income added successfully' : 'Income updated successfully'),
          ),
        );
      }
    } catch (e) {
      print('AddIncomeScreen: Error saving income: $e');
      if (mounted) {
        String errorMessage = 'Failed to save income';
        if (e is FormatException) {
          errorMessage = 'Please enter a valid numeric amount';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.incomeId == null ? 'Add Income' : 'Edit Income'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Income Source - Only show when "Other" category is selected
              if (_selectedCategory == 'Other') ...[
                TextFormField(
                  controller: _sourceController,
                  decoration: InputDecoration(
                    labelText: 'Income Source',
                    hintText: 'e.g., Salary, Business, Freelance',
                    prefixIcon: const Icon(Icons.business),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (_selectedCategory == 'Other' && (value == null || value.trim().isEmpty)) {
                      return 'Please enter income source';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Amount
              CustomTextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                formatAsCurrency: true,
                label: 'Amount',
                hint: '0.00',
                prefixIcon: Icons.attach_money,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final normalized = value.replaceAll(',', '');
                  final amount = double.tryParse(normalized);
                  if (amount == null || amount <= 0) {
                    return 'Please enter valid amount';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value!);
                },
              ),

              const SizedBox(height: 20),

              // Date
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Income Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: TextStyle(
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        color: isDark ? AppColors.darkSubtext : Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Recurring
              SwitchListTile(
                title: const Text('Recurring Income'),
                subtitle: const Text('This income repeats regularly'),
                value: _isRecurring,
                onChanged: (value) => setState(() => _isRecurring = value),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              if (_isRecurring) ...[
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _frequency,
                  decoration: InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _frequencies.map((freq) {
                    return DropdownMenuItem(
                      value: freq,
                      child: Text(freq[0].toUpperCase() + freq.substring(1)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _frequency = value!);
                  },
                ),
              ],

              const SizedBox(height: 20),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Additional notes about this income',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              CustomButton(
                text: widget.incomeId == null ? 'Add Income' : 'Update Income',
                onPressed: _saveIncome,
                isLoading: _isLoading,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}