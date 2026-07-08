import 'package:flutter/material.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/custom_button.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/custom_text_field.dart';
import 'package:smart_expenses_plan/services/currency_service.dart';
import 'package:intl/intl.dart';

class CurrencyConverter extends StatefulWidget {
  const CurrencyConverter({super.key});

  @override
  State<CurrencyConverter> createState() => _CurrencyConverterState();
}

class _CurrencyConverterState extends State<CurrencyConverter> {
  final CurrencyService _currencyService = CurrencyService();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  
  Map<String, double> _rates = {};
  List<String> _currencies = [];
  String _fromCurrency = 'USD';
  String _toCurrency = 'TZS';
  
  String _lastUpdated = 'Loading...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates() async {
    setState(() {
      _isLoading = true;
    });

    final rates = await _currencyService.getRates();
    final lastUpdated = await _currencyService.getLastUpdated();
    
    setState(() {
      _rates = rates;
      _currencies = rates.keys.toList()..sort();
      
      // Ensure selected currencies exist in the list
      if (!_currencies.contains(_fromCurrency)) {
        _fromCurrency = _currencies.isNotEmpty ? _currencies.first : 'USD';
      }
      if (!_currencies.contains(_toCurrency)) {
        _toCurrency = _currencies.length > 1 ? _currencies[1] : (_currencies.isNotEmpty ? _currencies.first : 'TZS');
      }

      if (lastUpdated != null) {
        _lastUpdated = DateFormat('MMM d, y, h:mm a').format(lastUpdated);
      } else {
        _lastUpdated = 'Never';
      }
      _isLoading = false;
      
      // Recalculate if there's a value
      if (_fromController.text.isNotEmpty) {
        _convertFromToTo(_fromController.text);
      }
    });
  }

  double get _currentRate {
    if (_rates.isEmpty || !_rates.containsKey(_fromCurrency) || !_rates.containsKey(_toCurrency)) {
      return 1.0;
    }
    // All rates are relative to USD.
    // If USD to EUR is 0.9, and USD to TZS is 2500, then EUR to TZS is 2500 / 0.9
    final fromRate = _rates[_fromCurrency]!;
    final toRate = _rates[_toCurrency]!;
    return toRate / fromRate;
  }

  void _convertFromToTo(String value) {
    if (value.isEmpty) {
      _toController.text = '';
      return;
    }
    
    try {
      double fromValue = double.parse(value);
      double toValue = fromValue * _currentRate;
      _toController.text = toValue.toStringAsFixed(2);
    } catch (e) {
      // Invalid input
    }
  }

  void _convertToToFrom(String value) {
    if (value.isEmpty) {
      _fromController.text = '';
      return;
    }
    
    try {
      double toValue = double.parse(value);
      double fromValue = toValue / _currentRate;
      _fromController.text = fromValue.toStringAsFixed(2);
    } catch (e) {
      // Invalid input
    }
  }

  void _swapCurrencies() {
    setState(() {
      final tempCur = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = tempCur;
      
      final tempVal = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = tempVal;
      
      if (_fromController.text.isNotEmpty) {
        _convertFromToTo(_fromController.text);
      }
    });
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Container(
        color: isDark ? AppColors.darkBackground : Colors.white,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      color: isDark ? AppColors.darkBackground : Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Exchange Rate Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Exchange Rate',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '1 $_fromCurrency = ${_currentRate.toStringAsFixed(2)} $_toCurrency',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.update,
                        size: 14,
                        color: isDark ? AppColors.darkSubtext : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Last updated: $_lastUpdated',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkSubtext : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // From Input
          _buildCurrencyCard(
            title: 'From',
            selectedCurrency: _fromCurrency,
            controller: _fromController,
            onCurrencyChanged: (val) {
              if (val != null) {
                setState(() {
                  _fromCurrency = val;
                  _convertFromToTo(_fromController.text);
                });
              }
            },
            onValueChanged: _convertFromToTo,
            color: AppColors.primary,
          ),

          // Swap Button
          Center(
            child: IconButton(
              onPressed: _swapCurrencies,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.swap_vert,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
            ),
          ),

          // To Input
          _buildCurrencyCard(
            title: 'To',
            selectedCurrency: _toCurrency,
            controller: _toController,
            onCurrencyChanged: (val) {
              if (val != null) {
                setState(() {
                  _toCurrency = val;
                  _convertToToFrom(_toController.text);
                });
              }
            },
            onValueChanged: _convertToToFrom,
            color: AppColors.warning,
          ),

          const SizedBox(height: 24),

          // Update Rate Button
          CustomButton(
            text: 'Refresh Rates',
            onPressed: _loadRates,
            icon: Icons.refresh,
            isFullWidth: true,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCurrencyCard({
    required String title,
    required String selectedCurrency,
    required TextEditingController controller,
    required ValueChanged<String?> onCurrencyChanged,
    required ValueChanged<String> onValueChanged,
    required Color color,
  }) {
    return Card(
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
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.monetization_on,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: selectedCurrency,
                  items: _currencies
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ))
                      .toList(),
                  onChanged: onCurrencyChanged,
                  underline: const SizedBox(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Enter amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: onValueChanged,
            ),
          ],
        ),
      ),
    );
  }
}