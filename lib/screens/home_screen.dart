import 'package:flutter/material.dart';
import '../models/siswa_model.dart'; // Pastikan path ini benar
import '../services/api_services/api_service.dart'; // Pastikan path ini benar

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Siswa"),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<SiswaModel>>(
        future: _apiService.getSiswa(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada data siswa"));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var siswa = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: Text(siswa.namaSiswa?[0] ?? "-"),
                    ),
                    title: Text(siswa.namaSiswa ?? "Tanpa Nama"),
                    subtitle: Text(
                      "Kelas: ${siswa.namaKelas} | Wali: ${siswa.namaWali}",
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
