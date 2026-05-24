import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_expenses_plan/app/app.dart';
import 'package:smart_expenses_plan/core/themes/dark_theme.dart';
import 'package:smart_expenses_plan/core/themes/light_theme.dart';
import 'package:smart_expenses_plan/services/database_service.dart';
import 'package:smart_expenses_plan/services/theme_service.dart';
import 'package:smart_expenses_plan/services/payment_status_service.dart';
import 'package:smart_expenses_plan/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smart_expenses_plan/services/ad_service.dart';
import 'package:smart_expenses_plan/data/repositories/auth_repository.dart';
import 'package:smart_expenses_plan/data/repositories/expense_repository.dart';
import 'package:smart_expenses_plan/data/repositories/payment_repository.dart';
import 'package:smart_expenses_plan/data/repositories/income_repository.dart';
import 'package:smart_expenses_plan/data/repositories/budget_repository.dart';
import 'package:smart_expenses_plan/bloc/home/home_bloc.dart';
import 'package:smart_expenses_plan/bloc/expense/expense_bloc.dart';
import 'package:smart_expenses_plan/bloc/payment/payment_bloc.dart';
import 'package:smart_expenses_plan/bloc/budget/budget_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize localization, notifications and ads
  await EasyLocalization.ensureInitialized();
  
  try {
    await NotificationService.initialize();
  } catch (e) {
    print('Main: Failed to initialize notifications: $e');
  }
  
  try {
    await AdService.instance.initialize();
  } catch (e) {
    print('Main: Failed to initialize ads: $e');
  }

  // For hot reload optimization, only do minimal database init
  // Full initialization will happen in the app when needed
  try {
    // Just ensure database exists, don't do heavy operations
    await DatabaseService.instance.database;
    print('Main: Database ready');
  } catch (e) {
    print('Database init error (non-critical): $e');
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('sw')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider(create: (_) => AuthRepository()),
          RepositoryProvider(create: (_) => ExpenseRepository()),
          RepositoryProvider(create: (_) => PaymentRepository()),
          RepositoryProvider(create: (_) => IncomeRepository()),
          RepositoryProvider(create: (_) => BudgetRepository()),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => HomeBloc(
                paymentRepository: context.read<PaymentRepository>(),
                expenseRepository: context.read<ExpenseRepository>(),
                authRepository: context.read<AuthRepository>(),
                incomeRepository: context.read<IncomeRepository>(),
                budgetRepository: context.read<BudgetRepository>(),
              )..add(LoadHomeData()),
            ),
            BlocProvider(
              create: (context) => ExpenseBloc(
                expenseRepository: context.read<ExpenseRepository>(),
              )..add(LoadExpenses()),
            ),
            BlocProvider(
              create: (context) => PaymentBloc(
                paymentRepository: context.read<PaymentRepository>(),
              )..add(LoadPayments()),
            ),
            BlocProvider(
              create: (context) => BudgetBloc(
                budgetRepository: context.read<BudgetRepository>(),
              )..add(LoadBudgets()),
            ),
          ],
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeService()),
            ],
            child: const MyApp(),
          ),
        ),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DateTime? _pausedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedTime != null) {
        final timeInBackground = DateTime.now().difference(_pausedTime!);
        // Only show App Open ad if the app was in the background for more than 5 minutes (300 seconds)
        if (timeInBackground.inMinutes >= 5) {
          print('Main: App returned from background after ${timeInBackground.inMinutes}m, showing App Open ad');
          AdService.instance.showAppOpenAd();
        } else {
          print('Main: App returned from background after only ${timeInBackground.inSeconds}s, skipping App Open ad to protect UX (requires 10 minutes)');
        }
        _pausedTime = null; // Reset
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return MaterialApp.router(
      title: 'Smart Expenses Plan',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        EasyLocalization.of(context)!.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('sw')],
      locale: context.locale,
      theme: LightTheme.theme,
      darkTheme: DarkTheme.theme,
      themeMode: themeService.themeMode,
      routerConfig: AppRouter.router,
    );
  }
}