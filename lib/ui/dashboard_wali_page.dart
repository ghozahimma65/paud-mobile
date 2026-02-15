import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Library QR Code
import 'package:http/http.dart' as http;
import 'dart:convert';

// Ganti dengan halaman login kamu
import '../screens/login_screen.dart';

// KITA AKAN BUAT HALAMAN LIST INI NANTI (Placeholder dulu biar gak error)
// Kalau belum ada file-nya, kamu bisa komen dulu import-nya
// import 'riwayat_anekdot_page.dart';
// import 'riwayat_karya_page.dart';
// import 'riwayat_ceklis_page.dart';

class DashboardWaliPage extends StatefulWidget {
  const DashboardWaliPage({super.key});

  @override
  State<DashboardWaliPage> createState() => _DashboardWaliPageState();
}

class _DashboardWaliPageState extends State<DashboardWaliPage> {
  bool _isLoading = true;
  String? namaAnak;
  String? kelompokUsia;
  String? fotoAnak;
  int? siswaId; // PENTING: Ini yang jadi isi QR Code

  @override
  void initState() {
    super.initState();
    _fetchDataAnak();
  }

  // 1. AMBIL DATA ANAK (Sesuai Login Wali)
  Future<void> _fetchDataAnak() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Asumsi: Saat login wali murid, API login mengembalikan data 'siswa' atau 'anak'
    // Kalau tidak, kita harus fetch manual ke endpoint /api/me atau sejenisnya
    // Di sini saya coba simulasi ambil dari local storage dulu kalau ada
    final userString = prefs.getString('user_data');

    if (userString != null) {
      // Cek data user
      // PENTING: Pastikan respon Login API kamu menyertakan data 'siswa'
      // atau kamu buat endpoint khusus GET /api/wali/my-child

      // SEMENTARA: Kita tembak data dummy dulu biar UI TAMPIL
      // Nanti kita sesuaikan dengan respon API aslimu
      setState(() {
        namaAnak = "Ananda Budi"; // Ganti logika ini nanti
        kelompokUsia = "Kelompok B (5-6 Tahun)";
        siswaId = 1; // ID Siswa 1 (Coba ganti sesuai database kamu: 1, 2, dst)
        _isLoading = false;
      });
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Dashboard Wali Murid",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. KARTU PENJEMPUTAN (QR CODE) ---
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Kartu Penjemputan",
                              style: GoogleFonts.poppins(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              namaAnak ?? "-",
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            Text(
                              kelompokUsia ?? "-",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // --- GENERATOR QR CODE ---
                            // Isinya adalah String ID Siswa (misal "1")
                            QrImageView(
                              // Tambah text "SISWA-" biar polanya lebih rumit & gampang discan
                              data: "SISWA-${siswaId}",
                              version: QrVersions.auto,
                              size: 280.0, // Ukuran Besar
                              // --- INI KUNCINYA BIAR BISA DISCAN ---
                              backgroundColor: Colors.white, // Wajib Putih
                              padding: const EdgeInsets.all(
                                30,
                              ), // Wajib ada jarak putih pinggir
                              gapless: false,
                            ),

                            const SizedBox(height: 10),
                            Text(
                              "Tunjukkan ke Guru saat menjemput",
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- 2. MENU RAPOT / LAPORAN ---
                    Text(
                      "Laporan Perkembangan",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Menu Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.3,
                      children: [
                        _buildMenuRapot(
                          title: "Catatan\nAnekdot",
                          icon: Icons.note_alt,
                          color: Colors.orange,
                          onTap: () {
                            // Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatAnekdotPage()));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Fitur Riwayat Anekdot Segera Hadir!",
                                ),
                              ),
                            );
                          },
                        ),
                        _buildMenuRapot(
                          title: "Hasil\nKarya",
                          icon: Icons.palette,
                          color: Colors.purple,
                          onTap: () {
                            // Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatKaryaPage()));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Fitur Riwayat Karya Segera Hadir!",
                                ),
                              ),
                            );
                          },
                        ),
                        _buildMenuRapot(
                          title: "Ceklis\nPerkembangan",
                          icon: Icons.checklist_rtl,
                          color: Colors.green,
                          onTap: () {
                            // Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatCeklisPage()));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Fitur Riwayat Ceklis Segera Hadir!",
                                ),
                              ),
                            );
                          },
                        ),
                        _buildMenuRapot(
                          title: "Informasi\nSekolah",
                          icon: Icons.info,
                          color: Colors.blue,
                          onTap: () {
                            // Boleh arahkan ke halaman pengumuman yang tadi
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildMenuRapot({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
