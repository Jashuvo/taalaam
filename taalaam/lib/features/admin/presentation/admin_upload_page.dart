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
  final bool isDuplicate;

  const UploadFileStatus({
    required this.file,
    this.status = 'অপেক্ষায়…',
    this.success = false,
    this.processing = false,
    this.isDuplicate = false,
  });

  UploadFileStatus copyWith({
    String? status,
    bool? success,
    bool? processing,
    bool? isDuplicate,
  }) =>
      UploadFileStatus(
        file: file,
        status: status ?? this.status,
        success: success ?? this.success,
        processing: processing ?? this.processing,
        isDuplicate: isDuplicate ?? this.isDuplicate,
      );
}

class UploadPageState {
  final List<UploadFileStatus> files;
  final String track;
  final bool processingAll;
  final bool anySuccess;

  const UploadPageState({
    this.files = const [],
    this.track = 'auto',
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

  Future<void> addFiles(List<PlatformFile> incoming) async {
    final existing = state.files;
    final toAdd = incoming
        .where((f) => !existing.any((s) => s.file.name == f.name))
        .map((f) => UploadFileStatus(file: f))
        .toList();
    if (toAdd.isEmpty) return;
    state = state.copyWith(files: [...existing, ...toAdd]);

    // Check which filenames were already processed before
    try {
      final names = toAdd.map((f) => f.file.name).toList();
      final res = await Supabase.instance.client
          .from('source_materials')
          .select('filename')
          .inFilter('filename', names);
      final seen = {for (final r in (res as List)) r['filename'] as String};
      if (seen.isNotEmpty) {
        final updated = state.files
            .map((fs) => seen.contains(fs.file.name)
                ? fs.copyWith(isDuplicate: true)
                : fs)
            .toList();
        state = state.copyWith(files: updated);
      }
    } catch (_) {}
  }

  void removeAt(int index) {
    final files = [...state.files];
    files.removeAt(index);
    state = state.copyWith(files: files);
  }

  void resetFile(int index) {
    _updateFile(index, status: 'অপেক্ষায়…', success: false, processing: false);
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
      await ref.read(uploadProvider.notifier).addFiles(result.files);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final upload = ref.watch(uploadProvider);
    final notifier = ref.read(uploadProvider.notifier);

    final hasFiles = upload.files.isNotEmpty;
    final hasPending = upload.files.any((f) => !f.success && !f.processing);
    final allDone = hasFiles && !hasPending;

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
                // Track selector — 'auto' lets Gemini decide based on content
                Text('কোর্স:', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'auto',
                        label: Text('স্বয়ংক্রিয়'),
                        icon: Icon(Icons.auto_awesome)),
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
                if (upload.track == 'auto') ...[
                  const SizedBox(height: 6),
                  Text(
                    'AI বিষয়বস্তু পড়ে স্বয়ংক্রিয়ভাবে কুরআন বা কথোপকথন কোর্স নির্বাচন করবে।',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
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
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(fs.file.name,
                                  style: theme.textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            if (fs.isDuplicate && !fs.success)
                              Tooltip(
                                message: 'এই ফাইল আগে একবার প্রসেস করা হয়েছে',
                                child: Icon(Icons.warning_amber_rounded,
                                    size: 15, color: Colors.orange.shade700),
                              ),
                          ],
                        ),
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
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (fs.success)
                                    Tooltip(
                                      message: 'আবার প্রসেস করুন',
                                      child: IconButton(
                                        icon: const Icon(Icons.replay, size: 16),
                                        onPressed: () => notifier.resetFile(i),
                                        visualDensity: VisualDensity.compact,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () => notifier.removeAt(i),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
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
