// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:objectbox/objectbox.dart';

@Entity()
class AttendanceEntity {
  int id = 0;
  String date;
  String masuk;
  String masukImage;
  String keluar;
  String keluarImage;
  AttendanceEntity({
    this.date = '',
    this.masuk = '',
    this.masukImage = '',
    this.keluar = '',
    this.keluarImage = '',
  });

  @override
  String toString() {
    return 'AttendanceEntity(id: $id, date: $date, masuk: $masuk, masukImage: $masukImage , keluar: $keluar, keluarImage: $keluarImage)';
  }
}
