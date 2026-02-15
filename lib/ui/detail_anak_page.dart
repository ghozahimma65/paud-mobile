import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/siswa_model.dart';

class DetailAnakPage extends StatelessWidget {
  final SiswaModel siswa;

  const DetailAnakPage({super.key, required this.siswa});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          siswa.namaSiswa ?? "Detail Anak",
          style: GoogleFonts.poppins(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // FOTO PROFIL BESAR
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      siswa.namaSiswa != null ? siswa.namaSiswa![0] : "-",
                      style: GoogleFonts.poppins(
                        fontSize: 40,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    siswa.namaSiswa ?? "-",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "NIS: ${siswa.nis} | Kelas: ${siswa.namaKelas}",
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // MENU PILIHAN LAPORAN
            _buildMenuItem(
              context,
              "Laporan Anekdot",
              Icons.book,
              Colors.orange,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Membuka Laporan Anekdot...")),
                );
              },
            ),
            _buildMenuItem(
              context,
              "Hasil Karya",
              Icons.palette,
              Colors.purple,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Membuka Hasil Karya...")),
                );
              },
            ),
            _buildMenuItem(
              context,
              "Ceklis Perkembangan",
              Icons.check_circle,
              Colors.blue,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Membuka Ceklis...")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
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
