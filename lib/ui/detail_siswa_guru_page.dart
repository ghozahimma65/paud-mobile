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
      appBar: AppBar(title: Text("Profil Siswa", style: GoogleFonts.poppins())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header Profil
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      siswa.namaSiswa![0],
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    siswa.namaSiswa ?? "-",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "NIS: ${siswa.nis}",
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Menu Aksi Guru
            _buildMenuGuru(
              context,
              "Input Catatan Anekdot",
              Icons.edit_note,
              Colors.orange,
            ),
            _buildMenuGuru(
              context,
              "Input Hasil Karya",
              Icons.art_track,
              Colors.purple,
            ),
            _buildMenuGuru(
              context,
              "Input Ceklis Perkembangan",
              Icons.check_box,
              Colors.blue,
            ),

            _buildMenuGuru(
              context,
              "Riwayat Penjemputan",
              Icons.history,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGuru(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (title == "Input Catatan Anekdot") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InputAnekdotPage(siswa: siswa),
              ),
            );
          } else if (title == "Input Hasil Karya") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InputKaryaPage(siswa: siswa),
              ),
            );
          } else if (title == "Input Ceklis Perkembangan") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InputCeklisPage(siswa: siswa),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Fitur $title segera hadir!")),
            );
          }
        },
      ),
    );
  }
}
