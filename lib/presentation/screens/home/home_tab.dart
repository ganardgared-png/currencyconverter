import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_expenses_plan/bloc/home/home_bloc.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/presentation/widgets/home/income_tray.dart';
import 'package:smart_expenses_plan/presentation/widgets/home/upcoming_tray.dart';
import 'package:smart_expenses_plan/presentation/widgets/home/paid_tray.dart';
import 'package:smart_expenses_plan/presentation/widgets/home/missed_tray.dart';
import 'package:smart_expenses_plan/presentation/widgets/home/budget_tray.dart';
import 'package:smart_expenses_plan/presentation/widgets/home/expense_chart.dart';
import 'package:smart_expenses_plan/presentation/widgets/home/quick_actions.dart';
import 'package:smart_expenses_plan/presentation/widgets/common/custom_app_bar.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
// Add these imports at the top
import 'package:smart_expenses_plan/presentation/widgets/home/income_tray.dart';
import 'package:smart_expenses_plan/presentation/widgets/home/upcoming_tray.dart';
import 'package:smart_expenses_plan/presentation/widgets/home/paid_tray.dart';
import 'package:smart_expenses_plan/presentation/widgets/home/missed_tray.dart';
import 'package:smart_expenses_plan/presentation/widgets/home/quick_actions.dart';
import 'package:smart_expenses_plan/bloc/budget/budget_bloc.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:smart_expenses_plan/services/onboarding_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: _isSearching 
            ? null 
            : 'Smart Expenses Plan',
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() => _isSearching = true);
                _animationController.forward();
              },
            ),
        ],
        bottom: _isSearching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search payments, expenses...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() => _isSearching = false);
                          _searchController.clear();
                          _animationController.reverse();
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : Colors.grey[100],
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: BlocListener<BudgetBloc, BudgetState>(
        listener: (context, state) {
          if (state is BudgetOperationSuccess) {
            context.read<HomeBloc>().add(RefreshHomeData());
          }
        },
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AnimationLimiter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 375),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(child: widget),
                  ),
                    children: [
                      // Income Tray
                      IncomeTray(showcaseKey: OnboardingService.incomeKey),
                      
                      const SizedBox(height: 20),
                      
                      // Stats Grid
                      Showcase(
                        key: OnboardingService.statsKey,
                        title: 'Financial Snapshots',
                        description: 'Monitor your upcoming, paid, and missed payments here.',
                        showArrow: true,
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          children: const [
                            UpcomingTray(),
                            PaidTray(),
                            MissedTray(),
                            BudgetTray(),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Expenses Chart
                      Showcase(
                        key: OnboardingService.chartKey,
                        title: 'Spending Trends',
                        description: 'Visualize your spending habits with this dynamic chart.',
                        showArrow: true,
                        child: const ExpenseChart(),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Quick Actions
                      Showcase(
                        key: OnboardingService.quickActionsKey,
                        title: 'Advanced Features',
                        description: 'Quickly access advanced features like Add Receipt, Budget, and more.',
                        showArrow: true,
                        child: const QuickActions(),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Recent Activity
                    _buildRecentActivity(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildRecentActivity() {
    // For now, don't show recent activity for new apps; avoid fake transactions.
    return const SizedBox.shrink();
  }
  
  Future<void> _refreshData() async {
    context.read<HomeBloc>().add(RefreshHomeData());
  }
}