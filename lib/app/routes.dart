import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_expenses_plan/presentation/screens/splash/splash_screen.dart';
import 'package:smart_expenses_plan/presentation/screens/auth/login_screen.dart';
import 'package:smart_expenses_plan/presentation/screens/auth/terms_screen.dart';
import 'package:smart_expenses_plan/presentation/screens/auth/initial_setup_screen.dart';
import 'package:smart_expenses_plan/presentation/screens/auth/pin_setup_screen.dart';
import 'package:smart_expenses_plan/presentation/screens/auth/pattern_setup_screen.dart';
import 'package:smart_expenses_plan/presentation/screens/home/home_screen.dart';
import 'package:smart_expenses_plan/presentation/screens/payment/add_payment_screen.dart';
import 'package:smart_expenses_plan/presentation/screens/payment/edit_payment_screen.dart';
import 'package:smart_expenses_plan/presentation/screens/payment/payment_detail_screen.dart';
import 'package:smart_expenses_plan/presentation/screens/payment/payment_list_screen.dart';
import 'package:smart_expenses_plan/presentation/screens/expense/add_expense_screen.dart';
import 'package:smart_expenses_plan/presentation/screens/expense/expense_detail_screen.dart';
import 'package:smart_expenses_plan/presentation/screens/expense/expense_list_screen.dart';
import 'package:smart_expenses_plan/presentation/screens/income/add_income_screen.dart';
import 'package:smart_expenses_plan/presentation/screens/income/income_detail_screen.dart';
import 'package:smart_expenses_plan/presentation/screens/income/income_list_screen.dart';
import 'package:smart_expenses_plan/presentation/screens/settings/settings_screen.dart';
import 'package:smart_expenses_plan/presentation/screens/backup/backup_setup_screen.dart';
import 'package:smart_expenses_plan/presentation/screens/backup/restore_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/terms',
      name: 'terms',
      builder: (context, state) => const TermsScreen(),
    ),
    GoRoute(
      path: '/initial-setup',
      name: 'initial-setup',
      builder: (context, state) => const InitialSetupScreen(),
    ),
    GoRoute(
      path: '/pin-setup',
      name: 'pin-setup',
      builder: (context, state) => const PinSetupScreen(),
    ),
    GoRoute(
      path: '/pattern-setup',
      name: 'pattern-setup',
      builder: (context, state) => const PatternSetupScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/add-payment',
      name: 'add-payment',
      builder: (context, state) => const AddPaymentScreen(),
    ),
    GoRoute(
      path: '/edit-payment/:id',
      name: 'edit-payment',
      builder: (context, state) => EditPaymentScreen(
        paymentId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/payment-detail/:id',
      name: 'payment-detail',
      builder: (context, state) => PaymentDetailScreen(
        paymentId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/payment-list',
      name: 'payment-list',
      builder: (context, state) => const PaymentListScreen(),
    ),
    GoRoute(
      path: '/add-expense',
      name: 'add-expense',
      builder: (context, state) => const AddExpenseScreen(),
    ),
    GoRoute(
      path: '/edit-expense/:id',
      name: 'edit-expense',
      builder: (context, state) => AddExpenseScreen(
        expenseId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/expense-detail/:id',
      name: 'expense-detail',
      builder: (context, state) => ExpenseDetailScreen(
        expenseId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/expense-list',
      name: 'expense-list',
      builder: (context, state) => const ExpenseListScreen(),
    ),
    GoRoute(
      path: '/income',
      name: 'income',
      builder: (context, state) => const IncomeListScreen(),
    ),
    GoRoute(
      path: '/add-income',
      name: 'add-income',
      builder: (context, state) => const AddIncomeScreen(),
    ),
    GoRoute(
      path: '/edit-income/:id',
      name: 'edit-income',
      builder: (context, state) => AddIncomeScreen(
        incomeId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/income-detail/:id',
      name: 'income-detail',
      builder: (context, state) => IncomeDetailScreen(
        incomeId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/backup-setup',
      name: 'backup-setup',
      builder: (context, state) => const BackupSetupScreen(),
    ),
    GoRoute(
      path: '/restore',
      name: 'restore',
      builder: (context, state) => const RestoreScreen(),
    ),
  ],
);