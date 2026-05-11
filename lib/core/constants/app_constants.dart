class AppConstants {
  static const String appName = 'Smart Expenses Plan';
  static const String appVersion = '1.0.0';
  
  // Database
  static const String databaseName = 'smart_expenses.db';
  static const int databaseVersion = 1;
  
  // Shared Preferences Keys
  static const String themeModeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String firstLaunchKey = 'first_launch';
  static const String termsAcceptedKey = 'terms_accepted';
  static const String userIdKey = 'user_id';
  static const String useBiometricsKey = 'use_biometrics';
  static const String hasPasswordKey = 'has_password';
  static const String adAddOperationCounterKey = 'ad_add_operation_counter';
  
  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  
  // Currency
  static const String defaultCurrency = 'TZS';
  static const List<String> currencies = ['TZS', 'USD'];
  
  // Income Types
  static const List<String> incomeTypes = ['Monthly', 'Weekly', 'Daily'];
  
  // Bill Types
  static const List<String> billTypes = [
    'Electricity',
    'Water',
    'Internet',
    'TV Subscription',
    'Rent',
    'Loan',
    'Insurance',
    'School Fees',
    'Health Insurance',
    'Phone Bill',
    'Gas',
    'Custom',
  ];
  
  // Payment Methods
  static const List<String> paymentMethods = [
    'Mobile',
    'Bank',
    'Card',
    'Cash',
  ];
  
  // Mobile Services
  static const List<String> mobileServices = [
    'M-Pesa',
    'Airtel Money',
    'Halopesa',
    'Mixx by Yas',
  ];
  
  // Banks
  static const List<String> banks = [
    'CRDB',
    'NMB',
    'Azania',
  ];
  
  // Expense Types
  static const List<String> expenseTypes = [
    'Loan',
    'Shopping',
    'Electrical',
    'Furniture',
    'Groceries',
    'Transport',
    'Entertainment',
    'Healthcare',
    'Education',
    'Other',
  ];
  
  // Backup Frequencies
  static const List<String> backupFrequencies = [
    'Never',
    'Daily',
    'Weekly',
    'Monthly',
  ];
  
  // Cloud Providers
  static const List<String> cloudProviders = [
    'Google Drive',
    'OneDrive',
    'Dropbox',
  ];
  
  // Notification Channels
  static const String paymentChannelId = 'payment_reminders';
  static const String paymentChannelName = 'Payment Reminders';
  static const String expenseChannelId = 'expense_reminders';
  static const String expenseChannelName = 'Expense Reminders';
  
  // API Endpoints (if needed)
  static const String baseUrl = 'https://api.smartexpenses.com';
  
  // Email
  static const String supportEmail = 'smartsexpensesganard@gmail.com';
  
  // Developer Info
  static const String developerName = 'Faustine';
  static const String managerName = 'Goodluck';
}