import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_html/flutter_html.dart';

class DetailRapotWaliPage extends StatelessWidget {
  final Map<String, dynamic> rapotData;

  const DetailRapotWaliPage({super.key, required this.rapotData});

  @override
  Widget build(BuildContext context) {
    final siswa = rapotData['siswa'] ?? {};
    final semester = rapotData['semester']?.toString() ?? '-';
    final tahunAjaran = rapotData['tahun_ajaran']?.toString() ?? '-';
    final namaGuru = rapotData['nama_guru'] ?? '-';
    final tanggalRapot = rapotData['tanggal_rapot'] ?? '-';

    // Nilai Kurikulum Merdeka (Mapping dari Model Rapot Admin)
    final narasiAgama = rapotData['narasi_agama'] ?? '-';
    final narasiBudiPekerti = rapotData['narasi_budi_pekerti'] ?? '-';
    final narasiJatiDiri = rapotData['narasi_jati_diri'] ?? '-';
    final narasiLiterasi = rapotData['narasi_literasi'] ?? '-';
    final narasiKokurikuler = rapotData['narasi_kokurikuler'] ?? '-';

    // Pertumbuhan & Kehadiran
    final tinggiBadan = rapotData['tinggi_badan']?.toString() ?? '0';
    final beratBadan = rapotData['berat_badan']?.toString() ?? '0';
    final lingkarKepala = rapotData['lingkar_kepala']?.toString() ?? '0';
    final sakit = rapotData['sakit']?.toString() ?? '0';
    final izin = rapotData['izin']?.toString() ?? '0';
    final alpha = rapotData['alpha']?.toString() ?? '0';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          "Detail Hasil Rapot",
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Laporan
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Laporan Capaian Pembelajaran",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Kurikulum Merdeka\nSemester $semester - $tahunAjaran\nTanggal: $tanggalRapot",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Identitas Siswa
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.purple.shade50,
                    child: const Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          siswa['nama_siswa'] ?? 'Nama Siswa',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "NIS: ${siswa['nis'] ?? '-'}",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SECTION 1: Capaian Pembelajaran
            _buildSectionTitle("Capaian Pembelajaran (Kurikulum Merdeka)"),
            _buildNarasiCard(
              "1. Nilai Agama & Kepercayaan",
              narasiAgama,
              Icons.favorite,
            ),
            _buildNarasiCard(
              "2. Nilai Budi Pekerti",
              narasiBudiPekerti,
              Icons.volunteer_activism,
            ),
            _buildNarasiCard(
              "3. Jati Diri",
              narasiJatiDiri,
              Icons.self_improvement,
            ),
            _buildNarasiCard(
              "4. Literasi & STEAM",
              narasiLiterasi,
              Icons.science,
            ),
            _buildNarasiCard(
              "5. Kokurikuler (P5)",
              narasiKokurikuler,
              Icons.groups,
            ),

            const SizedBox(height: 24),

            // SECTION 2: Pertumbuhan Anak
            _buildSectionTitle("Pertumbuhan Anak"),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      "Tinggi",
                      "$tinggiBadan cm",
                      Icons.height,
                      Colors.blue,
                    ),
                    _buildStatItem(
                      "Berat",
                      "$beratBadan kg",
                      Icons.monitor_weight,
                      Colors.orange,
                    ),
                    _buildStatItem(
                      "Kepala",
                      "$lingkarKepala cm",
                      Icons.face,
                      Colors.purple,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // SECTION 3: Kehadiran
            _buildSectionTitle("Kehadiran"),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      "Sakit",
                      "$sakit Hari",
                      Icons.local_hospital,
                      Colors.red,
                    ),
                    _buildStatItem(
                      "Izin",
                      "$izin Hari",
                      Icons.edit_document,
                      Colors.orange,
                    ),
                    _buildStatItem(
                      "Alpha",
                      "$alpha Hari",
                      Icons.cancel,
                      Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Penutup / Wali Kelas
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Wali Kelas:",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    namaGuru,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildNarasiCard(String title, String? narasi, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF8E2DE2), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A00E0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Html(
            data: narasi == null || narasi.trim().isEmpty ? '-' : narasi,
            style: {
              "body": Style(
                fontSize: FontSize(13.0),
                color: Colors.black87,
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                fontFamily: GoogleFonts.poppins().fontFamily,
                lineHeight: const LineHeight(1.4),
              ),
              "p": Style(margin: Margins.zero, padding: HtmlPaddings.zero),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
