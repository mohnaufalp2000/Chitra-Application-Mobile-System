// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:camos/objectbox.g.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ObjectBox {
  final Store store;

  ObjectBox._create({
    required this.store,
  });

  static Future<ObjectBox> create() async {
    var dir = await getApplicationDocumentsDirectory();

    Store store =
        await openStore(directory: path.join(dir.path, 'objectbox_crud'));

    return ObjectBox._create(store: store);
  }
}
