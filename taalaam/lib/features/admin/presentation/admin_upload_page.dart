import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUploadPage extends ConsumerStatefulWidget {
  const AdminUploadPage({super.key});

  @override
  ConsumerState<AdminUploadPage> createState() => _AdminUploadPageState();
}

class _FileStatus {
  final PlatformFile file;
  String status;
  bool success;
  bool processing;
  _FileStatus(this.file)
      : status = 'অপেক্ষায়…',
        success = false,
        processing = false;
}

class _AdminUploadPageState extends ConsumerState<AdminUploadPage> {
  final _files = <_FileStatus>[];
  String _track = 'conversational';
  final _noteCtrl = TextEditingController();
  bool _processingAll = false;
  bool _anySuccess = false;

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
      setState(() {
        for (final f in result.files) {
          if (!_files.any((s) => s.file.name == f.name)) {
            _files.add(_FileStatus(f));
          }
        }
      });
    }
  }

  Future<void> _processOne(_FileStatus fs) async {
    if (fs.file.bytes == null) return;
    setState(() {
      fs.processing = true;
      fs.status = 'আপলোড হচ্ছে…';
    });

    try {
      final supabase = Supabase.instance.client;
      final path =
          'raw-content/${DateTime.now().millisecondsSinceEpoch}_${fs.file.name}';

      await supabase.storage.from('raw-content').uploadBinary(path, fs.file.bytes!);

      final mat = await supabase.from('source_materials').insert({
        'filename': fs.file.name,
        'storage_path': path,
        'file_type': fs.file.extension ?? 'unknown',
        'processing_status': 'pending',
        'notes': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      }).select().single();

      setState(() => fs.status = 'AI প্রসেসিং…');

      final ext = fs.file.extension?.toLowerCase();
      final String? textContent =
          ext == 'txt' ? String.fromCharCodes(fs.file.bytes!) : null;

      await supabase.functions.invoke('process-content', body: {
        'material_id': mat['id'],
        'track': _track,
        'notes': _noteCtrl.text.trim(),
        if (textContent != null) 'text_content': textContent,
      });

      setState(() {
        fs.status = 'সফল ✓';
        fs.success = true;
        _anySuccess = true;
      });
    } catch (e) {
      setState(() => fs.status = 'ত্রুটি: $e');
    } finally {
      setState(() => fs.processing = false);
    }
  }

  Future<void> _processAll() async {
    setState(() => _processingAll = true);
    for (final fs in _files) {
      if (!fs.success && !fs.processing) {
        await _processOne(fs);
      }
    }
    setState(() => _processingAll = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFiles = _files.isNotEmpty;
    final allDone = hasFiles && _files.every((f) => f.success);

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
                  selected: {_track},
                  onSelectionChanged: _processingAll
                      ? null
                      : (s) => setState(() => _track = s.first),
                ),
                const SizedBox(height: 24),

                // File drop zone
                GestureDetector(
                  onTap: _processingAll ? null : _pickFiles,
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
                              ? '${_files.length}টি ফাইল নির্বাচিত — আরও যোগ করতে ক্লিক করুন'
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
                  ...(_files.asMap().entries.map((e) {
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
                        trailing: _processingAll
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () =>
                                    setState(() => _files.removeAt(i)),
                                visualDensity: VisualDensity.compact,
                              ),
                      ),
                    );
                  })),
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
                  enabled: !_processingAll,
                ),
                const SizedBox(height: 24),

                FilledButton.icon(
                  icon: _processingAll
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(_processingAll
                      ? 'প্রসেস হচ্ছে…'
                      : hasFiles
                          ? 'AI দিয়ে ${_files.length}টি ফাইল প্রসেস করুন'
                          : 'AI দিয়ে পাঠ তৈরি করুন'),
                  onPressed: _processingAll || !hasFiles || allDone
                      ? null
                      : _processAll,
                ),

                if (_anySuccess) ...[
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
