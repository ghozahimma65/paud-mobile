import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/siswa_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class InputAnekdotPage extends StatefulWidget {
  final SiswaModel siswa;
  const InputAnekdotPage({super.key, required this.siswa});

  @override
  State<InputAnekdotPage> createState() => _InputAnekdotPageState();
}

class _InputAnekdotPageState extends State<InputAnekdotPage> {
  // Controller disesuaikan dengan kolom di database kamu
  final _tempatController = TextEditingController();
  final _uraianController = TextEditingController();
  final _kejadianController = TextEditingController();
  final _analisisController = TextEditingController();

  bool _isLoading = false;

  Future<void> simpanAnekdot() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse(
          'http://10.131.166.25:8000/api/guru/anekdot',
        ), // Pastikan IP benar
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'siswa_id': widget.siswa.id,
          'tanggal': DateTime.now().toString().split(' ')[0],
          'waktu': TimeOfDay.now().format(context),
          'tempat': _tempatController.text,
          'uraian_kejadian': _uraianController.text,
          'kejadian_teramati': _kejadianController.text,
          'analisis_capaian': _analisisController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Anekdot Berhasil Simpan!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Input Anekdot: ${widget.siswa.namaSiswa}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInput("Tempat", _tempatController),
            _buildInput("Uraian Kejadian", _uraianController, maxLines: 3),
            _buildInput("Kejadian Teramati", _kejadianController, maxLines: 3),
            _buildInput("Analisis Capaian", _analisisController, maxLines: 3),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: simpanAnekdot,
                  child: const Text("Simpan Laporan"),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
