import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/siswa_model.dart';

class InputCeklisPage extends StatefulWidget {
  final SiswaModel siswa;
  const InputCeklisPage({super.key, required this.siswa});

  @override
  State<InputCeklisPage> createState() => _InputCeklisPageState();
}

class _InputCeklisPageState extends State<InputCeklisPage> {
  bool _isLoading = false;
  String? _selectedHasil;
  final _indikatorController = TextEditingController();
  final _keteranganController = TextEditingController();

  // Skala Penilaian PAUD sesuai kodingan Controller Admin kamu
  final List<Map<String, String>> _listSkala = [
    {"kode": "BB", "nama": "Belum Berkembang"},
    {"kode": "MB", "nama": "Mulai Berkembang"},
    {"kode": "BSH", "nama": "Berhasil Sesuai Harapan"},
    {"kode": "BSB", "nama": "Berhasil Sangat Baik"},
  ];

  Future<void> _simpanCeklis() async {
    if (_selectedHasil == null || _indikatorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Indikator dan Hasil harus diisi!")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.18.36:8000/api/guru/ceklis',
        ), // Pastikan IP benar
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'siswa_id': widget.siswa.id,
          'tanggal': DateTime.now().toString().split(' ')[0],
          'indikator': _indikatorController.text,
          'hasil': _selectedHasil,
          'keterangan': _keteranganController.text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Penilaian Ceklis Berhasil Disimpan!")),
        );
        Navigator.pop(context);
      } else {
        throw Exception(
          "Gagal menyimpan data (${response.statusCode}): ${response.body}",
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Ceklis: ${widget.siswa.namaSiswa}",
          style: GoogleFonts.poppins(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Indikator Perkembangan"),
            TextField(
              controller: _indikatorController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Misal: Mencuci tangan sebelum makan",
              ),
            ),
            const SizedBox(height: 20),

            _buildLabel("Hasil Capaian (Skala)"),
            // Menggunakan Radio List agar guru mudah memilih
            ..._listSkala.map(
              (skala) => RadioListTile<String>(
                title: Text("${skala['kode']} (${skala['nama']})"),
                value: skala['kode']!,
                groupValue: _selectedHasil,
                onChanged: (val) => setState(() => _selectedHasil = val),
              ),
            ),

            const SizedBox(height: 20),

            _buildLabel("Keterangan Tambahan"),
            TextField(
              controller: _keteranganController,
              maxLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Tambahkan catatan jika perlu...",
              ),
            ),

            const SizedBox(height: 30),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _simpanCeklis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text(
                      "Simpan Penilaian",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
