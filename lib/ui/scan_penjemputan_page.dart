import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_services/api_service.dart';
import '../models/siswa_model.dart';

class ScanPenjemputanPage extends StatefulWidget {
  const ScanPenjemputanPage({super.key});

  @override
  State<ScanPenjemputanPage> createState() => _ScanPenjemputanPageState();
}

class _ScanPenjemputanPageState extends State<ScanPenjemputanPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    returnImage: false,
    autoStart: true,
  );

  bool _isProcessing = false;
  List<SiswaModel> _anakBelumDijemput = [];
  bool _isLoadingSiswa = true;

  @override
  void initState() {
    super.initState();
    _fetchSiswaData();
  }

  Future<void> _fetchSiswaData() async {
    try {
      final listSiswa = await ApiService().getSiswa();
      if (!mounted) return;
      setState(() {
        _anakBelumDijemput = listSiswa;
        _isLoadingSiswa = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSiswa = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data anak.')),
        );
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        String code = barcode.rawValue!;

        if (code.startsWith("SISWA-")) {
          code = code.replaceAll("SISWA-", "");
        }

        setState(() {
          _isProcessing = true;
        });

        try {
          // Cari data anak dari list
          final siswa = _anakBelumDijemput.firstWhere(
            (s) => s.id.toString() == code,
          );
          
          // Tampilkan Modal Konfirmasi
          _tampilkanDialogKonfirmasi(siswa);
        } catch (e) {
          // Jika tidak ketemu
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "QR Ditolak: Anak sudah dijemput sebelumnya atau ID tidak terdaftar!",
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _isProcessing = false);
          });
        }
        break; // Hanya deteksi barcode pertama
      }
    }
  }

  void _tampilkanDialogKonfirmasi(SiswaModel siswa) {
    String opsiPenjemput = 'Orang Tua';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text(
                "Konfirmasi Jemput",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Nama Anak:", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  Text(siswa.namaSiswa ?? "-", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Text("Status Penjemputan:", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 5),
                  DropdownButtonFormField<String>(
                    value: opsiPenjemput,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: ['Orang Tua', 'Diwakilkan'].map((String val) {
                      return DropdownMenuItem(value: val, child: Text(val, style: GoogleFonts.poppins()));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          opsiPenjemput = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Tutup dialog
                    setState(() {
                      _isProcessing = false;
                    });
                  },
                  child: Text("Batal", style: GoogleFonts.poppins(color: Colors.red)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    Navigator.pop(context);
                    _kirimDataPenjemputan(siswa.id.toString(), opsiPenjemput);
                  },
                  child: Text("Konfirmasi Jemput", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _kirimDataPenjemputan(String siswaId, String opsiPenjemput) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    setState(() => _isProcessing = true);

    try {
      final url = Uri.parse('http://192.168.18.36:8000/api/guru/scan-jemput');

      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'qr_code': siswaId,
              'status_penjemput': opsiPenjemput,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Notifikasi Sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Anak berhasil dijemput!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green,
          ),
        );
        // Hapus data anak dari list state UI
        setState(() {
          _anakBelumDijemput.removeWhere((s) => s.id.toString() == siswaId);
          _isProcessing = false;
        });
      } else {
        final msg = jsonDecode(response.body)['message'] ?? "Gagal memproses data.";
        _showResultDialog("GAGAL", msg, false);
      }
    } catch (e) {
      _showResultDialog("ERROR", "Koneksi gagal: $e", false);
    }
  }

  void _showResultDialog(String title, String message, bool isSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: isSuccess ? Colors.green : Colors.red,
              ),
            ),
            content: Text(message, style: GoogleFonts.poppins()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _isProcessing = false;
                  });
                },
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Scan Penjemputan",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scanWindow = Rect.fromCenter(
            center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
            width: 250,
            height: 250,
          );

          return Stack(
            children: [
              MobileScanner(
                controller: controller,
                scanWindow: scanWindow,
                onDetect: _onDetect,
              ),
              CustomPaint(painter: ScannerOverlay(scanWindow)),
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Text(
                  _isProcessing ? "Memproses..." : "Arahkan QR ke dalam kotak",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_isProcessing)
                const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      ),
    );
  }
}

class ScannerOverlay extends CustomPainter {
  final Rect scanWindow;
  ScannerOverlay(this.scanWindow);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()..addRect(scanWindow);

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawPath(
      Path.combine(PathOperation.difference, backgroundPath, cutoutPath),
      backgroundPaint,
    );

    canvas.drawRect(scanWindow, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
