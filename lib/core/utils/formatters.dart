// lib/core/utils/formatters.dart
import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 0,
  );

  static final _numberFormat = NumberFormat.decimalPattern('tr_TR');

  static final _percentFormat = NumberFormat.percentPattern('tr_TR');

  static final _dateFormat = DateFormat('dd MMMM yyyy', 'tr_TR');

  static final _timeFormat = DateFormat('HH:mm', 'tr_TR');

  static final _dateTimeFormat = DateFormat('dd MMM yyyy HH:mm', 'tr_TR');

  static String currency(double amount) {
    return _currencyFormat.format(amount);
  }

  static String number(double number) {
    return _numberFormat.format(number);
  }

  static String percent(double percent) {
    return _percentFormat.format(percent / 100);
  }

  static String date(DateTime date) {
    return _dateFormat.format(date);
  }

  static String time(DateTime time) {
    return _timeFormat.format(time);
  }

  static String dateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${difference.inDays ~/ 365}y önce';
    } else if (difference.inDays > 30) {
      return '${difference.inDays ~/ 30}ay önce';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}g önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}s önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}d önce';
    } else {
      return 'Şimdi';
    }
  }

  static String duration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static String fileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  static String viewCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}