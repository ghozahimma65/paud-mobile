import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class RiwayatPenilaianWaliPage extends StatefulWidget {
  final int siswaId;
  final String namaSiswa;
  final int
  initialTabIndex; // Menentukan tab mana yang buka pertama (0=Anekdot, 1=Ceklis, 2=Karya)

  const RiwayatPenilaianWaliPage({
    super.key,
    required this.siswaId,
    required this.namaSiswa,
    this.initialTabIndex = 0,
  });

  @override
  State<RiwayatPenilaianWaliPage> createState() =>
      _RiwayatPenilaianWaliPageState();
}

class _RiwayatPenilaianWaliPageState extends State<RiwayatPenilaianWaliPage> {
  // ApiService di hapus karena tidak digunakan lagi

  List<dynamic> _listAnekdot = [];
  List<dynamic> _listCeklis = [];
  List<dynamic> _listKarya = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRiwayatBerdasarkanAnak();
  }

  Future<void> _fetchRiwayatBerdasarkanAnak() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      print("=== SUPER DEBUG: MULAI FETCH RIWAYAT ===");
      // Pastikan URL-nya benar menggunakan siswaId
      final url = Uri.parse(
        'http://paud.ghozifadhim.web.id/api/wali/riwayat-anak/${widget.siswaId}',
      );
      print("TARGET URL: $url");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print("STATUS CODE: ${response.statusCode}");
      print("RESPONSE BODY: ${response.body}");
      print("=== SUPER DEBUG: SELESAI ===");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final dataMap = decoded['data'] ?? decoded;

        setState(() {
          _listAnekdot = dataMap['anekdot'] ?? [];
          _listCeklis = dataMap['ceklis'] ?? [];
          _listKarya = dataMap['karya'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        print("GAGAL FETCH DATA: Status bukan 200");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("ERROR CATCH: $e");
    }
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
    return DefaultTabController(
      initialIndex: widget.initialTabIndex,
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE), // Soft modern background
        appBar: AppBar(
          title: Text(
            "Riwayat: ${widget.namaSiswa}",
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
        body:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.purple),
                )
                : TabBarView(
                  children: [
                    _buildList(_listAnekdot, _buildCardAnekdot),
                    _buildList(_listCeklis, _buildCardCeklis),
                    _buildList(_listKarya, _buildCardKarya),
                  ],
                ),
      ),
    );
  }

  // WIDGET RENDER LIST UMUM
  Widget _buildList(List<dynamic> data, Widget Function(dynamic) cardBuilder) {
    if (data.isEmpty) {
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
      itemCount: data.length,
      itemBuilder: (context, index) {
        return cardBuilder(data[index]);
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
      content: [
        _buildContentRow(
          "Kejadian Teramati",
          item['kejadian_teramati'] ?? item['uraian_kejadian'],
        ),
        _buildContentRow("Catatan Guru", item['catatan_guru']),
        _buildContentRow("Analisis Capaian", item['analisis_capaian']),
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
      content: [
        _buildContentRow("Indikator Perkembangan", item['indikator']),
        _buildContentRow("Keterangan", item['keterangan']),
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
      content: [
        if (item['foto_url'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => _showFullScreenImage(context, item['foto_url']),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  item['foto_url'],
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ),
          ),
        _buildContentRow("Deskripsi Karya", item['deskripsi_foto']),
        _buildContentRow("Analisis Capaian", item['analisis_capaian']),
      ],
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.white,
                      ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // KOMPONEN BASE CARD MEWAH //
  Widget _buildBaseCard({
    required IconData titleIcon,
    required String titleText,
    required Color titleColor,
    required String tanggal,
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
                // Tidak ada lagi nama siswa per card, karena ini khusus 1 siswa
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
