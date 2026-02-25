import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ScanPenjemputanPage extends StatefulWidget {
  const ScanPenjemputanPage({super.key});

  @override
  State<ScanPenjemputanPage> createState() => _ScanPenjemputanPageState();
}

class _ScanPenjemputanPageState extends State<ScanPenjemputanPage> {
  // 1. Controller Tanpa Batasan Format (Biar lebih sensitif)
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    // formats: [BarcodeFormat.qrCode], // HAPUS INI (Saran Antigravity)
    returnImage: false,
    autoStart: true,
  );

  bool _isProcessing = false;

  // Area Scan (Kotak Tengah)
  Rect? scanWindow;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // --- FUNGSI DETEKSI ---
  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        String code = barcode.rawValue!;

        // Bersihkan data kalau ada prefix
        if (code.startsWith("SISWA-")) {
          code = code.replaceAll("SISWA-", "");
        }

        print("QR DITEMUKAN: $code");

        setState(() {
          _isProcessing = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Memproses ID: $code...",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(milliseconds: 500),
          ),
        );

        await _kirimDataPenjemputan(code);
        break;
      }
    }
  }

  // --- FUNGSI KIRIM KE API ---
  Future<void> _kirimDataPenjemputan(String siswaId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      // ⚠️ PASTIKAN IP LAPTOP BENAR
      final url = Uri.parse('http://192.168.18.36:8000/api/penjemputan');

      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'siswa_id': siswaId}),
          )
          .timeout(const Duration(seconds: 10));

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showResultDialog(
          "BERHASIL!",
          "Data penjemputan siswa ID $siswaId tersimpan.",
          true,
        );
      } else {
        final msg =
            jsonDecode(response.body)['message'] ?? "Gagal memproses data.";
        _showResultDialog("GAGAL", msg, false);
      }
    } catch (e) {
      print("Error Scan: $e");
      _showResultDialog("ERROR KONEKSI", "Gagal: $e", false);
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
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      setState(() {
                        _isProcessing = false;
                      });
                    }
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
    // Hitung area tengah layar untuk scanWindow
    final scanAreaSize = 250.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    scanWindow = Rect.fromCenter(
      center: Offset(screenWidth / 2, screenHeight / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

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
      body: Stack(
        children: [
          // 1. KAMERA DENGAN SCAN WINDOW
          MobileScanner(
            controller: controller,
            scanWindow: scanWindow, // HANYA SCAN DI TENGAH!
            onDetect: _onDetect,
          ),

          // 2. OVERLAY KOTAK (Hiasan)
          CustomPaint(painter: ScannerOverlay(scanWindow!)),

          // 3. TEKS PETUNJUK
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

          // 4. LOADING
          if (_isProcessing) const Center(child: CircularProgressIndicator()),
        ],
      ),

      // 5. TOMBOL SIMULASI (FITUR BARU ANTIGRAVITY!)
      // Gunakan tombol ini kalau kamera susah baca layar laptop
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Pura-pura kita menscan QR dengan isi "SISWA-1"
          _onDetect(
            BarcodeCapture(
              barcodes: [
                Barcode(rawValue: "SISWA-1", format: BarcodeFormat.qrCode),
              ],
            ),
          );
        },
        label: const Text("Simulasi Scan (Tes)"),
        icon: const Icon(Icons.touch_app),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

// Widget Hiasan Kotak Scan
class ScannerOverlay extends CustomPainter {
  final Rect scanWindow;
  ScannerOverlay(this.scanWindow);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath =
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()..addRect(scanWindow);

    final backgroundPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.5)
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.dstOut;

    final borderPaint =
        Paint()
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
