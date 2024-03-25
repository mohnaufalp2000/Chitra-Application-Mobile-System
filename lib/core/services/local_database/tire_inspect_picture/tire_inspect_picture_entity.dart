// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:objectbox/objectbox.dart';

@Entity()
class TireInspectPictureEntity {
  int id = 0;
  String idImage;
  String image;
  TireInspectPictureEntity({
    this.idImage = '',
    this.image = '',
  });
}
