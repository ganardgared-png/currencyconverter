import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_expenses_plan/core/constants/colors.dart';
import 'package:smart_expenses_plan/presentation/screens/home/home_tab.dart';
import 'package:smart_expenses_plan/presentation/screens/home/calendar_tab.dart';
import 'package:smart_expenses_plan/presentation/screens/home/calculator_tab.dart';
import 'package:smart_expenses_plan/presentation/screens/home/comparison_tab.dart';
import 'package:smart_expenses_plan/presentation/screens/home/profile_tab.dart';
import 'package:smart_expenses_plan/presentation/widgets/home/draggable_floating_action_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  late Offset _fabPosition;
  
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
    _fabPosition = const Offset(0, 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            children: _tabs,
          ),
          Positioned(
            right: _fabPosition.dx,
            bottom: _fabPosition.dy,
            child: DraggableFloatingActionButton(
              onPressed: _showAddOptions,
              onPositionChanged: (offset) {
                setState(() {
                  _fabPosition = offset;
                });
              },
            ),
          ),
        ],
      ),
      floatingActionButton: null,
      bottomNavigationBar: BottomAppBar(
        color: isDark ? AppColors.darkSurface : Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(1, Icons.calendar_today_outlined, Icons.calendar_today, 'Calendar'),
              _buildNavItem(2, Icons.calculate_outlined, Icons.calculate, 'Calc'),
              _buildNavItem(3, Icons.compare_arrows_outlined, Icons.compare_arrows, 'Compare'),
              _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavItem(int index, IconData outlinedIcon, IconData filledIcon, String label) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlinedIcon,
              color: isSelected 
                ? AppColors.primary 
                : (isDark ? AppColors.darkSubtext : Colors.grey),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected 
                  ? AppColors.primary 
                  : (isDark ? AppColors.darkSubtext : Colors.grey),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.payment, color: AppColors.primary),
              ),
              title: const Text(
                'Add Payment Plan',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('Schedule a new payment'),
              onTap: () {
                Navigator.pop(context);
                if (mounted) {
                  context.push('/add-payment');
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt, color: AppColors.accent),
              ),
              title: const Text(
                'Add Expense',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('Record a new expense'),
              onTap: () {
                Navigator.pop(context);
                if (mounted) {
                  context.push('/add-expense');
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}