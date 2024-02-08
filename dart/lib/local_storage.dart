// In a file named local_storage.dart

import 'package:hive/hive.dart';
part 'local_storage.g.dart';

@HiveType(typeId: 0)
class FormData extends HiveObject {
  @HiveField(0)
  late String field1;

  @HiveField(1)
  late String field2;

  @HiveField(2)
  late String field3;
}
