import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';

// --- IMPORT FILE PENTING ---
import 'input_anekdot_page.dart';
import '../models/siswa_model.dart'; 

class PetaKunjunganPage extends StatefulWidget {
  final List<Map<String, dynamic>> siswaTerpilih;

  const PetaKunjunganPage({super.key, required this.siswaTerpilih});

  @override
  State<PetaKunjunganPage> createState() => _PetaKunjunganPageState();
}

class _PetaKunjunganPageState extends State<PetaKunjunganPage> {
  bool _isMencariRute = true;
  List<LatLng> _titikRuteAStar = [];
  
  double _jarakTotalMeter = 0;
  int _waktuTempuhJalanMenit = 0;
  int _totalDurasiMengajarMenit = 0;
  
  List<Map<String, dynamic>> _urutanOptimal = [];

  final LatLng _pusatPeta = const LatLng(-7.628337, 111.525506); // PAUD
  final String apiKey = "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjJiMjFjZTc1YTRlYTQzOWE4NTlkMDIzYTEwZDk1MTk0IiwiaCI6Im11cm11cjY0In0="; 

  @override
  void initState() {
    super.initState();
    _urutanOptimal = List.from(widget.siswaTerpilih);
    _kalkulasiRuteAStar();
  }

  void _kalkulasiRuteAStar() async {
    setState(() => _isMencariRute = true);
    
    List<Map<String, dynamic>> antrean = _urutanOptimal.where((s) => s['status_kunjungan'] == 'menunggu').toList();
    List<Map<String, dynamic>> hasilUrutan = [];
    
    LatLng titikAwal = _pusatPeta;
    
    var yangSelesai = _urutanOptimal.where((s) => s['status_kunjungan'] == 'selesai').toList();
    if (yangSelesai.isNotEmpty) {
      titikAwal = LatLng(double.parse(yangSelesai.last['latitude'].toString()), double.parse(yangSelesai.last['longitude'].toString()));
    }

    int totalMengajar = 0;

    while (antrean.isNotEmpty) {
      Map<String, dynamic>? anakTerpilih;
      double jarakMin = double.infinity;

      for (var anak in antrean) {
        if (anak['latitude'] == null || anak['longitude'] == null) continue;

        double latAnak = double.parse(anak['latitude'].toString());
        double lngAnak = double.parse(anak['longitude'].toString());
        
        double jarak = math.sqrt(math.pow(latAnak - titikAwal.latitude, 2) + math.pow(lngAnak - titikAwal.longitude, 2));
        
        if (anak['is_priority'] == true) jarak -= 999999; 
        
        if (jarak < jarakMin) {
          jarakMin = jarak;
          anakTerpilih = anak;
        }
      }

      if (anakTerpilih != null) {
        hasilUrutan.add(anakTerpilih);
        antrean.remove(anakTerpilih);
        totalMengajar += anakTerpilih['durasi_mengajar'] as int;
        titikAwal = LatLng(double.parse(anakTerpilih['latitude'].toString()), double.parse(anakTerpilih['longitude'].toString()));
      } else {
        break; 
      }
    }

    var yangBatal = _urutanOptimal.where((s) => s['status_kunjungan'] == 'batal').toList();
    _urutanOptimal = [...yangSelesai, ...hasilUrutan, ...yangBatal];
    _totalDurasiMengajarMenit = totalMengajar;

    List<List<double>> koordinatORS = [];
    koordinatORS.add([_pusatPeta.longitude, _pusatPeta.latitude]); 

    for (var anak in _urutanOptimal.where((s) => s['status_kunjungan'] != 'batal')) {
       if (anak['latitude'] != null && anak['longitude'] != null) {
          koordinatORS.add([double.parse(anak['longitude'].toString()), double.parse(anak['latitude'].toString())]);
       }
    }

    if (koordinatORS.length < 2) {
       setState(() {
        _isMencariRute = false;
        _jarakTotalMeter = 0;
        _waktuTempuhJalanMenit = 0;
       });
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada tujuan kunjungan yang valid.')));
       return;
    }

    try {
      final url = Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car/geojson');
      final response = await http.post(
        url,
        headers: {
          'Authorization': apiKey, 
          'Content-Type': 'application/json; charset=utf-8', 
          'Accept': 'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8'
        },
        body: jsonEncode({"coordinates": koordinatORS}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> coords = data['features'][0]['geometry']['coordinates'];
        
        setState(() {
          _titikRuteAStar = coords.map((c) => LatLng(c[1], c[0])).toList();
          _jarakTotalMeter = data['features'][0]['properties']['summary']['distance'];
          _waktuTempuhJalanMenit = (data['features'][0]['properties']['summary']['duration'] / 60).round();
          _isMencariRute = false;
        });
      } else {
        throw Exception("Gagal menarik rute. Cek konsol debug.");
      }
    } catch (e) {
      setState(() => _isMencariRute = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error peta: ${e.toString()}')));
    }
  }

  void _tandaiSelesai(int id) {
    setState(() {
      final index = _urutanOptimal.indexWhere((s) => s['id'] == id);
      if (index != -1) _urutanOptimal[index]['status_kunjungan'] = 'selesai';
    });
  }

  // --- CEK JIKA SEMUA SUDAH SELESAI ---
  void _cekSemuaSelesai() {
    bool semuaTuntas = _urutanOptimal.every((s) => s['status_kunjungan'] == 'selesai' || s['status_kunjungan'] == 'batal');

    if (semuaTuntas) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Column(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 60),
              SizedBox(height: 10),
              Text("Tugas Selesai! 🏆", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text("Seluruh jadwal Home Visit hari ini telah dinilai.\n\nTotal Jarak: ${(_jarakTotalMeter / 1000).toStringAsFixed(2)} KM", textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
              onPressed: () {
                // Menutup Pop-Up, lalu Pop peta, lalu kembali ke menu utama
                Navigator.pop(context); 
                Navigator.pop(context); 
              },
              child: const Text("Kembali ke Dashboard", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  void _batalkanKunjungan(int id) {
    setState(() {
      final index = _urutanOptimal.indexWhere((s) => s['id'] == id);
      if (index != -1) {
        _urutanOptimal[index]['status_kunjungan'] = 'batal';
        _urutanOptimal[index]['is_priority'] = false; 
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kunjungan Dibatalkan. Mengkalkulasi ulang rute...')));
    _kalkulasiRuteAStar(); 
    _cekSemuaSelesai(); // Jaga-jaga kalau yang dibatalkan itu adalah anak terakhir
  }

  Future<void> _bukaNavigasi(double lat, double lng) async {
    final Uri url = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$lat,$lng");
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    int totalEstimasiKerja = _waktuTempuhJalanMenit + _totalDurasiMengajarMenit;

    return Scaffold(
      appBar: AppBar(title: Text("Navigasi Pintar A*", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 1),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _pusatPeta,
              initialZoom: 14.0,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
            ),
            children: [
              TileLayer(urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}', userAgentPackageName: 'com.skripsi.paudmadiun'),
              if (_titikRuteAStar.isNotEmpty) PolylineLayer(polylines: [Polyline(points: _titikRuteAStar, strokeWidth: 5.0, color: Colors.blueAccent)]),
              MarkerLayer(
                markers: [
                  Marker(point: _pusatPeta, width: 80, height: 80, child: const Icon(Icons.school, color: Colors.blue, size: 40)),
                  ..._urutanOptimal.where((s) => s['status_kunjungan'] != 'batal').toList().asMap().entries.map((entry) {
                    var siswa = entry.value;
                    bool isSelesai = siswa['status_kunjungan'] == 'selesai';
                    
                    if(siswa['latitude'] == null || siswa['longitude'] == null) return const Marker(point: LatLng(0,0), child: SizedBox());

                    return Marker(
                      point: LatLng(double.parse(siswa['latitude'].toString()), double.parse(siswa['longitude'].toString())),
                      width: 80, height: 80,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: isSelesai ? Colors.green : Colors.red[700], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white, width: 2)),
                            child: Text(isSelesai ? "✓" : "${entry.key + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          Icon(Icons.location_on, color: isSelesai ? Colors.green : Colors.red, size: 40),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          if (!_isMencariRute)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(children: [Text("Total Jarak", style: TextStyle(color: Colors.grey[600], fontSize: 10)), Text("${(_jarakTotalMeter / 1000).toStringAsFixed(2)} KM", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue[800]))]),
                        Column(children: [Text("Waktu Jalan", style: TextStyle(color: Colors.grey[600], fontSize: 10)), Text("$_waktuTempuhJalanMenit Menit", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.orange[800]))]),
                        Column(children: [Text("Total Waktu Kerja", style: TextStyle(color: Colors.grey[600], fontSize: 10)), Text("$totalEstimasiKerja Menit", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.green[800]))]),
                      ],
                    ),
                    const Divider(height: 20),
                    
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        itemCount: _urutanOptimal.length,
                        itemBuilder: (context, index) {
                          final siswa = _urutanOptimal[index];
                          bool isSelesai = siswa['status_kunjungan'] == 'selesai';
                          bool isBatal = siswa['status_kunjungan'] == 'batal';
                          bool adaKoordinat = siswa['latitude'] != null && siswa['longitude'] != null;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: isSelesai ? Colors.green[100] : (isBatal ? Colors.grey[200] : Colors.red[100]),
                              child: isSelesai ? const Icon(Icons.check, color: Colors.green) : (isBatal ? const Icon(Icons.close, color: Colors.grey) : Text("${index + 1}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                            ),
                            title: Text(
                              siswa['nama_siswa'],
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, decoration: (isSelesai || isBatal) ? TextDecoration.lineThrough : null, color: (isSelesai || isBatal) ? Colors.grey : Colors.black),
                            ),
                            subtitle: Text(isBatal ? "Kunjungan Dibatalkan" : "Durasi Mengajar: ${siswa['durasi_mengajar']} Menit", style: const TextStyle(fontSize: 12)),
                            trailing: (isSelesai || isBatal) ? null : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if(adaKoordinat) IconButton(icon: const Icon(Icons.navigation, color: Colors.blue), onPressed: () => _bukaNavigasi(double.parse(siswa['latitude'].toString()), double.parse(siswa['longitude'].toString()))),
                                
                                // --- TOMBOL MENUJU FORM ANEKDOT ---
                                IconButton(
                                  icon: const Icon(Icons.edit_document, color: Colors.orange), 
                                  onPressed: () async {
                                    // Konversi data JSON Map ke SiswaModel menggunakan fromJson
                                    SiswaModel modelSiswa;
                                    try {
                                      modelSiswa = SiswaModel.fromJson(siswa);
                                    } catch(e) {
                                      // Fallback jika fromJson kamu agak beda
                                      modelSiswa = SiswaModel(id: siswa['id'], namaSiswa: siswa['nama_siswa']);
                                    }

                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => InputAnekdotPage(
                                          siswa: modelSiswa,
                                          kategori: "Home Visit", // Mengirim sinyal Home Visit
                                        )
                                      ),
                                    );

                                    // Jika berhasil disave dan kembali ke sini
                                    if (result == true) {
                                      _tandaiSelesai(siswa['id']);
                                      _cekSemuaSelesai();
                                    }
                                  }
                                ),

                                IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _batalkanKunjungan(siswa['id'])),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
          if (_isMencariRute)
            Container(color: Colors.black54, child: const Center(child: Card(child: Padding(padding: EdgeInsets.all(20.0), child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 10), Text("A* Sedang Menghitung Rute...")]))))),
        ],
      ),
    );
  }
}