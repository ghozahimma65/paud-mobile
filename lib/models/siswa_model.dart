class SiswaModel {
  int? id;
  String? namaSiswa;
  String? nis;
  String? namaKelas; // Untuk nampung 'Gatotkaca', dll
  String? namaWali;

  SiswaModel({this.id, this.namaSiswa, this.nis, this.namaKelas, this.namaWali});

  factory SiswaModel.fromJson(Map<String, dynamic> json) {
    return SiswaModel(
      id: json['id'],
      namaSiswa: json['nama_siswa'],
      nis: json['nis'],
      // Ambil data dari relasi 'kelompok' yang kita buat di Laravel kemarin
      namaKelas: json['kelompok'] != null ? json['kelompok']['nama_kelas'] : 'Tanpa Kelas',
      namaWali: json['wali_murid'] != null ? json['wali_murid']['nama_wali'] : '-',
    );
  }
}