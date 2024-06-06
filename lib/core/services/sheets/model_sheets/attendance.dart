class AttendanceFields {
  static final String id = 'id';
  static final String namaKaryawan = 'Nama_Karyawan';
  static final String sn = 'SN';
  static final String tanggal = 'Tanggal';
  static final String masuk = 'Masuk';
  static final String pulang = 'Pulang';
  static final String keteranganMasuk = 'Keterangan_Masuk';
  static final String keteranganPulang = 'Keterangan_Pulang';
  static final String email = 'email';

  static List<String> getFields() => [
        id,
        namaKaryawan,
        sn,
        tanggal,
        masuk,
        pulang,
        keteranganMasuk,
        keteranganPulang,
      ];
}

class AttendanceSheetsModel {
  final int? id;
  final String namaKaryawan;
  final String sn;
  final String tanggal;
  final String masuk;
  final String pulang;
  final String keteranganMasuk;
  final String keteranganPulang;

  AttendanceSheetsModel(
      {this.id,
      required this.namaKaryawan,
      required this.sn,
      required this.tanggal,
      required this.masuk,
      required this.pulang,
      required this.keteranganMasuk,
      required this.keteranganPulang});

  AttendanceSheetsModel copy({
    int? id,
    String? namaKaryawan,
    String? sn,
    String? tanggal,
    String? masuk,
    String? pulang,
    String? keteranganMasuk,
    String? keteranganPulang,
  }) =>
      AttendanceSheetsModel(
          id: id ?? this.id,
          namaKaryawan: namaKaryawan ?? this.namaKaryawan,
          sn: sn ?? this.sn,
          tanggal: tanggal ?? this.tanggal,
          masuk: masuk ?? this.masuk,
          pulang: pulang ?? this.pulang,
          keteranganMasuk: keteranganMasuk ?? this.keteranganMasuk,
          keteranganPulang: keteranganPulang ?? this.keteranganPulang);

  Map<String, dynamic> toJson() => {
        AttendanceFields.id: id,
        AttendanceFields.namaKaryawan: namaKaryawan,
        AttendanceFields.sn: sn,
        AttendanceFields.tanggal: tanggal,
        AttendanceFields.masuk: masuk,
        AttendanceFields.pulang: pulang,
        AttendanceFields.keteranganMasuk: keteranganMasuk,
        AttendanceFields.keteranganPulang: keteranganPulang,
      };
}
