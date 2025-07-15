class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-posta adresi gerekli';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Geçerli bir e-posta adresi girin';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gerekli';
    }

    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalı';
    }

    if (!RegExp(r'^(?=.*[A-Z])(?=.*\d).+$').hasMatch(value)) {
      return 'En az bir büyük harf ve rakam içermeli';
    }

    return null;
  }

  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ad soyad gerekli';
    }

    if (value.trim().split(' ').length < 2) {
      return 'Lütfen ad ve soyadınızı girin';
    }

    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName gerekli';
    }
    return null;
  }

  static String? amount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tutar gerekli';
    }

    final amount = double.tryParse(value.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      return 'Geçerli bir tutar girin';
    }

    return null;
  }

  static String? percentage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Hisse oranı gerekli';
    }

    final percentage = double.tryParse(value.replaceAll(',', '.'));
    if (percentage == null || percentage <= 0 || percentage > 100) {
      return 'Geçerli bir oran girin (0-100)';
    }

    return null;
  }

  static String? companyName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şirket adı gerekli';
    }

    if (value.length < 2) {
      return 'Şirket adı en az 2 karakter olmalı';
    }

    return null;
  }

  static String? website(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Website is optional
    }

    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Geçerli bir web adresi girin';
    }

    return null;
  }

  static String? bio(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Bio is optional
    }

    if (value.length > 500) {
      return 'Biyografi en fazla 500 karakter olabilir';
    }

    return null;
  }
}
