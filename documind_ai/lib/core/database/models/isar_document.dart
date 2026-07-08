import 'package:objectbox/objectbox.dart';

@Entity()
class IsarDocument {
  @Id()
  int id;

  String fileName;
  String filePath;
  
  @Property(type: PropertyType.date)
  DateTime? createdAt;

  IsarDocument({
    this.id = 0,
    required this.fileName,
    required this.filePath,
    this.createdAt,
  });
}
