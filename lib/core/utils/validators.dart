class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    
    return null;
  }
  
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }
  
  static String? validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN is required';
    }
    
    if (value.length != 4) {
      return 'PIN must be 4 digits';
    }
    
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'PIN must contain only numbers';
    }
    
    return null;
  }
  
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    
    // Remove commas to handle formatted currency input
    final cleanValue = value.replaceAll(',', '');
    final amount = double.tryParse(cleanValue);
    if (amount == null) {
      return 'Please enter a valid number';
    }
    
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    
    return null;
  }
  
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    return null;
  }
  
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    final phoneRegex = RegExp(r'^[0-9]{9,12}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }
  
  static String? validateRequired(String? value, {String field = 'Field'}) {
    if (value == null || value.isEmpty) {
      return '$field is required';
    }
    
    return null;
  }
  
  static String? validateNumber(String? value, {double min = 0, double? max}) {
    if (value == null || value.isEmpty) {
      return 'Number is required';
    }
    
    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    
    if (number < min) {
      return 'Number must be at least $min';
    }
    
    if (max != null && number > max) {
      return 'Number must be at most $max';
    }
    
    return null;
  }
  
  static String? validateDate(DateTime? date) {
    if (date == null) {
      return 'Date is required';
    }
    
    return null;
  }
  
  static String? validateFutureDate(DateTime? date) {
    if (date == null) {
      return 'Date is required';
    }
    
    if (date.isBefore(DateTime.now())) {
      return 'Date must be in the future';
    }
    
    return null;
  }
  
  static String? validatePastDate(DateTime? date) {
    if (date == null) {
      return 'Date is required';
    }
    
    if (date.isAfter(DateTime.now())) {
      return 'Date must be in the past';
    }
    
    return null;
  }
  
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }
    
    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    );
    
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }
  
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  static String? validateConfirmPin(String? value, String pin) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your PIN';
    }
    
    if (value != pin) {
      return 'PINs do not match';
    }
    
    return null;
  }
  
  static String? validatePattern(List<int>? pattern) {
    if (pattern == null || pattern.isEmpty) {
      return 'Pattern is required';
    }
    
    if (pattern.length < 3) {
      return 'Pattern must connect at least 3 dots';
    }
    
    return null;
  }
  
  static String? validateConfirmPattern(List<int>? pattern, List<int> originalPattern) {
    if (pattern == null || pattern.isEmpty) {
      return 'Please confirm your pattern';
    }
    
    if (pattern.length != originalPattern.length) {
      return 'Patterns do not match';
    }
    
    for (int i = 0; i < pattern.length; i++) {
      if (pattern[i] != originalPattern[i]) {
        return 'Patterns do not match';
      }
    }
    
    return null;
  }
}