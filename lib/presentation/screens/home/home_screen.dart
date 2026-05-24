import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/presentation/screens/home/home_tab.dart';
import 'package:smart_expenses_plan/presentation/screens/home/calendar_tab.dart';
import 'package:smart_expenses_plan/presentation/screens/home/calculator_tab.dart';
import 'package:smart_expenses_plan/presentation/screens/home/comparison_tab.dart';
import 'package:smart_expenses_plan/presentation/screens/home/profile_tab.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/banner_ad_widget.dart';
import 'package:upgrader/upgrader.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:smart_expenses_plan/services/onboarding_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  bool _isOnline = true;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  
  final List<Widget> _tabs = [
    const HomeTab(),
    const CalendarTab(),
    const CalculatorTab(),
    const ComparisonTab(),
    const ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    
    _checkConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (mounted) {
        setState(() {
          _isOnline = result != ConnectivityResult.none;
        });
      }
    });
  }


  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _connectivitySubscription.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
      
    return ShowCaseWidget(
      blurValue: 1.5,
      autoPlay: false,
      onFinish: () async {
        await OnboardingService.markHomeTourCompleted();
      },
      builder: (context) => Builder(
        builder: (context) {
          // Trigger tour here using the builder context which has ShowCaseWidget as ancestor
          _checkTourStatus(context);
          
          return UpgradeAlert(
            upgrader: Upgrader(),
            child: Scaffold(
              body: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                      },
                      children: _tabs,
                    ),
                  ),
                  const BannerAdWidget(),
                ],
              ),
              floatingActionButton: _buildSpeedDial(isDark),
              floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
              bottomNavigationBar: _buildBottomBar(isDark),
            ),
          );
        }
      ),
    );
  }

  Future<void> _checkTourStatus(BuildContext context) async {
    final completed = await OnboardingService.isHomeTourCompleted();
    if (!completed && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShowCaseWidget.of(context).startShowCase([
          OnboardingService.incomeKey,
          OnboardingService.statsKey,
          OnboardingService.chartKey,
          OnboardingService.quickActionsKey,
          OnboardingService.fabKey,
        ]);
      });
    }
  }

  Widget _buildBottomBar(bool isDark) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: isDark ? const Color(0xFF1A1F2E) : Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: isDark ? Colors.grey[600] : Colors.grey[400],
      selectedFontSize: 11,
      unselectedFontSize: 11,
      elevation: 16,
      onTap: (index) {
        setState(() => _currentIndex = index);
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: 'Calendar'),
        BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Calculator'),
        BottomNavigationBarItem(icon: Icon(Icons.insights_rounded), label: 'Trending'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
      ],
    );
  }

  Widget _buildSpeedDial(bool isDark) {
    return Showcase(
      key: OnboardingService.fabKey,
      title: 'Quick Actions',
      description: 'Access all features here: Receipts, Budgets, Payments & Expenses.',
      showArrow: true,
      child: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        spacing: 12,
        mini: false,
        childPadding: const EdgeInsets.all(5),
        spaceBetweenChildren: 12,
        dialRoot: (context, open, toggleView) {
          return GestureDetector(
            onTap: toggleView,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                open ? Icons.close : Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          );
        },
        buttonSize: const Size(56, 56),
        childrenButtonSize: const Size(56, 56),
        visible: true,
        direction: SpeedDialDirection.up,
        curve: Curves.elasticOut,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        elevation: 8.0,
        shape: const CircleBorder(),
        children: [
          SpeedDialChild(
            child: const Icon(Icons.receipt_long_rounded),
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            label: 'Add Receipt',
            labelStyle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
            onTap: () => context.push('/add-receipt'),
          ),
          SpeedDialChild(
            child: const Icon(Icons.account_balance_wallet_rounded),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            label: 'Add Budget',
            labelStyle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
            onTap: () => context.push('/add-budget'),
          ),
          SpeedDialChild(
            child: const Icon(Icons.payment_rounded),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            label: 'Add Payment',
            labelStyle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
            onTap: () => context.push('/add-payment'),
          ),
          SpeedDialChild(
            child: const Icon(Icons.receipt_rounded),
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            label: 'Add Expense',
            labelStyle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
            onTap: () => context.push('/add-expense'),
          ),
        ],
      ),
    );
  }
}