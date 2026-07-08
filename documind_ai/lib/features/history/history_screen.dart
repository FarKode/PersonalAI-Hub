import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/premium_background.dart';
import '../../core/database/models/agent_session.dart';
import 'services/history_service.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  final String? initialFilter; // Optional, pre-selects an agent tab

  const HistoryScreen({super.key, this.initialFilter});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Document Mind', 'Email Crafter', 'Language Tutor', 'Quick Chat'];

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null && _filters.contains(widget.initialFilter)) {
      _selectedFilter = widget.initialFilter!;
    }
  }

  IconData _getIconForAgent(String agentType) {
    switch (agentType) {
      case 'Document Mind': return Icons.auto_stories;
      case 'Email Crafter': return Icons.mark_email_read;
      case 'Language Tutor': return Icons.language;
      case 'Quick Chat': return Icons.chat_bubble_outline;
      default: return Icons.history;
    }
  }

  Color _getColorForAgent(String agentType) {
    switch (agentType) {
      case 'Document Mind': return AppTheme.neonPurple;
      case 'Email Crafter': return AppTheme.electricBlue;
      case 'Language Tutor': return Colors.greenAccent;
      case 'Quick Chat': return Colors.orangeAccent;
      default: return Colors.white;
    }
  }

  void _showSessionDetails(AgentSession session) {
    HapticFeedback.selectionClick();
    
    // If Document Mind, maybe route back to Chat screen?
    // For now, let's show a dialog/bottom sheet for read-only viewing of all single-turn/chats.
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.amoledBlack,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            final messages = session.messages.toList()
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(_getIconForAgent(session.agentType), color: _getColorForAgent(session.agentType)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          session.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const Divider(color: Colors.white24),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isUser = msg.role == 'user';
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                            decoration: BoxDecoration(
                              color: isUser ? AppTheme.electricBlue.withOpacity(0.9) : Colors.grey[850],
                              borderRadius: BorderRadius.circular(12).copyWith(
                                bottomRight: isUser ? Radius.zero : const Radius.circular(12),
                                bottomLeft: !isUser ? Radius.zero : const Radius.circular(12),
                              ),
                            ),
                            child: SelectableText(
                              msg.text, 
                              style: const TextStyle(color: Colors.white, fontSize: 15)
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _deleteSession(AgentSession session) {
    ref.read(historyServiceProvider).deleteSession(session.id);
    setState(() {}); // refresh
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('History deleted')));
  }

  void _togglePin(AgentSession session) {
    ref.read(historyServiceProvider).togglePin(session.id);
    setState(() {});
    HapticFeedback.lightImpact();
  }

  Future<void> _renameSession(AgentSession session) async {
    final controller = TextEditingController(text: session.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.amoledBlack,
        title: const Text('Rename Session', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter new name',
            hintStyle: TextStyle(color: Colors.grey),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonPurple),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty) {
      ref.read(historyServiceProvider).renameSession(session.id, newTitle);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyService = ref.watch(historyServiceProvider);
    
    List<AgentSession> sessions;
    if (_selectedFilter == 'All') {
      sessions = historyService.getAllSessions();
    } else {
      sessions = historyService.getSessionsByAgentType(_selectedFilter);
    }

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('History'),
        ),
        body: Column(
          children: [
            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: AppTheme.neonPurple.withOpacity(0.3),
                      backgroundColor: Colors.grey[900],
                      side: BorderSide(color: isSelected ? AppTheme.neonPurple : Colors.transparent),
                      onSelected: (selected) {
                        HapticFeedback.lightImpact();
                        if (selected) {
                          setState(() => _selectedFilter = filter);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            
            // List
            Expanded(
              child: sessions.isEmpty
                  ? Center(
                      child: Text(
                        'No history found.',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final dateStr = '${session.updatedAt.day}/${session.updatedAt.month}/${session.updatedAt.year}';
                        
                        return Dismissible(
                          key: Key(session.id.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => _deleteSession(session),
                          child: Card(
                            color: Colors.grey[900]?.withOpacity(0.6),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _getColorForAgent(session.agentType).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(_getIconForAgent(session.agentType), color: _getColorForAgent(session.agentType), size: 20),
                              ),
                              title: Row(
                                children: [
                                  if (session.isPinned)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 4.0),
                                      child: Icon(Icons.push_pin, size: 14, color: AppTheme.neonPurple),
                                    ),
                                  Expanded(child: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold))),
                                ],
                              ),
                              subtitle: Text('$dateStr • ${session.agentType}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                              onTap: () => _showSessionDetails(session),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Colors.grey),
                                color: AppTheme.amoledBlack,
                                onSelected: (value) {
                                  if (value == 'pin') _togglePin(session);
                                  if (value == 'rename') _renameSession(session);
                                  if (value == 'delete') _deleteSession(session);
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'pin',
                                    child: Row(
                                      children: [
                                        Icon(session.isPinned ? Icons.push_pin_outlined : Icons.push_pin, color: Colors.white, size: 18),
                                        const SizedBox(width: 8),
                                        Text(session.isPinned ? 'Unpin' : 'Pin to Top', style: const TextStyle(color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'rename',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, color: Colors.white, size: 18),
                                        SizedBox(width: 8),
                                        Text('Rename', style: TextStyle(color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
