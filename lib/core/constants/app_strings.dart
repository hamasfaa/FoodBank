class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'FoodBridge';
  static const String appTagline = 'Berbagi itu mudah, yuk mulai!';

  // Register page
  static const String register = 'Daftar';
  static const String createAccount = 'Buat Akun';
  static const String createAccountSubtitle =
      'Lengkapi data kamu dan mulai berbagi kebaikan.';
  static const String registerNow = 'Daftar Sekarang';
  static const String alreadyHaveAccount = 'Sudah punya akun?';
  static const String login = 'Masuk';
  static const String orDivider = 'atau';
  static const String continueWithGoogle = 'Lanjutkan dengan Google';

  // Login page
  static const String loginTitle = 'Selamat Datang Kembali';
  static const String loginSubtitle = 'Masuk untuk melanjutkan aksi baikmu.';
  static const String loginNow = 'Masuk Sekarang';
  static const String dontHaveAccount = 'Belum punya akun?';
  static const String errorInvalidCredentials = 'Email atau kata sandi salah';

  // Complete profile page
  static const String completeProfile = 'Lengkapi Profil';
  static const String completeProfileSubtitle =
      'Satu langkah lagi sebelum mulai.';
  static const String googleAccount = 'Akun Google';
  static const String saveAndContinue = 'Simpan & Lanjutkan';

  // Form labels
  static const String fullName = 'Nama Lengkap';
  static const String email = 'Email';
  static const String phoneNumber = 'Nomor HP';
  static const String password = 'Kata Sandi';
  static const String confirmPassword = 'Konfirmasi Kata Sandi';

  // Role selector
  static const String roleTitle = 'Daftar sebagai';
  static const String rolePemberi = 'Pemberi';
  static const String rolePemberiSub = 'Saya ingin berbagi';
  static const String rolePenerima = 'Penerima';
  static const String rolePenerimaSub = 'Saya butuh bantuan';

  // Validation errors
  static const String fieldRequired = 'Kolom ini wajib diisi';
  static const String validFullName = 'Nama minimal 3 karakter';
  static const String validEmail = 'Format email tidak valid';
  static const String validPhone = 'Format nomor HP tidak valid (08xx / +62xx)';
  static const String validPassword =
      'Kata sandi minimal 8 karakter, harus mengandung huruf dan angka';
  static const String validConfirmPassword = 'Konfirmasi kata sandi tidak cocok';
  static const String validRole = 'Pilih peran Anda terlebih dahulu';

  // Firebase errors
  static const String errorEmailInUse = 'Email sudah terdaftar, silakan login';
  static const String errorWeakPassword = 'Kata sandi terlalu lemah';
  static const String errorNetworkFailed = 'Tidak ada koneksi internet';
  static const String errorGeneral = 'Terjadi kesalahan, coba lagi';

  // Success
  static const String registerSuccess = 'Pendaftaran berhasil!';
}
