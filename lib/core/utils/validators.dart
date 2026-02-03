class Validators {
  // URL Validation
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }

    // Try to parse the URL
    final uri = Uri.tryParse(value);
    if (uri == null) {
      return 'Invalid URL format';
    }

    // Check scheme
    if (!uri.hasScheme || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return 'URL must start with http:// or https://';
    }

    // Check host
    if (!uri.hasAuthority || uri.host.isEmpty) {
      return 'URL must have a valid host';
    }

    return null;
  }

  // Database Name Validation
  static String? validateDatabase(String? value) {
    if (value == null || value.isEmpty) {
      return 'Database name is required';
    }

    if (value.length < 2) {
      return 'Database name must be at least 2 characters';
    }

    // Check for valid characters
    final validPattern = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!validPattern.hasMatch(value)) {
      return 'Database name can only contain letters, numbers, underscores, and hyphens';
    }

    return null;
  }

  // Username Validation
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }

    if (value.length < 2) {
      return 'Username must be at least 2 characters';
    }

    return null;
  }

  // Password Validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 4) {
      return 'Password must be at least 4 characters';
    }

    return null;
  }

  // Email Validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailPattern.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Required Field
  static String? validateRequired(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  // Numeric Validation
  static String? validateNumeric(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }

    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }

    return null;
  }

  // Positive Number Validation
  static String? validatePositiveNumber(String? value, [String? fieldName]) {
    final numericError = validateNumeric(value, fieldName);
    if (numericError != null) return numericError;

    final number = double.parse(value!);
    if (number <= 0) {
      return 'Please enter a positive number';
    }

    return null;
  }

  // Date Validation
  static String? validateDate(DateTime? value, [String? fieldName]) {
    if (value == null) {
      return '${fieldName ?? 'Date'} is required';
    }
    return null;
  }

  // Date Range Validation
  static String? validateDateRange(DateTime? start, DateTime? end) {
    if (start == null) {
      return 'Start date is required';
    }
    if (end == null) {
      return 'End date is required';
    }
    if (end.isBefore(start)) {
      return 'End date must be after start date';
    }
    return null;
  }

  // Phone Number Validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final phonePattern = RegExp(r'^\+?[\d\s-]{8,}$');
    if (!phonePattern.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // GPS Accuracy Validation
  static bool isGpsAccuracyValid(double accuracy, {double maxAccuracy = 100.0}) {
    return accuracy <= maxAccuracy;
  }

  // Mock Location Check
  static bool isMockLocationValid(bool isMock) {
    return !isMock;
  }
}
