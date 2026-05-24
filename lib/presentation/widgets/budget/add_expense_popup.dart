import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:smart_expenses_plan/core/utils/currency_formatter.dart';
import 'package:smart_expenses_plan/data/models/budget_model.dart';

class AddExpensePopup extends StatefulWidget {
  final double maxAmount;
  final BudgetExpenseModel? initialExpense;
  final Function(BudgetExpenseModel) onAdd;

  const AddExpensePopup({
    super.key, 
    required this.maxAmount, 
    this.initialExpense,
    required this.onAdd,
  });

  @override
  State<AddExpensePopup> createState() => _AddExpensePopupState();
}

class _AddExpensePopupState extends State<AddExpensePopup> {
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late String _selectedCategory;
  final List<String> _categories = [
    'Electricity', 'Phone bill', 'Water', 'Rent', 'Food', 'Transport', 
    'Internet', 'Health', 'Shopping', 'Entertainment', 'Savings', 'Debt', 'Others'
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialExpense != null 
          ? CurrencyFormatter.format(widget.initialExpense!.amount).replaceAll(RegExp(r'[^\d]'), '') 
          : '',
    );
    _noteController = TextEditingController(text: widget.initialExpense?.note ?? '');
    _selectedCategory = widget.initialExpense?.category ?? _categories.first;
    
    // Add amount limiting listener
    _amountController.addListener(_limitAmount);
  }

  void _limitAmount() {
    final text = _amountController.text;
    if (text.isEmpty) return;
    
    final currentAmount = CurrencyFormatter.parse(text);
    final allowedMax = widget.maxAmount + (widget.initialExpense?.amount ?? 0);
    
    if (currentAmount > allowedMax) {
      final formattedMax = CurrencyInputFormatter.formatInternal(allowedMax);
      _amountController.value = TextEditingValue(
        text: formattedMax,
        selection: TextSelection.collapsed(offset: formattedMax.length),
      );
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_limitAmount);
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Expense'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: 'Max: ${CurrencyFormatter.format(widget.maxAmount)}',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note (Optional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final amount = CurrencyFormatter.parse(_amountController.text);
            if (amount <= 0) return;
            if (amount > widget.maxAmount) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Insufficient budget amount!')),
              );
              return;
            }
            widget.onAdd(BudgetExpenseModel(
              category: _selectedCategory,
              amount: amount,
              note: _noteController.text.isEmpty ? null : _noteController.text,
            ));
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;

    double value = double.parse(newValue.text);
    String newText = formatInternal(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  static String formatInternal(double value) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(value);
  }
}
