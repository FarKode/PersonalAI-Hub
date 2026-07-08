import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';
import '../models/chat_message.dart';
import '../services/rag_orchestrator.dart';
import '../../monetization/services/usage_tracker.dart';
import '../../../core/services/ai_service.dart';
import '../../history/services/history_service.dart';
import '../../../core/database/models/agent_session.dart';
import '../../../core/database/models/isar_document.dart';
final ragOrchestratorProvider = Provider((ref) {
  final aiService = ref.watch(aiServiceProvider);
  return RagOrchestrator(
    aiService: aiService,
  );
});

final chatProvider = NotifierProvider<ChatNotifier, List<ChatMessage>>(() {
  return ChatNotifier();
});

class ChatNotifier extends Notifier<List<ChatMessage>> {
  late final RagOrchestrator _rag;
  late final UsageTracker _usageTracker;
  late final HistoryService _historyService;
  bool isTyping = false;
  int? _docId;
  AgentSession? _session;

  @override
  List<ChatMessage> build() {
    _rag = ref.read(ragOrchestratorProvider);
    _usageTracker = ref.read(usageTrackerProvider);
    _historyService = ref.read(historyServiceProvider);
    return [];
  }

  void setDocId(int docId) {
    if (_docId == docId) return;
    _docId = docId;
    _loadHistory();
  }

  void _loadHistory() {
    if (_docId == null) return;
    
    _session = _historyService.getSessionByDocId(_docId!);
    if (_session != null) {
      final msgs = _session!.messages.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      state = msgs.map((m) => ChatMessage(
        id: m.id.toString(),
        text: m.text,
        role: m.role == 'user' ? ChatRole.user : ChatRole.ai,
        timestamp: m.createdAt,
      )).toList();
    } else {
      state = [];
    }
  }

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<bool> checkLimits() async {
    return await _usageTracker.canSendDocumentMessage();
  }

  Future<void> sendMessage(String text) async {
    if (_docId == null) return;
    
    final canSend = await checkLimits();
    if (!canSend) {
      throw Exception("PAYWALL_LIMIT_REACHED");
    }

    await _usageTracker.incrementDocumentMessage();

    final userMsg = ChatMessage(
      id: _generateId(),
      text: text,
      role: ChatRole.user,
      timestamp: DateTime.now(),
    );
    state = [...state, userMsg];

    if (_session == null) {
      final docBox = obxStore.box<IsarDocument>();
      final doc = docBox.get(_docId!);
      final title = doc?.fileName ?? 'Document Chat';
      _session = _historyService.createSession(agentType: 'Document Mind', title: title, relatedDocId: _docId);
    }
    _historyService.addMessageToSession(_session!.id, 'user', text);
    
    isTyping = true;
    state = [...state]; 
    
    final aiMsgId = _generateId();
    var aiMsg = ChatMessage(
      id: aiMsgId,
      text: '',
      role: ChatRole.ai,
      timestamp: DateTime.now(),
    );
    state = [...state, aiMsg];

    try {
      final stream = await _rag.answerQueryStream(text, _docId!);
      isTyping = false;
      
      await for (final chunk in stream) {
        aiMsg = aiMsg.copyWith(text: aiMsg.text + chunk);
        state = [
          for (final msg in state)
            if (msg.id == aiMsgId) aiMsg else msg
        ];
      }
      
      // Save AI message to history after streaming is done
      _historyService.addMessageToSession(_session!.id, 'ai', aiMsg.text);
    } catch (e) {
      isTyping = false;
      aiMsg = aiMsg.copyWith(text: 'Error generating response: $e');
      state = [
        for (final msg in state)
          if (msg.id == aiMsgId) aiMsg else msg
      ];
    }
  }

  Future<void> generateSummary() async {
    await sendMessage("Please provide a comprehensive summary of this document. Extract the key takeaways.");
  }
}

