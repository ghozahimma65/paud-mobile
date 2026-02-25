import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RiwayatPenilaianPage extends StatefulWidget {
  const RiwayatPenilaianPage({super.key});

  @override
  State<RiwayatPenilaianPage> createState() => _RiwayatPenilaianPageState();
}

class _RiwayatPenilaianPageState extends State<RiwayatPenilaianPage> {
  List<dynamic> _listAnekdot = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRiwayatAnekdot();
  }

  Future<void> _fetchRiwayatAnekdot() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('http://192.168.18.36:8000/api/guru/anekdot'), 
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      // --- PASANG CCTV DI SINI ---
      print("=== CEK API ANEKDOT ===");
      print("Status Code: ${response.statusCode}");
      print("Body JSON: ${response.body}");
      print("=======================");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // Kalau datanya dibungkus 'data', pakai data['data']. Kalau beda, nanti kita sesuaikan.
          _listAnekdot = data['data'] ?? data; 
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error Fetch Riwayat: $e");
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Ada 3 Tab
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text("Riwayat Penilaian", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: TabBar(
            labelColor: Colors.blue.shade700,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue.shade700,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Anekdot"),
              Tab(text: "Ceklis"),
              Tab(text: "Hasil Karya"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: ANEKDOT (Data Asli dari Database)
            _buildTabAnekdot(),
            
            // TAB 2: CEKLIS (Coming Soon / Placeholder)
            _buildTabPlaceholder(Icons.checklist, "Riwayat Ceklis Belum Tersedia"),
            
            // TAB 3: HASIL KARYA (Coming Soon / Placeholder)
            _buildTabPlaceholder(Icons.brush, "Riwayat Hasil Karya Belum Tersedia"),
          ],
        ),
      ),
    );
  }

  // TAMPILAN LIST ANEKDOT
  Widget _buildTabAnekdot() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_listAnekdot.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text("Belum ada catatan anekdot", style: GoogleFonts.poppins(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _listAnekdot.length,
      itemBuilder: (context, index) {
        final item = _listAnekdot[index];
        // Membaca kategori (Sekolah atau Home Visit)
        bool isHomeVisit = item['kategori'] == "Home Visit" || item['tempat'] == "Rumah Siswa (Home Visit)";

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            border: Border.all(color: isHomeVisit ? Colors.orange.shade100 : Colors.blue.shade100),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isHomeVisit ? Colors.orange.shade50 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isHomeVisit ? "🏠 Home Visit" : "🏫 Di Sekolah",
                        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: isHomeVisit ? Colors.orange.shade700 : Colors.blue.shade700),
                      ),
                    ),
                    Text(
                      item['tanggal'] ?? "Tanggal -",
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey.shade200,
                      child: const Icon(Icons.person, size: 18, color: Colors.grey),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        // Tergantung nama relasi di Laravel, misal: item['siswa']['nama_siswa']
                        item['siswa']?['nama_siswa'] ?? "Nama Siswa Tidak Diketahui",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text("Kejadian Teramati:", style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                Text(
                  item['kejadian_teramati'] ?? item['uraian_kejadian'] ?? "-",
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // WIDGET BANTUAN UNTUK TAB YANG BELUM JADI
  Widget _buildTabPlaceholder(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 15),
          Text(text, style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }
}