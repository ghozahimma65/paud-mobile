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
  List<Map<String, dynamic>> _flatZonasiList = [];
  String? _selectedZonaId;

  List<dynamic> _listSiswa = [];
  List<Map<String, dynamic>> _siswaTerpilih = []; 
  
  bool _isLoadingZonasi = true;
  bool _isLoadingSiswa = false;

  @override
  void initState() {
    super.initState();
    _fetchZonasi();
  }

  Future<void> _fetchZonasi() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final url = Uri.parse('http://192.168.18.36:8000/api/zonasi');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Map<String, dynamic> zonasiMap = data['data'];
        
        List<Map<String, dynamic>> flatList = [];
        zonasiMap.forEach((kategori, listZona) {
          // Header Kategori
          flatList.add({
            'id': 'HEADER_$kategori',
            'nama_zona': kategori,
            'kategori': kategori,
            'is_header': true,
            'display_text': '=== ${kategori.toString().toUpperCase()} ==='
          });

          for (var zona in listZona) {
            flatList.add({
              'id': zona['id'].toString(),
              'nama_zona': zona['nama_zona'],
              'kategori': kategori,
              'is_header': false,
              'display_text': '    ${zona['nama_zona']}' // Tambah indentasi agar rapi
            });
          }
        });

        setState(() {
          _flatZonasiList = flatList;
          _isLoadingZonasi = false;
        });
      } else {
        setState(() => _isLoadingZonasi = false);
      }
    } catch (e) {
      setState(() => _isLoadingZonasi = false);
    }
  }

  Future<void> _fetchSiswaByZona(String zonaId) async {
    setState(() {
      _isLoadingSiswa = true;
      _listSiswa = [];
      // Kosongkan siswa terpilih jika ganti zona (opsional, tapi disarankan)
      // _siswaTerpilih.clear();
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final url = Uri.parse('http://192.168.18.36:8000/api/home-visit/zona/$zonaId');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // Hanya ambil siswa yang koordinatnya valid
          _listSiswa = (data['data'] as List).where((s) => s['latitude'] != null && s['longitude'] != null && s['latitude'].toString() != '0' && s['longitude'].toString() != '0').toList();
          _isLoadingSiswa = false;
        });
      } else {
        setState(() => _isLoadingSiswa = false);
      }
    } catch (e) {
      setState(() => _isLoadingSiswa = false);
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
      body: Column(
        children: [
          // UI Bagian Atas: Dropdown Filter Zonasi
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            width: double.infinity,
            child: _isLoadingZonasi
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Pilih Zona Wilayah",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.map),
                    ),
                    value: _selectedZonaId,
                    isExpanded: true,
                    items: _flatZonasiList.map((zona) {
                      bool isHeader = zona['is_header'] ?? false;
                      return DropdownMenuItem<String>(
                        value: zona['id'],
                        enabled: !isHeader,
                        child: Text(
                          zona['display_text'], 
                          style: GoogleFonts.poppins(
                            fontSize: isHeader ? 13 : 14,
                            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                            color: isHeader ? Colors.blue.shade800 : Colors.black87,
                          )
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedZonaId = val);
                        _fetchSiswaByZona(val);
                      }
                    },
                  ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

          // UI Bagian Bawah: List View Card
          Expanded(
            child: _selectedZonaId == null
                ? Center(
                    child: Text(
                      "Silakan pilih zona wilayah terlebih dahulu",
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : _isLoadingSiswa
                    ? const Center(child: CircularProgressIndicator())
                    : _listSiswa.isEmpty
                        ? Center(
                            child: Text(
                              "Tidak ada data siswa di zona ini",
                              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _listSiswa.length,
                            itemBuilder: (context, index) {
                              final siswa = _listSiswa[index];
                              final indexTerpilih = _siswaTerpilih.indexWhere((s) => s['id'] == siswa['id']);
                              final isSelected = indexTerpilih != -1;

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  children: [
                                    CheckboxListTile(
                                      value: isSelected,
                                      onChanged: (val) => _togglePilihSiswa(siswa, val),
                                      title: Text(
                                        siswa['nama_siswa'] ?? 'Tanpa Nama',
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("Wali: ${siswa['wali_murid']?['nama_wali'] ?? '-'}", style: GoogleFonts.poppins(fontSize: 13)),
                                            const SizedBox(height: 2),
                                            Text("Alamat: ${siswa['wali_murid']?['alamat'] ?? '-'}", style: GoogleFonts.poppins(fontSize: 13)),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Text("HP: ${siswa['wali_murid']?['no_hp'] ?? '-'}", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                                                const SizedBox(width: 12),
                                                InkWell(
                                                  onTap: () {},
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
                                                    child: const Icon(Icons.chat, size: 16, color: Colors.green),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                InkWell(
                                                  onTap: () {},
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(color: Colors.blue.shade100, shape: BoxShape.circle),
                                                    child: const Icon(Icons.phone, size: 16, color: Colors.blue),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      activeColor: Colors.blue[700],
                                      controlAffinity: ListTileControlAffinity.leading,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                    
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                                          border: Border(top: BorderSide(color: Colors.grey.shade200))
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.timer, size: 18, color: Colors.orange),
                                                const SizedBox(width: 8),
                                                DropdownButton<int>(
                                                  value: _siswaTerpilih[indexTerpilih]['durasi_mengajar'],
                                                  isDense: true,
                                                  underline: const SizedBox(),
                                                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
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
                                              style: TextButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              icon: Icon(
                                                _siswaTerpilih[indexTerpilih]['is_priority'] ? Icons.star : Icons.star_border,
                                                color: _siswaTerpilih[indexTerpilih]['is_priority'] ? Colors.amber : Colors.grey,
                                                size: 20,
                                              ),
                                              label: Text(
                                                "Prioritas A*",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  color: _siswaTerpilih[indexTerpilih]['is_priority'] ? Colors.amber.shade700 : Colors.grey,
                                                  fontWeight: _siswaTerpilih[indexTerpilih]['is_priority'] ? FontWeight.bold : FontWeight.normal
                                                ),
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