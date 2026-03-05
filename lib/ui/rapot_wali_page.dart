import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_services/api_service.dart';
import 'detail_rapot_wali_page.dart';

class RapotWaliPage extends StatefulWidget {
  final int siswaId;

  const RapotWaliPage({super.key, required this.siswaId});

  @override
  State<RapotWaliPage> createState() => _RapotWaliPageState();
}

class _RapotWaliPageState extends State<RapotWaliPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _rapotList = [];

  @override
  void initState() {
    super.initState();
    _fetchRapot();
  }

  Future<void> _fetchRapot() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      print("=== RAPOT SUPER DEBUG: MULAI FETCH ===");
      final url = Uri.parse(
        '${_apiService.baseUrl}/wali/rapot-anak/${widget.siswaId}',
      );
      print("TARGET URL: $url");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print("STATUS CODE: ${response.statusCode}");
      print("RESPONSE BODY: ${response.body}");
      print("=== RAPOT SUPER DEBUG: SELESAI ===");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _rapotList = decoded['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        print("GAGAL FETCH RAPOT: Status bukan 200");
      }
    } catch (e) {
      debugPrint("Error Fetching Rapot Anak: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          "Riwayat Hasil Rapot",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.purple),
              )
              : _rapotList.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _rapotList.length,
                itemBuilder: (context, index) {
                  final rapot = _rapotList[index];
                  return _buildRapotCard(rapot);
                },
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_late, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "Rapot belum tersedia",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Siswa belum memiliki riwayat rapot atau rapot semester ini sedang diproses.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRapotCard(Map<String, dynamic> rapot) {
    final semester = rapot['semester'] ?? '-';
    final tahunAjaran = rapot['tahun_ajaran'] ?? '-';
    final tanggal = rapot['tanggal_rapot'] ?? '-';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailRapotWaliPage(rapotData: rapot),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4A00E0).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description,
                color: Color(0xFF4A00E0),
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Semester $semester",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tahun Ajaran $tahunAjaran",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tgl Diterbitkan: $tanggal",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}
