import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'peta_kunjungan_page.dart';

class RencanaKunjunganPage extends StatefulWidget {
  const RencanaKunjunganPage({super.key});

  @override
  State<RencanaKunjunganPage> createState() => _RencanaKunjunganPageState();
}

class _RencanaKunjunganPageState extends State<RencanaKunjunganPage> {
  List<dynamic> _listSiswa = [];
  
  List<Map<String, dynamic>> _siswaTerpilih = []; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDataSiswa();
  }

  Future<void> _fetchDataSiswa() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      // PASTIKAN IP INI SESUAI DENGAN LAPTOPMU
      final url = Uri.parse('http://192.168.18.36:8000/api/siswa-saya');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // Hanya ambil siswa yang koordinatnya LENGKAP
          _listSiswa = data['data'].where((s) => s['latitude'] != null && s['longitude'] != null && s['latitude'].toString() != '0' && s['longitude'].toString() != '0').toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _togglePilihSiswa(dynamic siswa, bool? value) {
    setState(() {
      if (value == true) {
        if (_siswaTerpilih.length >= 5) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maksimal 5 anak per hari ya!')));
          return;
        }
        _siswaTerpilih.add({
          ...siswa,
          'durasi_mengajar': 30, 
          'is_priority': false, 
          'status_kunjungan': 'menunggu' 
        });
      } else {
        _siswaTerpilih.removeWhere((s) => s['id'] == siswa['id']);
      }
    });
  }

  void _ubahDurasi(int id, int durasiBaru) {
    setState(() {
      final index = _siswaTerpilih.indexWhere((s) => s['id'] == id);
      if (index != -1) _siswaTerpilih[index]['durasi_mengajar'] = durasiBaru;
    });
  }

  void _togglePrioritas(int id) {
    setState(() {
      final index = _siswaTerpilih.indexWhere((s) => s['id'] == id);
      if (index != -1) {
        _siswaTerpilih[index]['is_priority'] = !_siswaTerpilih[index]['is_priority'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Rencana Home Visit", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      const Icon(Icons.psychology, color: Colors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text("Sistem A* akan mengkalkulasi rute + total waktu mengajar. Beri tanda ⭐ jika anak harus dikunjungi pertama!", style: GoogleFonts.poppins(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _listSiswa.length,
                    itemBuilder: (context, index) {
                      final siswa = _listSiswa[index];
                      final indexTerpilih = _siswaTerpilih.indexWhere((s) => s['id'] == siswa['id']);
                      final isSelected = indexTerpilih != -1;

                      // Cek apakah alamat ada isinya
                      bool adaAlamat = siswa['alamat'] != null && siswa['alamat'].toString().isNotEmpty;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: Column(
                          children: [
                            CheckboxListTile(
                              value: isSelected,
                              onChanged: (val) => _togglePilihSiswa(siswa, val),
                              title: Text(siswa['nama_siswa'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                              // PERBAIKAN 1: Kalau tidak ada alamat, subtitle diset null (hilang)
                              subtitle: adaAlamat ? Text(siswa['alamat'], maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                              activeColor: Colors.blue[700],
                            ),
                            
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10))),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.timer, size: 16, color: Colors.orange),
                                        const SizedBox(width: 8),
                                        DropdownButton<int>(
                                          value: _siswaTerpilih[indexTerpilih]['durasi_mengajar'],
                                          isDense: true,
                                          items: const [
                                            DropdownMenuItem(value: 15, child: Text("15 Menit")),
                                            DropdownMenuItem(value: 30, child: Text("30 Menit")),
                                            DropdownMenuItem(value: 45, child: Text("45 Menit")),
                                            DropdownMenuItem(value: 60, child: Text("60 Menit")),
                                          ],
                                          onChanged: (val) => _ubahDurasi(siswa['id'], val!),
                                        ),
                                      ],
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _togglePrioritas(siswa['id']),
                                      icon: Icon(
                                        _siswaTerpilih[indexTerpilih]['is_priority'] ? Icons.star : Icons.star_border,
                                        color: _siswaTerpilih[indexTerpilih]['is_priority'] ? Colors.amber : Colors.grey,
                                      ),
                                      label: Text(
                                        "Prioritas A*",
                                        style: TextStyle(color: _siswaTerpilih[indexTerpilih]['is_priority'] ? Colors.amber.shade700 : Colors.grey),
                                      ),
                                    )
                                  ],
                                ),
                              )
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: _siswaTerpilih.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => PetaKunjunganPage(siswaTerpilih: _siswaTerpilih)));
              },
              backgroundColor: Colors.blue[700],
              icon: const Icon(Icons.auto_graph, color: Colors.white),
              label: Text("Kalkulasi Rute Cerdas", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
    );
  }
}