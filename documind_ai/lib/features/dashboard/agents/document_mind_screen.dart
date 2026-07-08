import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../../../../objectbox.g.dart';
import '../../../../main.dart'; // Access obxStore
import '../../../../core/widgets/premium_background.dart';
import '../../../../core/database/models/isar_document.dart';
import '../../../../core/database/models/isar_chunk.dart';
import '../../documents/services/document_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../monetization/services/usage_tracker.dart';
import '../../monetization/ui/paywall_bottom_sheet.dart';
import '../../auth/provider_bottom_sheet.dart';
import '../../../../core/providers/ai_provider.dart';

final documentServiceProvider = Provider((ref) => DocumentService());

final documentsProvider = FutureProvider<List<IsarDocument>>((ref) async {
  final box = obxStore.box<IsarDocument>();
  return box.getAll();
});

class DocumentMindScreen extends ConsumerStatefulWidget {
  const DocumentMindScreen({super.key});

  @override
  ConsumerState<DocumentMindScreen> createState() => _DocumentMindScreenState();
}

class _DocumentMindScreenState extends ConsumerState<DocumentMindScreen> {
  bool _isProcessing = false;

  Future<void> _pickAndProcessDocument() async {
    HapticFeedback.selectionClick();

    final usageTracker = ref.read(usageTrackerProvider);
    final canProcess = await usageTracker.canProcessDocument();
    
    if (!canProcess) {
      if (mounted) {
        PaywallBottomSheet.show(
          context, 
          title: "Limit Reached", 
          message: "You've reached your free limit of 1 document. Upgrade to Pro for unlimited documents and chats!"
        );
      }
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    final config = ref.read(aiProviderConfigProvider).value;
    if (config == null || config.apiKey.isEmpty) {
      if (mounted) {
        final success = await ProviderBottomSheet.show(context);
        if (success != true) return;
      }
    }

    final filePath = result.files.single.path!;
    final fileName = result.files.single.name;

    setState(() {
      _isProcessing = true;
    });

    try {
      final docService = ref.read(documentServiceProvider);
      
      final chunks = await docService.processPdf(filePath);
      if (chunks.isEmpty) throw Exception("Could not extract text from the PDF.");

      final boxDocs = obxStore.box<IsarDocument>();
      final boxChunks = obxStore.box<IsarChunk>();

      final newDoc = IsarDocument(
        fileName: fileName,
        filePath: filePath,
        createdAt: DateTime.now(),
      );
      
      final docId = boxDocs.put(newDoc);

      final objChunks = chunks.map((text) {
        return IsarChunk(
          docId: docId,
          chunkText: text,
        );
      }).toList();

      boxChunks.putMany(objChunks);

      await usageTracker.incrementDocumentCount();

      ref.invalidate(documentsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing document: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(documentsProvider);

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Document Mind'),
        ),
        body: _isProcessing 
            ? const _ShimmerLoading() 
            : docsAsync.when(
                data: (docs) {
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 150,
                            child: Lottie.network(
                              'https://assets9.lottiefiles.com/packages/lf20_tno6cg2w.json', 
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.upload_file, 
                                size: 80, 
                                color: AppTheme.electricBlue.withOpacity(0.5)
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Drop your first document here', style: TextStyle(fontSize: 18, color: Colors.grey[400])),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      return Card(
                        color: Colors.grey[900],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                          title: Text(doc.fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Added ${doc.createdAt?.toString().split(' ')[0] ?? 'Unknown'}'),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              HapticFeedback.selectionClick();
                              final config = ref.read(aiProviderConfigProvider).value;
                              if (config == null || config.apiKey.isEmpty) {
                                if (mounted) {
                                  final success = await ProviderBottomSheet.show(context);
                                  if (success != true) return;
                                }
                              }
                              if (mounted) {
                                context.push('/chat', extra: {
                                  'docId': doc.id,
                                  'docName': doc.fileName,
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.neonPurple,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Chat'),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error loading documents: $e')),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _isProcessing ? null : _pickAndProcessDocument,
          backgroundColor: AppTheme.electricBlue,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

class _ShimmerLoading extends StatelessWidget {
  const _ShimmerLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 80,
          decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(12)),
          child: const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple)),
        );
      },
    );
  }
}
