import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../main.dart'; // Access obxStore
import '../../../../objectbox.g.dart';
import '../../../../core/database/models/agent_session.dart';
import '../../../../core/database/models/agent_message.dart';

final historyServiceProvider = Provider((ref) => HistoryService());

class HistoryService {
  late final Box<AgentSession> _sessionBox;
  late final Box<AgentMessage> _messageBox;

  HistoryService() {
    _sessionBox = obxStore.box<AgentSession>();
    _messageBox = obxStore.box<AgentMessage>();
  }

  /// Get all sessions, sorted by isPinned descending, then updatedAt descending.
  List<AgentSession> getAllSessions() {
    final query = _sessionBox.query()
        .order(AgentSession_.isPinned, flags: Order.descending)
        .order(AgentSession_.updatedAt, flags: Order.descending).build();
    final results = query.find();
    query.close();
    return results;
  }

  /// Get sessions for a specific agent type.
  List<AgentSession> getSessionsByAgentType(String agentType) {
    final query = _sessionBox.query(AgentSession_.agentType.equals(agentType))
        .order(AgentSession_.isPinned, flags: Order.descending)
        .order(AgentSession_.updatedAt, flags: Order.descending).build();
    final results = query.find();
    query.close();
    return results;
  }

  /// Get a session by its related Document ID (for Document Mind).
  AgentSession? getSessionByDocId(int docId) {
    final query = _sessionBox.query(AgentSession_.relatedDocId.equals(docId)).build();
    final session = query.findFirst();
    query.close();
    return session;
  }

  /// Create a new session.
  AgentSession createSession({
    required String agentType,
    required String title,
    int? relatedDocId,
  }) {
    final session = AgentSession(
      agentType: agentType,
      title: title,
      relatedDocId: relatedDocId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _sessionBox.put(session);
    return session;
  }

  /// Add a message to an existing session.
  AgentMessage addMessageToSession(int sessionId, String role, String text) {
    final session = _sessionBox.get(sessionId);
    if (session == null) throw Exception('Session not found');

    final message = AgentMessage(
      role: role,
      text: text,
      createdAt: DateTime.now(),
    );
    
    // Using ObjectBox relations
    message.session.target = session;
    _messageBox.put(message);

    // Update session timestamp
    session.updatedAt = DateTime.now();
    _sessionBox.put(session);

    return message;
  }

  /// Create a single-turn session (e.g. Email Crafter or Language Tutor)
  AgentSession createSingleTurnSession(String agentType, String prompt, String response) {
    // Generate a short title from prompt
    String title = prompt.replaceAll('\n', ' ');
    if (title.length > 30) {
      title = '${title.substring(0, 30)}...';
    }

    final session = createSession(agentType: agentType, title: title);
    addMessageToSession(session.id, 'user', prompt);
    addMessageToSession(session.id, 'ai', response);

    return session;
  }

  /// Delete a session and its messages.
  void deleteSession(int sessionId) {
    // Due to the Backlink relation, ObjectBox doesn't auto-cascade delete in Dart yet.
    // We must delete messages manually.
    final session = _sessionBox.get(sessionId);
    if (session != null) {
      for (final msg in session.messages) {
        _messageBox.remove(msg.id);
      }
      _sessionBox.remove(sessionId);
    }
  }

  /// Toggle pin status
  void togglePin(int sessionId) {
    final session = _sessionBox.get(sessionId);
    if (session != null) {
      session.isPinned = !session.isPinned;
      _sessionBox.put(session);
    }
  }

  /// Rename session
  void renameSession(int sessionId, String newTitle) {
    final session = _sessionBox.get(sessionId);
    if (session != null) {
      session.title = newTitle;
      _sessionBox.put(session);
    }
  }
}
