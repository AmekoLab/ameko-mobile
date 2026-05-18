/// Centralized form validators. Use with flutter_form_builder validators.
class AppValidators {
  AppValidators._();

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    if (cleaned.length < 8 || cleaned.length > 15) {
      return 'Số điện thoại không hợp lệ';
    }
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Số điện thoại chỉ được chứa chữ số';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập tên';
    }
    if (value.trim().length < 2) {
      return 'Tên phải có ít nhất 2 ký tự';
    }
    return null;
  }

  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập mã OTP';
    }
    if (value.length < 4 || value.length > 6) {
      return 'Mã OTP không hợp lệ';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Mã OTP chỉ được chứa chữ số';
    }
    return null;
  }

  static String? validateRequired(String? value, {String label = 'Trường này'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label là bắt buộc';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (value != password) {
      return 'Mật khẩu không khớp';
    }
    return null;
  }
}
