import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/data/repositories/expense_repository.dart';
import 'package:smart_expenses_plan/data/models/expense_model.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/custom_button.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/custom_text_field.dart';
import 'package:smart_expenses_plan/services/ad_service.dart';
import 'package:smart_expenses_plan/core/utils/validators.dart';
import 'package:intl/intl.dart';
import 'package:smart_expenses_plan/bloc/expense/expense_bloc.dart';
import 'package:smart_expenses_plan/bloc/home/home_bloc.dart';

class AddExpenseScreen extends StatefulWidget {
  final String? expenseId;
  
  const AddExpenseScreen({super.key, this.expenseId});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedType = 'Shopping';
  DateTime _selectedDate = DateTime.now();
  bool _reminderEnabled = true;
  bool _isLoading = false;
  ExpenseModel? _expense;
  
  final List<String> _expenseTypes = [
    'Loan',
    'Shopping',
    'Food',
    'Electrical',
    'Furniture',
    'Groceries',
    'Transport',
    'Entertainment',
    'Healthcare',
    'Education',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.expenseId != null) {
      _loadExpense();
    }
  }
  
  Future<void> _loadExpense() async {
    setState(() => _isLoading = true);
    try {
      final repository = ExpenseRepository();
      final expense = await repository.getExpenseById(int.parse(widget.expenseId!));
      if (expense != null) {
        _nameController.text = expense.name;
        _amountController.text = expense.amount.toString();
        _selectedType = expense.type;
        _selectedDate = expense.expenseDate;
        _reminderEnabled = expense.reminderEnabled;
        _notesController.text = expense.notes ?? '';
        _expense = expense;
      }
    } catch (e) {
      _showErrorMessage('Failed to load expense');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_expense == null ? 'Add Expense' : 'Edit Expense'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            CustomTextField(
              controller: _nameController,
              label: 'Expense Name',
              hint: 'Enter expense name',
              prefixIcon: Icons.receipt,
              validator: Validators.validateName,
            ),
            
            const SizedBox(height: 16),
            
            // Amount
            CustomTextField(
              controller: _amountController,
              label: 'Amount',
              hint: 'Enter amount',
              prefixIcon: Icons.attach_money,
              keyboardType: TextInputType.number,
              formatAsCurrency: true,
              validator: Validators.validateAmount,
            ),
            
            const SizedBox(height: 16),
            
            // Type
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Expense Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.category),
              ),
              items: _expenseTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                if (value == 'Other') {
                  _showCustomInputDialog('Expense Type', (custom) {
                    setState(() => _selectedType = custom);
                  });
                } else {
                  setState(() => _selectedType = value!);
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Expense Date
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Expense Date',
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
            
            // Reminder Switch
            SwitchListTile(
              title: const Text('Enable Reminder'),
              subtitle: const Text('Get notified about this expense'),
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
              text: _expense == null ? 'Save Expense' : 'Update Expense',
              onPressed: _saveExpense,
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

  void _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      if (_amountController.text.isEmpty || _amountController.text.replaceAll(',', '').trim().isEmpty) {
        _showErrorMessage('Please enter amount');
        return;
      }
      setState(() => _isLoading = true);

      try {
        final expense = ExpenseModel(
          id: _expense?.id,
          name: _nameController.text,
          amount: double.parse(_amountController.text.replaceAll(',', '')),
          type: _selectedType,
          expenseDate: _selectedDate,
          reminderEnabled: _reminderEnabled,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );

        final repository = ExpenseRepository();
        
        if (_expense == null) {
          context.read<ExpenseBloc>().add(AddExpense(expense: expense));
          await AdService.instance.registerAddOperation();
        } else {
          context.read<ExpenseBloc>().add(UpdateExpense(expense: expense));
        }

        // Refresh home data
        if (mounted) {
          context.read<HomeBloc>().add(RefreshHomeData());
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        String errorMessage = 'Failed to save expense';
        if (e is FormatException || e is TypeError) {
          errorMessage = 'Please enter a valid numeric amount';
        }
        _showErrorMessage(errorMessage);
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}