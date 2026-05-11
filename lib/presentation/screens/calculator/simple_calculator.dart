import 'package:flutter/material.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:math_expressions/math_expressions.dart';

class SimpleCalculator extends StatefulWidget {
  const SimpleCalculator({super.key});

  @override
  State<SimpleCalculator> createState() => _SimpleCalculatorState();
}

class _SimpleCalculatorState extends State<SimpleCalculator> {
  String _expression = '';
  String _result = '0';
  bool _isNewCalculation = true;

  final List<String> _buttons = [
    'C', '⌫', '%', '÷',
    '7', '8', '9', '×',
    '4', '5', '6', '-',
    '1', '2', '3', '+',
    '0', '.', '=',
  ];

  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _expression = '';
        _result = '0';
        _isNewCalculation = true;
      } else if (value == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
        if (_expression.isEmpty) {
          _result = '0';
        }
      } else if (value == '=') {
        _calculateResult();
      } else if (value == '÷') {
        _expression += '/';
      } else if (value == '×') {
        _expression += '*';
      } else {
        if (_isNewCalculation && _isOperator(value)) {
          _expression = _result + value;
        } else {
          _expression += value;
        }
        _isNewCalculation = false;
      }
    });
  }

  bool _isOperator(String value) {
    return value == '+' || value == '-' || value == '×' || value == '÷' || value == '%';
  }

  void _calculateResult() {
    try {
      String expression = _expression.replaceAll('÷', '/').replaceAll('×', '*');
      
      // Handle percentage
      if (expression.contains('%')) {
        expression = expression.replaceAll('%', '/100');
      }
      
      Parser p = Parser();
      Expression exp = p.parse(expression);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);
      
      // Format result
      if (eval == eval.toInt()) {
        _result = eval.toInt().toString();
      } else {
        _result = eval.toStringAsFixed(2);
      }
      
      _isNewCalculation = true;
    } catch (e) {
      _result = 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.darkBackground : Colors.white,
      child: Column(
        children: [
          // Display
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.bottomRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _expression,
                  style: TextStyle(
                    fontSize: 24,
                    color: isDark ? AppColors.darkSubtext : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _result,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Buttons
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _buttons.length,
              itemBuilder: (context, index) {
                final button = _buttons[index];
                return _buildButton(button);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text) {
    bool isOperator = _isOperator(text) || text == '=' || text == 'C' || text == '⌫';
    bool isNumber = !isOperator && text != '.';
    
    Color backgroundColor;
    Color textColor;
    
    if (text == '=') {
      backgroundColor = AppColors.primary;
      textColor = Colors.white;
    } else if (text == 'C' || text == '⌫') {
      backgroundColor = AppColors.error.withOpacity(0.1);
      textColor = AppColors.error;
    } else if (isOperator) {
      backgroundColor = AppColors.warning.withOpacity(0.1);
      textColor = AppColors.warning;
    } else {
      backgroundColor = Colors.transparent;
      textColor = Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onButtonPressed(text),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: isNumber
                ? Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkSurface
                        : Colors.grey[300]!,
                  )
                : null,
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 24,
                fontWeight: text == '=' ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}