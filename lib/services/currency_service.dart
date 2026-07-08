import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static const String _repoRawUrl = 'https://raw.githubusercontent.com/ganardgared-png/currencyconverter/main/rates.json';
  static const String _cacheKey = 'cached_currency_rates';
  static const String _lastUpdatedKey = 'currency_last_updated';

  /// Fetches exchange rates. Tries network first, then falls back to local cache.
  Future<Map<String, double>> getRates() async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      final response = await http.get(Uri.parse(_repoRawUrl));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, dynamic> rawRates = data['rates'];
        
        final Map<String, double> rates = rawRates.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );
        
        // Cache the successful response
        await prefs.setString(_cacheKey, json.encode(rates));
        await prefs.setInt(_lastUpdatedKey, DateTime.now().millisecondsSinceEpoch);
        
        return rates;
      }
    } catch (e) {
      // If network fails (e.g., offline), we silently fall through to cache
      print('Failed to fetch rates from network: $e');
    }

    // Fallback to cache if offline or error
    final cachedData = prefs.getString(_cacheKey);
    if (cachedData != null) {
      final Map<String, dynamic> decoded = json.decode(cachedData);
      return decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
    }

    // Default fallback if no cache and no network
    return {'USD': 1.0, 'TZS': 2500.0};
  }

  /// Gets the last time the rates were successfully fetched from the network.
  Future<DateTime?> getLastUpdated() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastUpdatedKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }
}
