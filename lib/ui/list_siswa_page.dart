import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paud_mobile/ui/detail_siswa_guru_page.dart';
import '../models/siswa_model.dart';
import '../services/api_services/api_service.dart';
import 'detail_siswa_guru_page.dart';

class ListSiswaPage extends StatefulWidget {
  const ListSiswaPage({super.key});

  @override
  State<ListSiswaPage> createState() => _ListSiswaPageState();
}

class _ListSiswaPageState extends State<ListSiswaPage> {
  final ApiService _apiService = ApiService();
  late Future<List<SiswaModel>> _siswaList;

  @override
  void initState() {
    super.initState();
    _siswaList = _apiService.getSiswa(); // Ambil data dari Laravel
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Daftar Siswa",
          style: GoogleFonts.poppins(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<SiswaModel>>(
        future: _siswaList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada data siswa."));
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                SiswaModel siswa = snapshot.data![index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      radius: 25,
                      child: Text(
                        siswa.namaSiswa != null ? siswa.namaSiswa![0] : "-",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      siswa.namaSiswa ?? "-",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Kelas: ${siswa.namaKelas} | NIS: ${siswa.nis}",
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      // Navigasi ke Detail Siswa Guru
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => DetailSiswaGuruPage(siswa: siswa),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
