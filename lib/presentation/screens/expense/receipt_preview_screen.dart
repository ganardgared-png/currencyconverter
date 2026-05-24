import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/data/models/expense_model.dart';
import 'package:smart_expenses_plan/data/repositories/expense_repository.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/custom_button.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/custom_text_field.dart';
import 'package:smart_expenses_plan/services/receipt_service.dart';
import 'package:smart_expenses_plan/bloc/expense/expense_bloc.dart';
import 'package:smart_expenses_plan/bloc/home/home_bloc.dart';
import 'package:smart_expenses_plan/services/ad_service.dart';
import 'package:intl/intl.dart';

class ReceiptPreviewScreen extends StatefulWidget {
  final ReceiptData receiptData;

  const ReceiptPreviewScreen({super.key, required this.receiptData});

  @override
  State<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<ReceiptPreviewScreen> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late String _selectedType;
  late DateTime _selectedDate;
  bool _isLoading = false;

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
    _nameController = TextEditingController(text: widget.receiptData.merchantName ?? '');
    _amountController = TextEditingController(text: widget.receiptData.amount?.toString() ?? '');
    _notesController = TextEditingController(text: widget.receiptData.notes);
    _selectedType = widget.receiptData.category;
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveReceipt() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an amount')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final expense = ExpenseModel(
        name: _nameController.text.isEmpty ? 'Receipt Expense' : _nameController.text,
        amount: double.parse(_amountController.text.replaceAll(',', '')),
        type: _selectedType,
        expenseDate: _selectedDate,
        reminderEnabled: false,
        notes: _notesController.text,
      );

      context.read<ExpenseBloc>().add(AddExpense(expense: expense));
      
      if (mounted) {
        context.read<HomeBloc>().add(RefreshHomeData());
        await AdService.instance.registerAddOperation();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt saved successfully!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save receipt. Please check values.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Receipt Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'We extracted the following information. Please confirm or edit if necessary.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          CustomTextField(
            controller: _nameController,
            label: 'Merchant / Name',
            prefixIcon: Icons.store_rounded,
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _amountController,
            label: 'Amount',
            prefixIcon: Icons.attach_money_rounded,
            keyboardType: TextInputType.number,
            formatAsCurrency: true,
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.category_rounded),
            ),
            items: _expenseTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _selectedType = v!),
          ),
          const SizedBox(height: 16),
          
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.calendar_today_rounded),
              ),
              child: Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
            ),
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _notesController,
            label: 'Notes',
            prefixIcon: Icons.note_rounded,
            maxLines: 4,
          ),
          const SizedBox(height: 32),
          
          CustomButton(
            text: 'Confirm & Save',
            onPressed: _saveReceipt,
            isLoading: _isLoading,
            icon: Icons.check_circle_rounded,
          ),
        ],
      ),
    );
  }
}
