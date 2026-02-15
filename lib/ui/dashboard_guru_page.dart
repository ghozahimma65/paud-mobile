import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- PASTIKAN IMPORT INI SESUAI DENGAN NAMA FILE KAMU ---
import 'list_siswa_page.dart';
import 'scan_penjemputan_page.dart';
import '../screens/login_screen.dart';

class DashboardGuruPage extends StatefulWidget {
  const DashboardGuruPage({super.key});

  @override
  State<DashboardGuruPage> createState() => _DashboardGuruPageState();
}

class _DashboardGuruPageState extends State<DashboardGuruPage> {
  String? namaGuru;
  bool _isLoading = true;

  // Variabel untuk Pengumuman
  List<dynamic> _listPengumuman = [];
  bool _loadingPengumuman = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchPengumuman(); // Panggil fungsi ambil pengumuman
  }

  // 1. Ambil Nama Guru dari Shared Prefs
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

  // 2. Ambil Data Pengumuman dari API
  Future<void> _fetchPengumuman() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      // ⚠️ PENTING: GANTI IP INI SESUAI HASIL 'ipconfig' DI LAPTOP KAMU
      // Jika pakai Emulator Android Studio: 10.0.2.2
      // Jika pakai HP Fisik: Harus satu WiFi dan pakai IP Laptop (misal 192.168.x.x atau 10.131.x.x)
      final response = await http.get(
        Uri.parse('http://10.131.166.25:8000/api/pengumuman'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          _listPengumuman = json['data'];
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Selamat Pagi,",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        namaGuru ?? "Bu Guru",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_none,
                          color: Colors.purple,
                          size: 28,
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.red),
                        onPressed: _logout,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // --- SEARCH BAR ---
              TextField(
                decoration: InputDecoration(
                  hintText: "Search",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),

              const SizedBox(height: 24),

              // --- KOTAK INFORMASI (PENGUMUMAN) ---
              Text(
                "Informasi Sekolah",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                height: 160,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
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
                          itemCount: _listPengumuman.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final item = _listPengumuman[index];

                            // Logika Tanggal
                            String tanggalInfo = "";
                            if (item['tanggal_mulai'] != null &&
                                item['tanggal_selesai'] != null) {
                              tanggalInfo =
                                  "${item['tanggal_mulai']} s/d ${item['tanggal_selesai']}";
                            } else if (item['tanggal_mulai'] != null) {
                              tanggalInfo = item['tanggal_mulai'];
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // JUDUL
                                Text(
                                  item['judul'] ?? "Tanpa Judul",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // ISI
                                Text(
                                  item['isi'] ?? "-",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // TANGGAL
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 12,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      tanggalInfo,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
              ),

              const SizedBox(height: 24),

              // --- MENU KATEGORI ---
              Text(
                "Menu Guru",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              _buildMenuItem(
                title: "Data Kelas",
                icon: Icons.people_alt,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ListSiswaPage(),
                    ),
                  );
                },
              ),

              _buildMenuItem(
                title: "Input Laporan",
                icon: Icons.edit_note,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ListSiswaPage(),
                    ),
                  );
                },
              ),

              _buildMenuItem(
                title: "Scan Penjemputan",
                icon: Icons.qr_code_scanner,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScanPenjemputanPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Helper
  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.purple),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
