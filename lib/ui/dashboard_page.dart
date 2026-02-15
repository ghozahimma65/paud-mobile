import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_services/api_service.dart'; // Pastikan path ini benar
import '../models/siswa_model.dart';
import '../screens/login_screen.dart';
import 'detail_anak_page.dart'; // <--- PANGGIL HALAMAN BARU TADI

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? namaWali;
  bool isLoading = true;
  List<SiswaModel> listAnak = []; // Kita pakai List biar bisa nampung 2 anak
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      var userData = jsonDecode(userDataString);
      setState(() {
        namaWali = userData['name'];
      });

      // Ambil data anak dari API
      try {
        List<SiswaModel> hasilApi = await _apiService.getSiswa();
        setState(() {
          listAnak = hasilApi;
        });
      } catch (e) {
        print("Gagal ambil data anak: $e");
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
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
                        namaWali ?? "Ibunda",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.purple),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // JUDUL LIST ANAK
              Text(
                "Anak Saya (${listAnak.length})",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),

              // LOOPING KARTU ANAK (Biar muncul 2 kalau anaknya 2)
              if (listAnak.isEmpty && isLoading)
                const Center(child: CircularProgressIndicator())
              else if (listAnak.isEmpty && !isLoading)
                const Text("Data anak tidak ditemukan.")
              else
                ...listAnak.map(
                  (anak) => _buildAnakCard(anak),
                ), // Tampilkan semua anak

              const SizedBox(height: 24),

              // TOMBOL QR CODE
              InkWell(
                onTap: () => _showQRCodeDialog(), // <--- KLIK QR CODE
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code, color: Colors.white, size: 30),
                      const SizedBox(width: 10),
                      Text(
                        "Tampilkan Tiket Penjemputan",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- KOMPONEN ---

  Widget _buildAnakCard(SiswaModel anak) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      ),
      child: Material(
        // Material & InkWell biar ada efek pencetnya
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // NAVIGASI KE HALAMAN DETAIL
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailAnakPage(siswa: anak),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      anak.namaSiswa != null ? anak.namaSiswa![0] : "-",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anak.namaSiswa ?? "-",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Kelas: ${anak.namaKelas} | NIS: ${anak.nis}",
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Klik untuk lihat detail",
                        style: GoogleFonts.poppins(
                          color: Colors.blue,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQRCodeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Tiket Penjemputan",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              // Nanti diganti library QR, sementara Icon dulu
              Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black),
                ),
                child: const Icon(Icons.qr_code_2, size: 150),
              ),
              const SizedBox(height: 20),
              Text(
                "Tunjukkan ke Guru",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}
