import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/siswa_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl =
      "http://10.131.166.25:8000/api"; // Ganti ke IP laptop jika pakai HP asli

  Future<List<SiswaModel>> getSiswa() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token'); // Ambil token

    final response = await http.get(
      Uri.parse('$baseUrl/siswa-saya'),
      headers: {
        'Authorization': 'Bearer $token', // Kirim token ke Laravel
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body)['data'];
      return data.map((item) => SiswaModel.fromJson(item)).toList();
    } else {
      print("Gagal ambil data siswa. Status: ${response.statusCode}");
      print("Body: ${response.body}");
      throw Exception('Gagal ambil data siswa: ${response.statusCode}');
    }
  }
}
