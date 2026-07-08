import 'package:objectbox/objectbox.dart';
import 'agent_session.dart';

@Entity()
class AgentMessage {
  @Id()
  int id;

  String role; // 'user' or 'ai'
  
  String text;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  final session = ToOne<AgentSession>();

  AgentMessage({
    this.id = 0,
    required this.role,
    required this.text,
    required this.createdAt,
  });
}
