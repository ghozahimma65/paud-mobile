import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class RiwayatPenilaianPage extends StatefulWidget {
  const RiwayatPenilaianPage({super.key});

  @override
  State<RiwayatPenilaianPage> createState() => _RiwayatPenilaianPageState();
}

class _RiwayatPenilaianPageState extends State<RiwayatPenilaianPage> {
  List<dynamic> _listAnekdot = [];
  List<dynamic> _listCeklis = [];
  List<dynamic> _listKarya = [];
  bool _isLoading = true;
  String? _selectedSiswa; // Untuk filter nama anak

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final responses = await Future.wait([
        http.get(
          Uri.parse('http://192.168.18.36:8000/api/guru/anekdot'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
        http.get(
          Uri.parse('http://192.168.18.36:8000/api/guru/ceklis'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
        http.get(
          Uri.parse('http://192.168.18.36:8000/api/guru/karya'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      ]);

      setState(() {
        if (responses[0].statusCode == 200)
          _listAnekdot = jsonDecode(responses[0].body)['data'] ?? [];
        if (responses[1].statusCode == 200)
          _listCeklis = jsonDecode(responses[1].body)['data'] ?? [];
        if (responses[2].statusCode == 200)
          _listKarya = jsonDecode(responses[2].body)['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      print("Error Fetching All Penilaian: $e");
      setState(() => _isLoading = false);
    }
  }

  List<String> _getUniqueStudents() {
    Set<String> students = {};
    for (var list in [_listAnekdot, _listCeklis, _listKarya]) {
      for (var item in list) {
        if (item['siswa'] != null && item['siswa']['nama_siswa'] != null) {
          students.add(item['siswa']['nama_siswa']);
        }
      }
    }
    return students.toList()..sort();
  }

  String formatTgl(String? tgl) {
    if (tgl == null) return "-";
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(tgl));
    } catch (e) {
      return tgl;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> studentList = _getUniqueStudents();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE), // Soft modern background
        appBar: AppBar(
          title: Text(
            "Riwayat Penilaian",
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
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: "Anekdot"),
              Tab(text: "Ceklis"),
              Tab(text: "Hasil Karya"),
            ],
          ),
        ),
        body: Column(
          children: [
            // BAR FILTER SISWA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  hintText: "Pilih Siswa (Semua)",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  prefixIcon: const Icon(
                    Icons.filter_list,
                    color: Colors.purple,
                  ),
                ),
                value: _selectedSiswa,
                icon: const Icon(
                  Icons.arrow_drop_down_circle,
                  color: Colors.purple,
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(
                      "Semua Siswa",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                  ...studentList.map(
                    (st) => DropdownMenuItem(
                      value: st,
                      child: Text(
                        st,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedSiswa = val;
                  });
                },
              ),
            ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                        children: [
                          _buildList(_listAnekdot, _buildCardAnekdot),
                          _buildList(_listCeklis, _buildCardCeklis),
                          _buildList(_listKarya, _buildCardKarya),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET RENDER LIST UMUM DENGAN FILTER //
  Widget _buildList(List<dynamic> data, Widget Function(dynamic) cardBuilder) {
    List<dynamic> filteredData = data;
    if (_selectedSiswa != null) {
      filteredData =
          data
              .where(
                (item) =>
                    item['siswa'] != null &&
                    item['siswa']['nama_siswa'] == _selectedSiswa,
              )
              .toList();
    }

    if (filteredData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(
              "Tidak ada riwayat ditemukan",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredData.length,
      itemBuilder: (context, index) {
        return cardBuilder(filteredData[index]);
      },
    );
  }

  // BUILDER CARD ANEKDOT (MEWAH)
  Widget _buildCardAnekdot(dynamic item) {
    bool isHomeVisit =
        item['kategori'] == "Home Visit" ||
        item['tempat'] == "Rumah Siswa (Home Visit)";
    return _buildBaseCard(
      titleIcon: isHomeVisit ? Icons.home : Icons.school,
      titleText: isHomeVisit ? "Home Visit" : "Di Sekolah",
      titleColor: isHomeVisit ? Colors.orange : Colors.blue,
      tanggal: formatTgl(item['tanggal']),
      namaSiswa: item['siswa']?['nama_siswa'],
      content: [
        _buildContentRow(
          "Kejadian Teramati",
          item['kejadian_teramati'] ?? item['uraian_kejadian'],
        ),
        _buildContentRow("Catatan Guru", item['catatan_guru'] ?? "-"),
        _buildContentRow("Analisis Capaian", item['analisis_capaian'] ?? "-"),
      ],
    );
  }

  // BUILDER CARD CEKLIS (MEWAH)
  Widget _buildCardCeklis(dynamic item) {
    Color hasilColor;
    switch (item['hasil']) {
      case 'BSB':
        hasilColor = Colors.green;
        break;
      case 'BSH':
        hasilColor = Colors.blue;
        break;
      case 'MB':
        hasilColor = Colors.orange;
        break;
      case 'BB':
        hasilColor = Colors.red;
        break;
      default:
        hasilColor = Colors.grey;
    }

    return _buildBaseCard(
      titleIcon: Icons.checklist_rtl,
      titleText: "Skala: ${item['hasil'] ?? '-'}",
      titleColor: hasilColor,
      tanggal: formatTgl(item['tanggal']),
      namaSiswa: item['siswa']?['nama_siswa'],
      content: [
        _buildContentRow("Indikator Perkembangan", item['indikator']),
        _buildContentRow("Keterangan", item['keterangan'] ?? "-"),
      ],
    );
  }

  // BUILDER CARD HASIL KARYA (MEWAH)
  Widget _buildCardKarya(dynamic item) {
    return _buildBaseCard(
      titleIcon: Icons.brush,
      titleText: "Hasil Karya Anak",
      titleColor: Colors.purple,
      tanggal: formatTgl(item['tanggal']),
      namaSiswa: item['siswa']?['nama_siswa'],
      content: [
        if (item['foto_url'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item['foto_url'],
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const SizedBox(),
              ),
            ),
          ),
        _buildContentRow("Deskripsi Karya", item['deskripsi_foto'] ?? "-"),
        _buildContentRow("Analisis Capaian", item['analisis_capaian'] ?? "-"),
      ],
    );
  }

  // KOMPONEN BASE CARD MEWAH //
  Widget _buildBaseCard({
    required IconData titleIcon,
    required String titleText,
    required Color titleColor,
    required String tanggal,
    required String? namaSiswa,
    required List<Widget> content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER CARD
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: titleColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(titleIcon, size: 18, color: titleColor),
                    const SizedBox(width: 8),
                    Text(
                      titleText,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  tanggal,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.purple.shade50,
                      child: const Icon(
                        Icons.face,
                        size: 20,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        namaSiswa ?? "Nama Siswa Tidak Diketahui",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, thickness: 1),
                ),
                ...content,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET TEXT CONTENT //
  Widget _buildContentRow(String label, String? value) {
    if (value == null || value.isEmpty || value == "-") return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
