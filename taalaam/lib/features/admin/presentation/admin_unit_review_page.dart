import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/confirm_dialog.dart';

class AdminUnitReviewPage extends StatefulWidget {
  final String unitId;
  const AdminUnitReviewPage({required this.unitId, super.key});

  @override
  State<AdminUnitReviewPage> createState() => _AdminUnitReviewPageState();
}

class _AdminUnitReviewPageState extends State<AdminUnitReviewPage> {
  Map<String, dynamic>? _unit;
  List<Map<String, dynamic>> _lessons = [];
  Map<String, dynamic>? _examLesson;
  int _examQuestionCount = 0;
  final _exercisesMap = <String, List<Map<String, dynamic>>>{};
  final _vocabularyMap = <String, List<Map<String, dynamic>>>{};
  bool _loading = true;
  String? _error;
  bool _publishing = false;
  bool _sorting = false;
  bool _generatingExam = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final c = Supabase.instance.client;
      final unit = await c.from('units').select().eq('id', widget.unitId).single();

      final allLessons = List<Map<String, dynamic>>.from(
        await c.from('lessons').select().eq('unit_id', widget.unitId).order('sort_order'),
      );

      // Separate regular lessons from the exam lesson
      final regularLessons = allLessons
          .where((l) => !(l['is_exam'] as bool? ?? false))
          .toList();
      final examCandidates = allLessons
          .where((l) => l['is_exam'] as bool? ?? false)
          .toList();
      final examLesson = examCandidates.isNotEmpty ? examCandidates.first : null;

      // Count stored exam questions for this unit
      int examQuestionCount = 0;
      if (examLesson != null) {
        final qRes = await c
            .from('exam_questions')
            .select('id')
            .eq('unit_id', widget.unitId);
        examQuestionCount = (qRes as List).length;
      }

      _exercisesMap.clear();
      _vocabularyMap.clear();
      for (final lesson in regularLessons) {
        final lid = lesson['id'] as String;
        _exercisesMap[lid] = List<Map<String, dynamic>>.from(
          await c.from('exercises').select().eq('lesson_id', lid).order('sort_order'),
        );
        _vocabularyMap[lid] = List<Map<String, dynamic>>.from(
          await c.from('vocabulary').select().eq('lesson_id', lid),
        );
      }
      setState(() {
        _unit = unit;
        _lessons = regularLessons;
        _examLesson = examLesson;
        _examQuestionCount = examQuestionCount;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _viewExamQuestions() async {
    final rows = await Supabase.instance.client
        .from('exam_questions')
        .select()
        .eq('unit_id', widget.unitId)
        .order('sort_order');
    if (!mounted) return;
    final questions = List<Map<String, dynamic>>.from(rows as List);
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কোনো প্রশ্ন সংরক্ষিত নেই')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => _ExamQuestionsPreviewDialog(
        unitTitle: _unit?['title_bn'] as String? ?? 'মডিউল',
        questions: questions,
      ),
    );
  }

  Future<void> _generateExam() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'পরীক্ষা তৈরি করবেন?',
      body: 'Gemini এই মডিউলের সমস্ত পাঠ বিশ্লেষণ করে ৩০টি প্রশ্নের একটি প্রশ্ন ব্যাংক তৈরি করবে। '
          'প্রতিবার শিক্ষার্থী পরীক্ষা দিলে ১০-১২টি র‍্যান্ডম প্রশ্ন দেওয়া হবে।',
      confirmLabel: 'তৈরি করুন',
      cancelLabel: 'বাতিল',
    );
    if (!confirmed || !mounted) return;

    setState(() => _generatingExam = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI ৩০টি পরীক্ষার প্রশ্ন তৈরি করছে…')),
      );
    }
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'generate-exam',
        body: {'unit_id': widget.unitId},
      );
      final data = res.data as Map<String, dynamic>?;
      if (data?['error'] != null) throw Exception(data!['error']);
      final qCount = data?['question_count'] as int? ?? 0;
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('পরীক্ষার প্রশ্ন ব্যাংক তৈরি হয়েছে! 🏆 ($qCount প্রশ্ন)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('ত্রুটি: $e')));
      }
    } finally {
      if (mounted) setState(() => _generatingExam = false);
    }
  }

  Future<void> _publishUnit() async {
    setState(() => _publishing = true);
    try {
      final c = Supabase.instance.client;
      await c.from('units').update({'status': 'published'}).eq('id', widget.unitId);
      for (final lesson in _lessons) {
        await c.from('lessons').update({'status': 'published'}).eq('id', lesson['id']);
      }
      setState(() => _unit = {...?_unit, 'status': 'published'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('ইউনিট প্রকাশিত হয়েছে!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('ত্রুটি: $e')));
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _editExercise(Map<String, dynamic> exercise) async {
    final updated = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ExerciseEditDialog(exercise: exercise),
    );
    if (updated == null) return;
    try {
      await Supabase.instance.client.from('exercises').update(updated).eq('id', exercise['id']);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('ত্রুটি: $e')));
      }
    }
  }

  Future<void> _editVocab(Map<String, dynamic> vocab) async {
    final updated = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _VocabEditDialog(vocab: vocab),
    );
    if (updated == null) return;
    try {
      await Supabase.instance.client.from('vocabulary').update(updated).eq('id', vocab['id']);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('ত্রুটি: $e')));
      }
    }
  }

  Future<void> _regenExercise(String exerciseId) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'AI দিয়ে পুনরায় তৈরি করবেন?',
      body: 'এই এক্সারসাইজটি AI দিয়ে নতুন করে তৈরি হবে। পুরানো বিষয়বস্তু প্রতিস্থাপিত হবে।',
    );
    if (!confirm) return;
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI পুনরায় তৈরি করছে…')),
        );
      }
      await Supabase.instance.client.functions
          .invoke('regenerate-exercise', body: {'exercise_id': exerciseId});
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('এক্সারসাইজ পুনরায় তৈরি হয়েছে!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('ত্রুটি: $e')));
      }
    }
  }

  Future<void> _uploadVocabAudio(String vocabId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg', 'm4a'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    try {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('অডিও আপলোড হচ্ছে…')));
      }
      final path = 'audio/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final c = Supabase.instance.client;
      await c.storage.from('audio').uploadBinary(path, file.bytes!);
      final url = c.storage.from('audio').getPublicUrl(path);
      await c.from('vocabulary').update({'audio_url': url}).eq('id', vocabId);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('অডিও আপলোড সফল!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('ত্রুটি: $e')));
      }
    }
  }

  void _exportJson() {
    final export = {
      'unit': _unit,
      'lessons': _lessons.map((lesson) {
        final lid = lesson['id'] as String;
        return {
          ...lesson,
          'exercises': _exercisesMap[lid] ?? [],
          'vocabulary': _vocabularyMap[lid] ?? [],
        };
      }).toList(),
    };
    final json =
        const JsonEncoder.withIndent('  ').convert(export);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_unit?['title_bn'] as String? ?? 'Export JSON'),
        content: SizedBox(
          width: 560,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              json,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বন্ধ'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('কপি করুন'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: json));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('JSON কপি হয়েছে!')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPreview() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
                child: Row(
                  children: [
                    const Icon(Icons.phone_android, size: 18),
                    const SizedBox(width: 8),
                    Text('Learner Preview',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: _lessons.map((lesson) {
                    final lid = lesson['id'] as String;
                    final exercises = _exercisesMap[lid] ?? [];
                    final vocab = _vocabularyMap[lid] ?? [];
                    return _PreviewLessonCard(
                      lesson: lesson,
                      exercises: exercises,
                      vocabulary: vocab,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _aiSortLessons() async {
    if (_lessons.isEmpty) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'AI দিয়ে পাঠ সাজাবেন?',
      body: 'Gemini পাঠের শিরোনাম বিশ্লেষণ করে সর্বোত্তম শেখার ক্রম নির্ধারণ করবে।',
      confirmLabel: 'সাজান',
      cancelLabel: 'বাতিল',
    );
    if (!confirmed || !mounted) return;

    setState(() => _sorting = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI পাঠের ক্রম বিশ্লেষণ করছে…')),
      );
    }
    try {
      final res = await Supabase.instance.client.functions
          .invoke('sort-lessons', body: {'unit_id': widget.unitId});
      await _load();
      if (!mounted) return;

      final duplicates = (res.data?['duplicates'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      if (duplicates.isNotEmpty) {
        _showDuplicateWarning(duplicates);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('পাঠগুলো সফলভাবে সাজানো হয়েছে!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('ত্রুটি: $e')));
      }
    } finally {
      if (mounted) setState(() => _sorting = false);
    }
  }

  void _showDuplicateWarning(List<Map<String, dynamic>> duplicates) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text('Duplicate Lessons Found'),
        ]),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sorted successfully, but these lessons teach the same content. '
                  'Consider merging them into one lesson with more exercises:',
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                ...duplicates.map((d) {
                  final reason = d['reason'] as String? ?? '';
                  final ids =
                      (d['ids'] as List?)?.join(', ') ?? '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reason,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('IDs: $ids',
                            style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: Colors.grey)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteExercise(String exerciseId) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'এক্সারসাইজ মুছবেন?',
      body: 'এই অনুশীলনটি স্থায়ীভাবে মুছে যাবে।',
      danger: true,
    );
    if (!confirm) return;
    try {
      await Supabase.instance.client.from('exercises').delete().eq('id', exerciseId);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('ত্রুটি: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPublished = _unit?['status'] == 'published';

    return Scaffold(
      appBar: AppBar(
        title: Text(_unit?['title_bn'] as String? ?? 'ইউনিট রিভিউ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/review'),
        ),
        actions: [
          if (!_loading && _error == null) ...[
            if (_sorting || _publishing || _generatingExam)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) {
                if (v == 'exam') _generateExam();
                if (v == 'sort') _aiSortLessons();
                if (v == 'preview') _showPreview();
                if (v == 'export') _exportJson();
                if (v == 'publish') _publishUnit();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'exam',
                  child: Row(children: [
                    Icon(Icons.emoji_events_outlined,
                        size: 18, color: Colors.amber.shade600),
                    const SizedBox(width: 10),
                    Text('Generate Exam 🏆',
                        style: TextStyle(color: Colors.amber.shade700,
                            fontWeight: FontWeight.bold)),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'sort',
                  child: Row(children: [
                    Icon(Icons.auto_awesome_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('AI Sort Lessons'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'preview',
                  child: Row(children: [
                    Icon(Icons.preview_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Preview'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: Row(children: [
                    Icon(Icons.download_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Export JSON'),
                  ]),
                ),
                if (!isPublished)
                  const PopupMenuItem(
                    value: 'publish',
                    child: Row(children: [
                      Icon(Icons.publish, size: 18,
                          color: Colors.green),
                      SizedBox(width: 10),
                      Text('Publish Unit',
                          style: TextStyle(color: Colors.green)),
                    ]),
                  ),
              ],
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('ত্রুটি: $_error',
                          style: TextStyle(color: theme.colorScheme.error)),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text('পুনরায় চেষ্টা')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _UnitHeader(unit: _unit!),
                      const SizedBox(height: 20),
                      Text(
                        'পাঠসমূহ (${_lessons.length}টি)',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._lessons.asMap().entries.map((e) => _LessonSection(
                            lesson: e.value,
                            lessonNumber: e.key + 1,
                            exercises: _exercisesMap[e.value['id']] ?? [],
                            vocabulary: _vocabularyMap[e.value['id']] ?? [],
                            onEditExercise: _editExercise,
                            onDeleteExercise: _deleteExercise,
                            onRegenExercise: (id) => _regenExercise(id),
                            onEditVocab: _editVocab,
                            onUploadVocabAudio: (id) => _uploadVocabAudio(id),
                          )),
                      const SizedBox(height: 16),
                      _ExamSection(
                        examLesson: _examLesson,
                        questionCount: _examQuestionCount,
                        generating: _generatingExam,
                        onGenerate: _generateExam,
                        onViewQuestions: _examQuestionCount > 0
                            ? _viewExamQuestions
                            : null,
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _UnitHeader extends StatelessWidget {
  final Map<String, dynamic> unit;
  const _UnitHeader({required this.unit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleAr = unit['title_ar'] as String?;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(unit['title_bn'] as String? ?? '',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          if (titleAr != null && titleAr.isNotEmpty) ...[
            const SizedBox(height: 4),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                titleAr,
                style: const TextStyle(
                    fontFamily: 'NotoNaskhArabic', fontSize: 18, height: 1.6),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _StatusChip(status: unit['status'] as String? ?? 'draft'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPublished = status == 'published';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPublished ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isPublished ? 'PUBLISHED' : 'DRAFT',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isPublished ? Colors.green.shade800 : Colors.orange.shade800,
        ),
      ),
    );
  }
}

class _LessonSection extends StatefulWidget {
  final Map<String, dynamic> lesson;
  final int lessonNumber;
  final List<Map<String, dynamic>> exercises;
  final List<Map<String, dynamic>> vocabulary;
  final Future<void> Function(Map<String, dynamic>) onEditExercise;
  final Future<void> Function(String) onDeleteExercise;
  final Future<void> Function(String) onRegenExercise;
  final Future<void> Function(Map<String, dynamic>) onEditVocab;
  final Future<void> Function(String) onUploadVocabAudio;

  const _LessonSection({
    required this.lesson,
    required this.lessonNumber,
    required this.exercises,
    required this.vocabulary,
    required this.onEditExercise,
    required this.onDeleteExercise,
    required this.onRegenExercise,
    required this.onEditVocab,
    required this.onUploadVocabAudio,
  });

  @override
  State<_LessonSection> createState() => _LessonSectionState();
}

class _LessonSectionState extends State<_LessonSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleBn = widget.lesson['title_bn'] as String? ?? 'পাঠ ${widget.lessonNumber}';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(10),
              bottom: _expanded ? Radius.zero : const Radius.circular(10),
            ),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.lessonNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      titleBn,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${widget.exercises.length} ex · ${widget.vocabulary.length} vocab',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.exercises.isNotEmpty) ...[
                    Text('Exercises',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 6),
                    ...widget.exercises.asMap().entries.map((e) => _ExerciseRow(
                          exercise: e.value,
                          index: e.key + 1,
                          onEdit: () => widget.onEditExercise(e.value),
                          onDelete: () =>
                              widget.onDeleteExercise(e.value['id'] as String),
                          onRegen: () =>
                              widget.onRegenExercise(e.value['id'] as String),
                        )),
                    const SizedBox(height: 12),
                  ],
                  if (widget.vocabulary.isNotEmpty) ...[
                    Text('Vocabulary',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 6),
                    ...widget.vocabulary.map((v) => _VocabRow(
                          vocab: v,
                          onEdit: () => widget.onEditVocab(v),
                          onUploadAudio: () =>
                              widget.onUploadVocabAudio(v['id'] as String),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRegen;
  const _ExerciseRow({
    required this.exercise,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    required this.onRegen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = exercise['type'] as String? ?? '';
    final promptBn = exercise['prompt_bn'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              type.replaceAll('_', ' '),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              promptBn.isEmpty ? '(no prompt)' : promptBn,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: onRegen,
            tooltip: 'AI Regenerate',
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: onEdit,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}

class _VocabRow extends StatelessWidget {
  final Map<String, dynamic> vocab;
  final VoidCallback onEdit;
  final VoidCallback onUploadAudio;
  const _VocabRow({
    required this.vocab,
    required this.onEdit,
    required this.onUploadAudio,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final arabic = vocab['arabic'] as String? ?? '';
    final meaningBn = vocab['meaning_bn'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              arabic,
              style: const TextStyle(
                  fontFamily: 'NotoNaskhArabic', fontSize: 16, height: 1.4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              meaningBn,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              (vocab['audio_url'] as String?) != null
                  ? Icons.volume_up_outlined
                  : Icons.upload_outlined,
              size: 18,
              color: (vocab['audio_url'] as String?) != null
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: onUploadAudio,
            tooltip: 'Upload Audio',
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: onEdit,
            tooltip: 'Edit',
          ),
        ],
      ),
    );
  }
}

// ── Edit Dialogs ─────────────────────────────────────────────────────────────

class _ExerciseEditDialog extends StatefulWidget {
  final Map<String, dynamic> exercise;
  const _ExerciseEditDialog({required this.exercise});

  @override
  State<_ExerciseEditDialog> createState() => _ExerciseEditDialogState();
}

class _ExerciseEditDialogState extends State<_ExerciseEditDialog> {
  late final TextEditingController _promptBn;
  late final TextEditingController _promptAr;
  late final TextEditingController _grammarNote;

  @override
  void initState() {
    super.initState();
    _promptBn = TextEditingController(text: widget.exercise['prompt_bn'] as String? ?? '');
    _promptAr = TextEditingController(text: widget.exercise['prompt_ar'] as String? ?? '');
    _grammarNote = TextEditingController(text: widget.exercise['grammar_note_bn'] as String? ?? '');
  }

  @override
  void dispose() {
    _promptBn.dispose();
    _promptAr.dispose();
    _grammarNote.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.exercise['type'] as String? ?? '';
    return AlertDialog(
      title: Text('Edit: ${type.replaceAll('_', ' ')}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _promptBn,
              decoration: const InputDecoration(
                labelText: 'Prompt (Bangla)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Directionality(
              textDirection: TextDirection.rtl,
              child: TextField(
                controller: _promptAr,
                decoration: const InputDecoration(
                  labelText: 'Prompt (Arabic)',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 18, height: 1.6),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _grammarNote,
              decoration: const InputDecoration(
                labelText: 'Grammar Note (Bangla)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল')),
        FilledButton(
          onPressed: () => Navigator.pop(context, {
            'prompt_bn': _promptBn.text.trim(),
            'prompt_ar': _promptAr.text.trim().isEmpty ? null : _promptAr.text.trim(),
            'grammar_note_bn': _grammarNote.text.trim().isEmpty ? null : _grammarNote.text.trim(),
          }),
          child: const Text('সংরক্ষণ'),
        ),
      ],
    );
  }
}

class _VocabEditDialog extends StatefulWidget {
  final Map<String, dynamic> vocab;
  const _VocabEditDialog({required this.vocab});

  @override
  State<_VocabEditDialog> createState() => _VocabEditDialogState();
}

class _VocabEditDialogState extends State<_VocabEditDialog> {
  late final TextEditingController _arabic;
  late final TextEditingController _translit;
  late final TextEditingController _meaningBn;
  late final TextEditingController _grammarNote;

  @override
  void initState() {
    super.initState();
    _arabic = TextEditingController(text: widget.vocab['arabic'] as String? ?? '');
    _translit = TextEditingController(text: widget.vocab['transliteration'] as String? ?? '');
    _meaningBn = TextEditingController(text: widget.vocab['meaning_bn'] as String? ?? '');
    _grammarNote = TextEditingController(text: widget.vocab['grammar_note_bn'] as String? ?? '');
  }

  @override
  void dispose() {
    _arabic.dispose();
    _translit.dispose();
    _meaningBn.dispose();
    _grammarNote.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Vocabulary সম্পাদনা'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: TextField(
                controller: _arabic,
                decoration: const InputDecoration(
                  labelText: 'Arabic (with harakat)',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 20, height: 1.6),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _translit,
              decoration: const InputDecoration(
                labelText: 'Transliteration',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _meaningBn,
              decoration: const InputDecoration(
                labelText: 'Meaning (Bangla)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _grammarNote,
              decoration: const InputDecoration(
                labelText: 'Grammar Note (Bangla)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল')),
        FilledButton(
          onPressed: () => Navigator.pop(context, {
            'arabic': _arabic.text.trim(),
            'transliteration': _translit.text.trim().isEmpty ? null : _translit.text.trim(),
            'meaning_bn': _meaningBn.text.trim(),
            'grammar_note_bn': _grammarNote.text.trim().isEmpty ? null : _grammarNote.text.trim(),
          }),
          child: const Text('সংরক্ষণ'),
        ),
      ],
    );
  }
}

// ── Preview ───────────────────────────────────────────────────────────────────

class _PreviewLessonCard extends StatelessWidget {
  final Map<String, dynamic> lesson;
  final List<Map<String, dynamic>> exercises;
  final List<Map<String, dynamic>> vocabulary;
  const _PreviewLessonCard({
    required this.lesson,
    required this.exercises,
    required this.vocabulary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lesson['title_bn'] as String? ?? '',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (vocabulary.isNotEmpty) ...[
              Text('শব্দভাণ্ডার:',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.primary)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: vocabulary.map((v) {
                  return Chip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            v['arabic'] as String? ?? '',
                            style: const TextStyle(
                                fontFamily: 'NotoNaskhArabic',
                                fontSize: 14,
                                height: 1.4),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(' — ${v['meaning_bn'] ?? ''}',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
            Text('অনুশীলন (${exercises.length}টি):',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(height: 4),
            ...exercises.map((ex) {
              final type = (ex['type'] as String? ?? '')
                  .replaceAll('_', ' ');
              final prompt = ex['prompt_bn'] as String? ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(type,
                          style: TextStyle(
                              fontSize: 9,
                              color:
                                  theme.colorScheme.onSecondaryContainer)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        prompt.isEmpty ? '(no prompt)' : prompt,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Exam section (shown below regular lessons) ────────────────────────────────

class _ExamSection extends StatelessWidget {
  final Map<String, dynamic>? examLesson;
  final int questionCount;
  final bool generating;
  final VoidCallback onGenerate;
  final VoidCallback? onViewQuestions;

  const _ExamSection({
    required this.examLesson,
    required this.questionCount,
    required this.generating,
    required this.onGenerate,
    this.onViewQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = Colors.amber.shade600;
    final hasExam = examLesson != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasExam
            ? Colors.amber.withValues(alpha: 0.08)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasExam
              ? Colors.amber.withValues(alpha: 0.4)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasExam ? Icons.emoji_events_rounded : Icons.emoji_events_outlined,
                color: hasExam ? gold : theme.colorScheme.onSurfaceVariant,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'মডিউল পরীক্ষা',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: hasExam ? gold : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasExam
                          ? '$questionCount টি প্রশ্ন সংরক্ষিত • প্রতি পরীক্ষায় ১০-১২টি র‍্যান্ডম'
                          : 'এখনও তৈরি হয়নি — "Generate Exam 🏆" চালু করুন',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: hasExam
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (generating)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton.icon(
                  icon: Icon(Icons.refresh_rounded, size: 16, color: gold),
                  label: Text(
                    hasExam ? 'পুনরায়' : 'তৈরি করুন',
                    style: TextStyle(color: gold, fontSize: 13),
                  ),
                  onPressed: onGenerate,
                ),
            ],
          ),
          if (onViewQuestions != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(Icons.list_alt_rounded, size: 16, color: gold),
                label: Text(
                  'প্রশ্নগুলো দেখুন ($questionCount টি)',
                  style: TextStyle(color: gold, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: gold.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onPressed: onViewQuestions,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Exam questions preview dialog ─────────────────────────────────────────────

class _ExamQuestionsPreviewDialog extends StatelessWidget {
  final String unitTitle;
  final List<Map<String, dynamic>> questions;

  const _ExamQuestionsPreviewDialog({
    required this.unitTitle,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Group by type for summary
    final typeCounts = <String, int>{};
    for (final q in questions) {
      final t = q['type'] as String? ?? 'unknown';
      typeCounts[t] = (typeCounts[t] ?? 0) + 1;
    }

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      color: AppColors.gold, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('পরীক্ষার প্রশ্ন ব্যাংক',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text(unitTitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Type summary chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: typeCounts.entries.map((e) {
                  return Chip(
                    label: Text('${e.key.replaceAll('_', ' ')}: ${e.value}',
                        style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    backgroundColor:
                        theme.colorScheme.secondaryContainer,
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 16),
            // Question list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: questions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final q = questions[i];
                  final type = q['type'] as String? ?? '';
                  final promptBn = q['prompt_bn'] as String? ?? '';
                  final promptAr = q['prompt_ar'] as String? ?? '';
                  final grammarNote = q['grammar_note_bn'] as String? ?? '';
                  final difficulty = q['difficulty'] as int? ?? 1;
                  final answer = q['correct_answer'];

                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${i + 1}. ${type.replaceAll('_', ' ')}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: List.generate(
                                3,
                                (s) => Icon(
                                  Icons.star_rounded,
                                  size: 12,
                                  color: s < difficulty
                                      ? AppColors.gold
                                      : theme.colorScheme.outline
                                          .withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (promptBn.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(promptBn,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w500)),
                        ],
                        if (promptAr.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              promptAr,
                              style: const TextStyle(
                                fontFamily: 'NotoNaskhArabic',
                                fontSize: 16,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                        if (answer != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _summariseAnswer(type, answer),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                        if (grammarNote.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            grammarNote,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
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

  String _summariseAnswer(String type, dynamic answer) {
    if (answer is! Map) return '';
    try {
      switch (type) {
        case 'multiple_choice':
          final opts = answer['options'] as List?;
          final idx = answer['correct_index'] as int? ?? 0;
          if (opts != null && idx < opts.length) {
            return '✓ ${opts[idx]}';
          }
          return '';
        case 'true_false':
          return '✓ ${answer['is_true'] == true ? 'সত্য' : 'মিথ্যা'}';
        case 'fill_in_blank':
          return '✓ ${answer['answer'] ?? ''}';
        case 'tap_to_build':
          final words = answer['words_ar'] as List?;
          return words != null ? '✓ ${words.join(' ')}' : '';
        default:
          return '';
      }
    } catch (_) {
      return '';
    }
  }
}
