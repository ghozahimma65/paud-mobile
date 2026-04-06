import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import '../screens/login_screen.dart';
import '../services/api_services/api_service.dart';
import 'riwayat_penilaian_wali_page.dart';
import 'rapot_wali_page.dart';

class DashboardWaliPage extends StatefulWidget {
  const DashboardWaliPage({super.key});

  @override
  State<DashboardWaliPage> createState() => _DashboardWaliPageState();
}

class _DashboardWaliPageState extends State<DashboardWaliPage> {
  bool _isLoading = true;

  // Data State
  String? namaWali;
  Map<String, dynamic>? siswaData;
  Map<String, dynamic>? pengumumanData;
  Map<String, dynamic>? penjemputanData;
  List<dynamic> progressData = [];

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Parse user data for Parent Name
    final userString = prefs.getString('user_data');
    if (userString != null) {
      final userJson = jsonDecode(userString);
      setState(() {
        namaWali = userJson['name'];
      });
    }

    if (token == null) {
      _prosesLogout();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${_apiService.baseUrl}/wali/dashboard'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          siswaData = data['siswa'];
          pengumumanData = data['pengumuman'];
          progressData = data['progress'] ?? [];
          penjemputanData = data['penjemputan_terakhir'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        debugPrint('Gagal mengambil data dashboard wali: ${response.body}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error: $e');
    }
  }

  Future<void> _prosesLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Konfirmasi Logout", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text("Apakah Anda yakin ingin keluar dari aplikasi?", style: GoogleFonts.poppins()),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
              },
              child: Text("Batal", style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                _prosesLogout(); // Eksekusi hapus session
              },
              child: Text("Ya, Keluar", style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // 2. SMART NOTIFICATION: Cek apakah sudah waktunya menjemput (Jam >= 11:00)
  bool _isWaktuPulang() {
    final now = DateTime.now();
    return now.hour >= 11;
  }

  @override
  Widget build(BuildContext context) {
    bool showPulangAlert = _isWaktuPulang() && siswaData != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.purple),
              )
              : RefreshIndicator(
                onRefresh: _fetchDashboardData,
                child: CustomScrollView(
                  slivers: [
                    _buildPremiumAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 25,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showPulangAlert) ...[
                              _buildAlertPenjemputan(),
                              const SizedBox(height: 25),
                            ],

                            if (siswaData != null) ...[
                              _buildQRCard(),
                              const SizedBox(height: 30),
                            ],

                            if (pengumumanData != null) ...[
                              _buildSectionTitle("Pengumuman Terbaru"),
                              const SizedBox(height: 15),
                              _buildPengumumanCard(),
                              const SizedBox(height: 30),
                            ],

                            _buildSectionTitle("Progress Perkembangan"),
                            const SizedBox(height: 15),
                            _buildProgressList(),

                            const SizedBox(height: 30),
                            _buildSectionTitle("Monitoring & Laporan"),
                            const SizedBox(height: 15),
                            _buildMenuGrid(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  // --- 1. HEADER & QR CODE: PREMIUM APP BAR ---
  SliverAppBar _buildPremiumAppBar() {
    return SliverAppBar(
      expandedHeight: 140.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        backgroundImage:
                            siswaData != null && siswaData!['foto'] != null
                                ? NetworkImage(
                                  '${_apiService.baseUrl.replaceAll('/api', '')}/storage/${siswaData!['foto']}',
                                )
                                : null,
                        child:
                            siswaData == null || siswaData!['foto'] == null
                                ? const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 28,
                                )
                                : null,
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Selamat Datang,",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            namaWali ?? "Bunda/Ayah",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: _logout,
                      tooltip: 'Logout',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET TITLE ---
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  // --- 2. SMART NOTIFICATION ALERT ---
  Widget _buildAlertPenjemputan() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.alarm, color: Colors.amber.shade700, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              "⏰ Waktunya Menjemput! QR Code Anda sudah siap digunakan.",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. HEADER & QR CODE: KARTU QR PENJEMPUTAN ---
  Widget _buildQRCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 2),
      ),
      child: Column(
        children: [
          Text(
            "Kartu Jemput Digital",
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            siswaData!['nama'] ?? "-",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          Container(
            margin: const EdgeInsets.only(top: 5, bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              siswaData!['kelas'] ?? "-",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.purple.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: QrImageView(
              data:
                  "SISWA-${siswaData!['id']}", // QR Code berisikan SISWA-sekian
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(20),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_scanner,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 5),
              Text(
                "Tunjukkan kode ini kepada Guru",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          if (penjemputanData != null) ...[
            const SizedBox(height: 15),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 14, color: Colors.green.shade600),
                const SizedBox(width: 5),
                Text(
                  "Penjemputan Terakhir: ${DateFormat('dd MMM HH:mm').format(DateTime.parse(penjemputanData!['created_at']))}",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- 3. PROGRESS PERKEMBANGAN (Visualisasi) ---
  Widget _buildProgressList() {
    if (progressData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text("Belum ada data nilai ceklis.")),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children:
            progressData.map((item) {
              int percent = int.parse(item['nilai'].toString());

              // Logika Warna Dinamis: Abu-abu (0), Merah (<50), Orange (<75), Hijau (>=75)
              Color color;
              if (percent == 0) {
                color = Colors.grey.shade400;
              } else if (percent < 50) {
                color = Colors.redAccent;
              } else if (percent < 75) {
                color = Colors.orange;
              } else {
                color = Colors.green;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['aspek'],
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          "$percent%",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: percent / 100.0,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  // --- 4. MONITORING MENU (Action Cards) ---
  Widget _buildMenuGrid() {
    if (siswaData == null) return const SizedBox();

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildMenuCard(
          title: "Laporan Anekdot",
          icon: Icons.assignment,
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => RiwayatPenilaianWaliPage(
                      siswaId: siswaData!['id'],
                      namaSiswa: siswaData!['nama'],
                      initialTabIndex: 0,
                    ),
              ),
            );
          },
        ),
        _buildMenuCard(
          title: "Ceklis Perkembangan",
          icon: Icons.checklist,
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => RiwayatPenilaianWaliPage(
                      siswaId: siswaData!['id'],
                      namaSiswa: siswaData!['nama'],
                      initialTabIndex: 1,
                    ),
              ),
            );
          },
        ),
        _buildMenuCard(
          title: "Hasil Karya",
          icon: Icons.brush,
          color: Colors.purple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => RiwayatPenilaianWaliPage(
                      siswaId: siswaData!['id'],
                      namaSiswa: siswaData!['nama'],
                      initialTabIndex: 2,
                    ),
              ),
            );
          },
        ),
        _buildMenuCard(
          title: "Hasil Rapot",
          icon: Icons.assignment_turned_in,
          color: Colors.teal,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RapotWaliPage(siswaId: siswaData!['id']),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: color.shade50, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PENGUMUMAN WIDGET ---
  Widget _buildPengumumanCard() {
    String tglMulai = "-";
    if (pengumumanData!['tanggal_mulai'] != null) {
      tglMulai = DateFormat(
        'dd MMM yyyy',
      ).format(DateTime.parse(pengumumanData!['tanggal_mulai']));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.push_pin, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pengumumanData!['judul'] ?? "Pengumuman",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            pengumumanData!['isi'] ?? "-",
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.calendar_today, size: 12, color: Colors.blue.shade400),
              const SizedBox(width: 5),
              Text(
                tglMulai,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
