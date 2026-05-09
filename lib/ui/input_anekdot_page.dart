import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/siswa_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class InputAnekdotPage extends StatefulWidget {
  final SiswaModel siswa;
  final String kategori; // Tambahan Kategori Otomatis

  const InputAnekdotPage({
    super.key, 
    required this.siswa,
    this.kategori = "Sekolah", // Default jika dibuka dari dashboard
  });

  @override
  State<InputAnekdotPage> createState() => _InputAnekdotPageState();
}

class _InputAnekdotPageState extends State<InputAnekdotPage> {
  final _tempatController = TextEditingController();
  final _uraianController = TextEditingController();
  final _kejadianController = TextEditingController();
  final _analisisController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // OTOMATIS MENGISI TEMPAT JIKA DIBUKA DARI PETA HOME VISIT
    if (widget.kategori == "Home Visit") {
      _tempatController.text = "Rumah Siswa (Home Visit)";
    }
  }

  Future<void> simpanAnekdot() async {
    // Validasi singkat
    if (_uraianController.text.isEmpty || _kejadianController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lengkapi catatan terlebih dahulu!")));
      return;
    }

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('http://192.168.18.36:8000/api/guru/anekdot'),
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
          'kategori': widget.kategori, // Kirim kategori sebagai pembeda
        }),
      );

      // Anggap 200 atau 201 itu berhasil (tergantung settingan Laravelmu)
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Anekdot ${widget.kategori} Berhasil Disimpan!")),
        );
        // PENTING: Kembalikan TRUE agar peta tahu tugas selesai
        if (!mounted) return;
        Navigator.pop(context, true); 
      } else {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menyimpan. Kode: ${response.statusCode}")));
      }
    } catch (e) {
      print("Error Anekdot: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ubah warna UI berdasarkan Kategori
    bool isHomeVisit = widget.kategori == "Home Visit";
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Anekdot ${widget.kategori}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: isHomeVisit ? Colors.orange.shade100 : Colors.blue.shade100,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Siswa
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(isHomeVisit ? Icons.home_work : Icons.school, color: isHomeVisit ? Colors.orange : Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(child: Text(widget.siswa.namaSiswa ?? "Nama Siswa", style: GoogleFonts.poppins(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildInput("Tempat Kejadian", _tempatController),
            _buildInput("Uraian Kejadian", _uraianController, maxLines: 3),
            _buildInput("Kejadian Teramati", _kejadianController, maxLines: 3),
            _buildInput("Analisis Capaian Guru", _analisisController, maxLines: 3),
            
            const SizedBox(height: 20),
            
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: simpanAnekdot,
                      icon: const Icon(Icons.save, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isHomeVisit ? Colors.orange.shade700 : Colors.blue.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      label: Text("Simpan Laporan", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}