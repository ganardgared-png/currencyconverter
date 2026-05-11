import 'package:flutter/material.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/custom_button.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/custom_text_field.dart';

class CurrencyConverter extends StatefulWidget {
  const CurrencyConverter({super.key});

  @override
  State<CurrencyConverter> createState() => _CurrencyConverterState();
}

class _CurrencyConverterState extends State<CurrencyConverter> {
  final TextEditingController _tzsController = TextEditingController();
  final TextEditingController _usdController = TextEditingController();
  
  double _exchangeRate = 2500.0; // Example rate: 1 USD = 2500 TZS
  String _lastUpdated = 'Today, 10:30 AM';
  bool _isLoading = false;

  @override
  void dispose() {
    _tzsController.dispose();
    _usdController.dispose();
    super.dispose();
  }

  void _convertTZStoUSD(String value) {
    if (value.isEmpty) {
      _usdController.text = '';
      return;
    }
    
    try {
      double tzs = double.parse(value);
      double usd = tzs / _exchangeRate;
      _usdController.text = usd.toStringAsFixed(2);
    } catch (e) {
      // Invalid input
    }
  }

  void _convertUSDtoTZS(String value) {
    if (value.isEmpty) {
      _tzsController.text = '';
      return;
    }
    
    try {
      double usd = double.parse(value);
      double tzs = usd * _exchangeRate;
      _tzsController.text = tzs.toStringAsFixed(0);
    } catch (e) {
      // Invalid input
    }
  }

  void _swapCurrencies() {
    String tzs = _tzsController.text;
    String usd = _usdController.text;
    
    _tzsController.text = usd;
    _usdController.text = tzs;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                          '1 USD = ${_exchangeRate.toStringAsFixed(0)} TZS',
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

          // TZS Input
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
                          Icons.money,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Tanzanian Shilling',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'TZS',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tzsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter amount in TZS',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: _convertTZStoUSD,
                  ),
                ],
              ),
            ),
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

          // USD Input
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
                          Icons.attach_money,
                          color: AppColors.warning,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'US Dollar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'USD',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _usdController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter amount in USD',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: _convertUSDtoTZS,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Quick Conversion Examples
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
                    'Quick Examples',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickExample('100 USD', '250,000 TZS'),
                      _buildQuickExample('50 USD', '125,000 TZS'),
                      _buildQuickExample('20 USD', '50,000 TZS'),
                      _buildQuickExample('10 USD', '25,000 TZS'),
                      _buildQuickExample('5 USD', '12,500 TZS'),
                      _buildQuickExample('1 USD', '2,500 TZS'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Update Rate Button
          CustomButton(
            text: 'Update Exchange Rate',
            onPressed: _showUpdateRateDialog,
            icon: Icons.update,
            isFullWidth: true,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildQuickExample(String usd, String tzs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            usd,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.warning,
            ),
          ),
          Text(
            tzs,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkSubtext
                  : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateRateDialog() {
    final controller = TextEditingController(text: _exchangeRate.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Exchange Rate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('1 USD = ? TZS'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Exchange Rate',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _exchangeRate = double.parse(controller.text);
                _lastUpdated = 'Just now';
                
                // Recalculate if there are values
                if (_tzsController.text.isNotEmpty) {
                  _convertTZStoUSD(_tzsController.text);
                }
                if (_usdController.text.isNotEmpty) {
                  _convertUSDtoTZS(_usdController.text);
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}