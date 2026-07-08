import 'package:objectbox/objectbox.dart';

@Entity()
class IsarChunk {
  @Id()
  int id;

  @Index()
  int docId;

  String chunkText;

  @HnswIndex(dimensions: 1536)
  @Property(type: PropertyType.floatVector)
  List<double>? chunkVector;

  IsarChunk({
    this.id = 0,
    required this.docId,
    required this.chunkText,
    this.chunkVector,
  });
}
