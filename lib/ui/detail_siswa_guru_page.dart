import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/siswa_model.dart';
import 'input_anekdot_page.dart';
import 'input_karya_page.dart';
import 'input_ceklis_page.dart';

class DetailSiswaGuruPage extends StatelessWidget {
  final SiswaModel siswa;

  const DetailSiswaGuruPage({super.key, required this.siswa});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          "Profil Siswa",
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          children: [
            // --- HEADER PROFIL PREMUIM ---
            Container(
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
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        siswa.namaSiswa != null
                            ? siswa.namaSiswa![0].toUpperCase()
                            : "S",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    siswa.namaSiswa ?? "-",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "NIS: ${siswa.nis}",
                      style: GoogleFonts.poppins(
                        color: Colors.purple.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(thickness: 1, height: 1),
                  ),
                  _buildInfoRow(
                    Icons.family_restroom,
                    "Orang Tua/Wali",
                    siswa.namaWali ?? "-",
                  ),
                  const SizedBox(height: 15),
                  _buildInfoRow(
                    Icons.location_on,
                    "Alamat",
                    siswa.alamat ?? "-",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 35),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Menu Aksi Guru",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 15),

            // --- MENU AKSI GURU ---
            _buildMenuGuru(
              context: context,
              title: "Input Catatan Anekdot",
              subtitle: "Tambah observasi perilaku anak",
              icon: Icons.edit_note,
              color: Colors.orange,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InputAnekdotPage(siswa: siswa),
                    ),
                  ),
            ),
            _buildMenuGuru(
              context: context,
              title: "Input Hasil Karya",
              subtitle: "Upload foto & analisis karya anak",
              icon: Icons.art_track,
              color: Colors.pink,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InputKaryaPage(siswa: siswa),
                    ),
                  ),
            ),
            _buildMenuGuru(
              context: context,
              title: "Input Ceklis Perkembangan",
              subtitle: "Evaluasi indikator skala PAUD",
              icon: Icons.check_box,
              color: Colors.blue,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InputCeklisPage(siswa: siswa),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET INFO ROW PROFIL
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // WIDGET TOMBOL MENU MEWAH
  Widget _buildMenuGuru({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color.shade600, size: 28),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: color.shade300),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
