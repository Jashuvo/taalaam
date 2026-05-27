import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class UploadFileStatus {
  final PlatformFile file;
  final String status;
  final bool success;
  final bool processing;

  const UploadFileStatus({
    required this.file,
    this.status = 'অপেক্ষায়…',
    this.success = false,
    this.processing = false,
  });

  UploadFileStatus copyWith({String? status, bool? success, bool? processing}) =>
      UploadFileStatus(
        file: file,
        status: status ?? this.status,
        success: success ?? this.success,
        processing: processing ?? this.processing,
      );
}

class UploadPageState {
  final List<UploadFileStatus> files;
  final String track;
  final bool processingAll;
  final bool anySuccess;

  const UploadPageState({
    this.files = const [],
    this.track = 'conversational',
    this.processingAll = false,
    this.anySuccess = false,
  });

  UploadPageState copyWith({
    List<UploadFileStatus>? files,
    String? track,
    bool? processingAll,
    bool? anySuccess,
  }) =>
      UploadPageState(
        files: files ?? this.files,
        track: track ?? this.track,
        processingAll: processingAll ?? this.processingAll,
        anySuccess: anySuccess ?? this.anySuccess,
      );
}

class UploadNotifier extends Notifier<UploadPageState> {
  @override
  UploadPageState build() => const UploadPageState();

  void addFiles(List<PlatformFile> incoming) {
    final existing = state.files;
    final toAdd = incoming
        .where((f) => !existing.any((s) => s.file.name == f.name))
        .map((f) => UploadFileStatus(file: f))
        .toList();
    if (toAdd.isEmpty) return;
    state = state.copyWith(files: [...existing, ...toAdd]);
  }

  void removeAt(int index) {
    final files = [...state.files];
    files.removeAt(index);
    state = state.copyWith(files: files);
  }

  void setTrack(String track) => state = state.copyWith(track: track);

  void _updateFile(int index,
      {String? status, bool? success, bool? processing}) {
    final files = [...state.files];
    files[index] =
        files[index].copyWith(status: status, success: success, processing: processing);
    state = state.copyWith(files: files);
  }

  Future<void> processAll(String note) async {
    state = state.copyWith(processingAll: true);
    final indices = [
      for (int i = 0; i < state.files.length; i++)
        if (!state.files[i].success && !state.files[i].processing) i
    ];
    for (final i in indices) {
      await _processOne(i, note);
    }
    state = state.copyWith(processingAll: false);
  }

  Future<void> _processOne(int index, String note) async {
    final fs = state.files[index];
    if (fs.file.bytes == null) return;
    _updateFile(index, processing: true, status: 'আপলোড হচ্ছে…');

    try {
      final supabase = Supabase.instance.client;
      final safeName = _sanitizeFilename(fs.file.name).isEmpty
          ? (fs.file.extension ?? 'file')
          : _sanitizeFilename(fs.file.name);
      final path =
          'raw-content/${DateTime.now().millisecondsSinceEpoch}_$safeName';

      await supabase.storage.from('raw-content').uploadBinary(path, fs.file.bytes!);

      final mat = await supabase.from('source_materials').insert({
        'filename': fs.file.name,
        'storage_path': path,
        'file_type': fs.file.extension ?? 'unknown',
        'processing_status': 'pending',
        'notes': note.trim().isEmpty ? null : note.trim(),
      }).select().single();

      _updateFile(index, status: 'AI প্রসেসিং…');

      final ext = fs.file.extension?.toLowerCase();
      final String? textContent =
          ext == 'txt' ? String.fromCharCodes(fs.file.bytes!) : null;

      await supabase.functions.invoke('process-content', body: {
        'material_id': mat['id'],
        'track': state.track,
        'notes': note.trim(),
        if (textContent != null) 'text_content': textContent,
      });

      _updateFile(index, status: 'সফল ✓', success: true);
      state = state.copyWith(anySuccess: true);
    } catch (e) {
      _updateFile(index, status: 'ত্রুটি: $e');
    } finally {
      _updateFile(index, processing: false);
    }
  }

  String _sanitizeFilename(String name) {
    return name
        .replaceAll(RegExp(r'[^\x00-\x7F]'), '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}

// Not autoDispose — state survives navigation within the same app session
final uploadProvider =
    NotifierProvider<UploadNotifier, UploadPageState>(UploadNotifier.new);

// ── Page ──────────────────────────────────────────────────────────────────────

class AdminUploadPage extends ConsumerStatefulWidget {
  const AdminUploadPage({super.key});

  @override
  ConsumerState<AdminUploadPage> createState() => _AdminUploadPageState();
}

class _AdminUploadPageState extends ConsumerState<AdminUploadPage> {
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'png', 'jpg', 'jpeg'],
      allowMultiple: true,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      ref.read(uploadProvider.notifier).addFiles(result.files);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final upload = ref.watch(uploadProvider);
    final notifier = ref.read(uploadProvider.notifier);

    final hasFiles = upload.files.isNotEmpty;
    final allDone = hasFiles && upload.files.every((f) => f.success);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Content'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Track selector
                Text('কোর্স:', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'conversational',
                        label: Text('কথোপকথন'),
                        icon: Icon(Icons.record_voice_over)),
                    ButtonSegment(
                        value: 'quranic',
                        label: Text('কুরআন'),
                        icon: Icon(Icons.menu_book)),
                  ],
                  selected: {upload.track},
                  onSelectionChanged: upload.processingAll
                      ? null
                      : (s) => notifier.setTrack(s.first),
                ),
                const SizedBox(height: 24),

                // File drop zone
                GestureDetector(
                  onTap: upload.processingAll ? null : _pickFiles,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: hasFiles
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                          width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: hasFiles
                          ? theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.15)
                          : theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.upload_file_outlined,
                          size: 36,
                          color: hasFiles
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasFiles
                              ? '${upload.files.length}টি ফাইল নির্বাচিত — আরও যোগ করতে ক্লিক করুন'
                              : 'একাধিক ফাইল বেছে নিন (PDF / TXT / ছবি)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: hasFiles
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // File list
                if (hasFiles) ...[
                  ...upload.files.asMap().entries.map((e) {
                    final i = e.key;
                    final fs = e.value;
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: fs.success
                              ? Colors.green.shade300
                              : theme.colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: fs.processing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                fs.success
                                    ? Icons.check_circle
                                    : Icons.insert_drive_file_outlined,
                                color: fs.success
                                    ? Colors.green.shade700
                                    : theme.colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                        title: Text(fs.file.name,
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis),
                        subtitle: Text(fs.status,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: fs.success
                                  ? Colors.green.shade700
                                  : fs.status.startsWith('ত্রুটি')
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.onSurfaceVariant,
                            )),
                        trailing: upload.processingAll
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () => notifier.removeAt(i),
                                visualDensity: VisualDensity.compact,
                              ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],

                // Optional note
                TextField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'প্রসঙ্গ নোট (ঐচ্ছিক)',
                    hintText: 'যেমন: "Al-Asr Book 1, Lessons 19-24"',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  enabled: !upload.processingAll,
                ),
                const SizedBox(height: 24),

                FilledButton.icon(
                  icon: upload.processingAll
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(upload.processingAll
                      ? 'প্রসেস হচ্ছে…'
                      : hasFiles
                          ? 'AI দিয়ে ${upload.files.length}টি ফাইল প্রসেস করুন'
                          : 'AI দিয়ে পাঠ তৈরি করুন'),
                  onPressed: upload.processingAll || !hasFiles || allDone
                      ? null
                      : () => notifier.processAll(_noteCtrl.text),
                ),

                if (upload.anySuccess) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.go('/admin/review'),
                    child: const Text('ড্রাফট রিভিউ করুন →'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
