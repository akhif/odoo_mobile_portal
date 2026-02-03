import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

class AppDateUtils {
  // Parse Odoo date string to DateTime
  static DateTime? parseOdooDate(dynamic value) {
    if (value == null || value == false) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Format DateTime to Odoo date string
  static String toOdooDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  // Format DateTime to Odoo datetime string
  static String toOdooDateTime(DateTime dateTime) {
    return DateFormat(AppConstants.dateTimeFormat).format(dateTime.toUtc());
  }

  // Format for display
  static String formatDisplayDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat(AppConstants.displayDateFormat).format(date);
  }

  static String formatDisplayDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat(AppConstants.displayDateTimeFormat).format(dateTime.toLocal());
  }

  // Format relative date (e.g., "2 days ago", "in 3 hours")
  static String formatRelativeDate(DateTime? date) {
    if (date == null) return '-';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inSeconds < 0) {
      // Future date
      final futureDiff = date.difference(now);
      if (futureDiff.inDays > 0) {
        return 'in ${futureDiff.inDays} ${futureDiff.inDays == 1 ? 'day' : 'days'}';
      } else if (futureDiff.inHours > 0) {
        return 'in ${futureDiff.inHours} ${futureDiff.inHours == 1 ? 'hour' : 'hours'}';
      } else {
        return 'in a few minutes';
      }
    } else {
      return 'Just now';
    }
  }

  // Get month name
  static String getMonthName(int month) {
    return DateFormat.MMMM().format(DateTime(2024, month));
  }

  // Get short month name
  static String getShortMonthName(int month) {
    return DateFormat.MMM().format(DateTime(2024, month));
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // Check if date is past
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  // Check if date is future
  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  // Get days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }

  // Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  // Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Get end of month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  // Calculate aging in days from today
  static int getAgingDays(DateTime? date) {
    if (date == null) return 0;
    final today = DateTime.now();
    return daysBetween(date, today);
  }

  // Get aging bucket
  static String getAgingBucket(int days) {
    if (days <= 30) return '0-30';
    if (days <= 60) return '31-60';
    if (days <= 90) return '61-90';
    return '90+';
  }
}
