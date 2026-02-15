import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Pastikan IP ini benar (IP Laptop kamu)
  final String baseUrl = "http://10.131.166.25:8000/api";

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print("Mencoba login ke: $baseUrl/login"); // Cek URL

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        body: {'email': email, 'password': password},
      );

      // --- BAGIAN INI SAYA TAMBAHKAN BUAT NGINTIP ERRORNYA ---
      print("=== MULAI DEBUG LARAVEL ===");
      print(
        "Status Code: ${response.statusCode}",
      ); // Kalau 200 aman, kalau 500 error server
      print(
        "Isi Pesan: ${response.body}",
      ); // Ini bakal kasih tau error Laravelnya apa
      print("=== SELESAI DEBUG LARAVEL ===");
      // ---------------------------------------------------------

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        // Simpan data user
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', json.encode(data['user']));

        // Simpan token (buat jaga-jaga kalau nanti butuh)
        if (data['token'] != null) {
          await prefs.setString('token', data['token']);
        }

        return {'success': true, 'data': data['user'], 'token': data['token']};
      } else {
        // Kalau server nolak (misal password salah atau error 500)
        // Kita coba decode, kalau gagal decode (karena HTML), kita tangkap errornya
        try {
          var errorData = json.decode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Login Gagal',
          };
        } catch (e) {
          // Ini yang terjadi sekarang (HTML masuk sini)
          return {
            'success': false,
            'message': 'Error Server (HTML): Cek Debug Console',
          };
        }
      }
    } catch (e) {
      print("Error Koneksi Flutter: $e");
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }
}
