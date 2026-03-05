import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_services/api_service.dart';

class InputRapotPage extends StatefulWidget {
  const InputRapotPage({super.key});

  @override
  State<InputRapotPage> createState() => _InputRapotPageState();
}

class _InputRapotPageState extends State<InputRapotPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  bool _isSubmitting = false;

  List<dynamic> _siswaList = [];
  String? _selectedSiswaId;
  String? _selectedSemester;
  String? _selectedTahunAjaran;

  // Teks Narasi
  final TextEditingController _aikCtrl = TextEditingController();
  final TextEditingController _budiPekertiCtrl = TextEditingController();
  final TextEditingController _jatiDiriCtrl = TextEditingController();
  final TextEditingController _literasiCtrl = TextEditingController();
  final TextEditingController _kokurikulerCtrl = TextEditingController();
  final TextEditingController _catatanGuruCtrl = TextEditingController();

  // Pertumbuhan & Kehadiran
  final TextEditingController _tinggiCtrl = TextEditingController();
  final TextEditingController _beratCtrl = TextEditingController();
  final TextEditingController _kepalaCtrl = TextEditingController();
  final TextEditingController _sakitCtrl = TextEditingController();
  final TextEditingController _izinCtrl = TextEditingController();
  final TextEditingController _alphaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSiswa();
  }

  Future<void> _fetchSiswa() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('${_apiService.baseUrl}/siswa-saya'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _siswaList = data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching siswa: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRapot() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSiswaId == null ||
        _selectedSemester == null ||
        _selectedTahunAjaran == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih Siswa, Semester, dan Tahun Ajaran!'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('${_apiService.baseUrl}/guru/rapot'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'siswa_id': _selectedSiswaId,
          'semester': _selectedSemester,
          'tahun_ajaran': _selectedTahunAjaran,
          'nilai_aik': _aikCtrl.text,
          'nilai_budi_pekerti': _budiPekertiCtrl.text,
          'nilai_jati_diri': _jatiDiriCtrl.text,
          'nilai_literasi_steam': _literasiCtrl.text,
          'nilai_kokurikuler': _kokurikulerCtrl.text,
          'catatan_guru': _catatanGuruCtrl.text,
          'tinggi_badan': _tinggiCtrl.text,
          'berat_badan': _beratCtrl.text,
          'lingkar_kepala': _kepalaCtrl.text,
          'sakit': _sakitCtrl.text,
          'izin': _izinCtrl.text,
          'alpha': _alphaCtrl.text,
        }),
      );

      print("=== SUBMIT RAPOT RESPONSE ===");
      print(response.statusCode);
      print(response.body);

      setState(() => _isSubmitting = false);

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rapot berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Kembali ke dashboard
      } else {
        final decoded = jsonDecode(response.body);
        TargetPlatform;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decoded['message'] ?? 'Gagal menyimpan rapot'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      debugPrint("Error submit rapot: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan koneksi!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          "Input Rapot",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E88E5), // Warna biru Guru
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("Identitas Rapot"),
                      // Dropdown Siswa
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration("Pilih Siswa"),
                        items:
                            _siswaList.map((s) {
                              return DropdownMenuItem<String>(
                                value: s['id'].toString(),
                                child: Text(s['nama_siswa'] ?? 'Unknown'),
                              );
                            }).toList(),
                        onChanged:
                            (val) => setState(() => _selectedSiswaId = val),
                        validator:
                            (val) => val == null ? 'Wajib pilih siswa' : null,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: _inputDecoration("Semester"),
                              items: const [
                                DropdownMenuItem(
                                  value: "Ganjil",
                                  child: Text("Ganjil"),
                                ),
                                DropdownMenuItem(
                                  value: "Genap",
                                  child: Text("Genap"),
                                ),
                              ],
                              onChanged:
                                  (val) =>
                                      setState(() => _selectedSemester = val),
                              validator: (val) => val == null ? 'Wajib' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: _inputDecoration("Tahun Ajaran"),
                              items: const [
                                DropdownMenuItem(
                                  value: "2024/2025",
                                  child: Text("2024/2025"),
                                ),
                                DropdownMenuItem(
                                  value: "2025/2026",
                                  child: Text("2025/2026"),
                                ),
                              ],
                              onChanged:
                                  (val) => setState(
                                    () => _selectedTahunAjaran = val,
                                  ),
                              validator: (val) => val == null ? 'Wajib' : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      _buildSectionHeader("Capaian Pembelajaran (Narasi)"),
                      _buildTextArea("Agama & Budi Pekerti (AIK)", _aikCtrl),
                      _buildTextArea("Sikap Budi Pekerti", _budiPekertiCtrl),
                      _buildTextArea("Jati Diri", _jatiDiriCtrl),
                      _buildTextArea("Literasi & STEAM", _literasiCtrl),
                      _buildTextArea("Kokurikuler / P5", _kokurikulerCtrl),
                      _buildTextArea("Pesan & Catatan Guru", _catatanGuruCtrl),

                      const SizedBox(height: 24),
                      _buildSectionHeader("Pertumbuhan Fisik"),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNumberInput(
                              "Tinggi (cm)",
                              _tinggiCtrl,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildNumberInput("Berat (kg)", _beratCtrl),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildNumberInput(
                              "Kepala (cm)",
                              _kepalaCtrl,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      _buildSectionHeader("Ketidakhadiran"),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNumberInput(
                              "Sakit (hari)",
                              _sakitCtrl,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildNumberInput("Izin (hari)", _izinCtrl),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildNumberInput(
                              "Alpha (hari)",
                              _alphaCtrl,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitRapot,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child:
                              _isSubmitting
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Text(
                                    "Simpan Rapot",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1E88E5),
        ),
      ),
    );
  }

  Widget _buildTextArea(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: 4,
        decoration: _inputDecoration(label),
        validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
      ),
    );
  }

  Widget _buildNumberInput(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: _inputDecoration(label),
      validator: (val) => val == null || val.isEmpty ? 'Wajib' : null,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.all(16),
    );
  }
}
