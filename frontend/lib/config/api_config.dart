class ApiConfig {
  // Base URL backend REST API Python
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  
  // Format mata uang Rupiah
  static String formatRupiah(num amount) {
    final str = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join('')}';
  }
}
