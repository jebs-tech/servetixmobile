/// Configuration untuk Payment Service
/// Gunakan ini untuk switch antara Mock Data dan Real API

class PaymentServiceConfig {
  // Set true untuk menggunakan mock data (testing tanpa backend)
  // Set false untuk menggunakan real API dari Django
  static const bool USE_MOCK_DATA = true; // Ganti ke false saat backend sudah siap
  
  // Catatan:
  // - Saat USE_MOCK_DATA = true, akan menggunakan MockDataService
  // - Saat USE_MOCK_DATA = false, akan menggunakan PaymentApiService
  // - Pastikan untuk mengubah ke false sebelum merge dengan kode teman
}

