import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _homeTourKey = 'home_tour_completed';

  // Global keys for the tour
  static final GlobalKey incomeKey = GlobalKey();
  static final GlobalKey statsKey = GlobalKey();
  static final GlobalKey chartKey = GlobalKey();
  static final GlobalKey quickActionsKey = GlobalKey();
  static final GlobalKey fabKey = GlobalKey();

  static Future<bool> isHomeTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_homeTourKey) ?? false;
  }

  static Future<void> markHomeTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_homeTourKey, true);
  }
}
