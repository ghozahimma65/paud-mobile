import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
// --- IMPORT MENU KAMU ---
import 'rencana_kunjungan_page.dart';
import 'list_siswa_page.dart';
import 'scan_penjemputan_page.dart';
import '../screens/login_screen.dart';
// IMPORT FILE BARU KITA (Jangan dihapus ya, file-nya kita bikin di bawah)
import 'riwayat_penilaian_page.dart';

class DashboardGuruPage extends StatefulWidget {
  const DashboardGuruPage({super.key});

  @override
  State<DashboardGuruPage> createState() => _DashboardGuruPageState();
}

class _DashboardGuruPageState extends State<DashboardGuruPage> {
  String? namaGuru;
  bool _isLoading = true;
  List<dynamic> _listPengumuman = [];
  bool _loadingPengumuman = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchPengumuman();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString('user_data');
    if (dataString != null) {
      final data = jsonDecode(dataString);
      setState(() {
        namaGuru = data['name'];
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPengumuman() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('http://192.168.18.36:8000/api/pengumuman'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      // --- PASANG CCTV PENGUMUMAN ---
      print("=== CEK API PENGUMUMAN ===");
      print("Status Code: ${response.statusCode}");
      print("Body JSON: ${response.body}");
      print("==========================");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          _listPengumuman = json['data'] ?? json;
          _loadingPengumuman = false;
        });
      } else {
        setState(() => _loadingPengumuman = false);
      }
    } catch (e) {
      print("Error Pengumuman: $e");
      setState(() => _loadingPengumuman = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F7FA,
      ), // Latar belakang abu-abu sangat soft
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER GRADIENT MEWAH ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 60,
                left: 20,
                right: 20,
                bottom: 40,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF4A00E0),
                    Color(0xFF8E2DE2),
                  ], // Gradasi Ungu Modern
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Selamat Datang,",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                namaGuru ?? "Bu Guru",
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _logout,
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  // SEARCH BAR DI DALAM HEADER
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Cari data siswa...",
                        hintStyle: GoogleFonts.poppins(color: Colors.grey),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.purple,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- KOTAK PENGUMUMAN ELEGAN ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Informasi Sekolah",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 150,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child:
                  _loadingPengumuman
                      ? const Center(child: CircularProgressIndicator())
                      : _listPengumuman.isEmpty
                      ? Center(
                        child: Text(
                          "Tidak ada pengumuman terbaru",
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.all(15),
                        itemCount: _listPengumuman.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = _listPengumuman[index];

                          String formatTgl(String? tgl) {
                            if (tgl == null) return "";
                            try {
                              return DateFormat(
                                'dd MMM yyyy',
                              ).format(DateTime.parse(tgl));
                            } catch (e) {
                              return tgl.split('T')[0];
                            }
                          }

                          String tanggalInfo = formatTgl(item['tanggal_mulai']);
                          if (item['tanggal_mulai'] != null &&
                              item['tanggal_selesai'] != null) {
                            tanggalInfo =
                                "${formatTgl(item['tanggal_mulai'])} s/d ${formatTgl(item['tanggal_selesai'])}";
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.campaign,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['judul'] ?? "Tanpa Judul",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      item['isi'] ?? "-",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      tanggalInfo,
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
            ),

            const SizedBox(height: 25),

            // --- MENU UTAMA (GRID KOTAK-KOTAK MEWAH) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Menu Utama",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.1, // Membuat proporsi kotaknya pas
                children: [
                  _buildMenuCard(
                    title: "Rencana Visit",
                    icon: Icons.map,
                    color: Colors.blue,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RencanaKunjunganPage(),
                          ),
                        ),
                  ),
                  _buildMenuCard(
                    title: "Input Laporan",
                    icon: Icons.edit_note,
                    color: Colors.orange,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ListSiswaPage(),
                          ),
                        ),
                  ),
                  _buildMenuCard(
                    title: "Riwayat Nilai",
                    icon: Icons.history_edu,
                    color: Colors.purple,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RiwayatPenilaianPage(),
                          ),
                        ),
                  ),
                  _buildMenuCard(
                    title: "Data Kelas",
                    icon: Icons.people_alt,
                    color: Colors.teal,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ListSiswaPage(),
                          ),
                        ),
                  ),
                  _buildMenuCard(
                    title: "Scan Jemput",
                    icon: Icons.qr_code_scanner,
                    color: Colors.green,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ScanPenjemputanPage(),
                          ),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // WIDGET BANTUAN UNTUK KOTAK MENU
  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 35, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
