import 'package:objectbox/objectbox.dart';
import 'agent_message.dart';

@Entity()
class AgentSession {
  @Id()
  int id;

  String agentType; // 'Document Mind', 'Email Crafter', 'Language Tutor', 'Quick Chat'
  String title; // A short generated title or default title
  
  int? relatedDocId; // Nullable, used if linked to a specific Document Mind file

  bool isPinned; // Used for pinning history items

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime updatedAt;

  @Backlink('session')
  final messages = ToMany<AgentMessage>();

  AgentSession({
    this.id = 0,
    required this.agentType,
    required this.title,
    this.relatedDocId,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });
}
