import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/siswa_model.dart';

class InputKaryaPage extends StatefulWidget {
  final SiswaModel siswa;
  const InputKaryaPage({super.key, required this.siswa});

  @override
  State<InputKaryaPage> createState() => _InputKaryaPageState();
}

class _InputKaryaPageState extends State<InputKaryaPage> {
  File? _image;
  final _picker = ImagePicker();
  final _deskripsiController = TextEditingController();
  final _analisisController = TextEditingController();
  bool _isLoading = false;

  // Fungsi ambil gambar
  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _simpanKarya() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih foto hasil karya dulu!")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      // Karena ada upload file, kita pakai MultipartRequest
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.131.166.25:8000/api/guru/karya'), // GANTI IP
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['siswa_id'] = widget.siswa.id.toString();
      request.fields['tanggal'] = DateTime.now().toString().split(' ')[0];
      request.fields['deskripsi_foto'] = _deskripsiController.text;
      request.fields['analisis_capaian'] = _analisisController.text;

      request.files.add(
        await http.MultipartFile.fromPath('foto', _image!.path),
      );

      var response = await request.send();

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hasil Karya berhasil disimpan!")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Gagal upload karya")));
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Karya: ${widget.siswa.namaSiswa}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _showPicker(context),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    _image != null
                        ? Image.file(_image!, fit: BoxFit.cover)
                        : const Icon(
                          Icons.add_a_photo,
                          size: 50,
                          color: Colors.grey,
                        ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _deskripsiController,
              decoration: const InputDecoration(
                labelText: "Deskripsi Foto (Apa yang dibuat anak?)",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _analisisController,
              decoration: const InputDecoration(
                labelText: "Analisis Capaian",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _simpanKarya,
                    child: const Text("Simpan Karya"),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  void _showPicker(context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () {
                  _getImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Kamera'),
                onTap: () {
                  _getImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
