import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _scenarios = [
  _Scenario('classroom', 'শ্রেণিকক্ষ', 'মিসরীয় শিক্ষকের সাথে', Icons.school_outlined),
  _Scenario('market', 'বাজার', 'মাদীনার বইয়ের দোকানে', Icons.store_outlined),
  _Scenario('mosque', 'মসজিদ', 'জুম\'আর পর ইমামের সাথে', Icons.mosque_outlined),
  _Scenario('hajj', 'হজ', 'মক্কায় গাইডের সাথে', Icons.location_on_outlined),
];

class _Scenario {
  final String id;
  final String titleBn;
  final String subtitleBn;
  final IconData icon;
  const _Scenario(this.id, this.titleBn, this.subtitleBn, this.icon);
}

class _Message {
  final bool isUser;
  final String arabic;
  final String transliteration;
  final String translation;
  final String? correction;
  _Message({
    required this.isUser,
    required this.arabic,
    this.transliteration = '',
    this.translation = '',
    this.correction,
  });
}

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  String _scenario = 'classroom';
  final _messages = <_Message>[];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _loading = false;
  bool _started = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _started = true;
      _loading = true;
    });
    await _send('السلام عليكم');
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _ctrl.clear();

    final userMsg = _Message(isUser: true, arabic: text);
    setState(() {
      _messages.add(userMsg);
      _loading = true;
    });
    _scrollToBottom();

    try {
      final history = _messages.map((m) => {
        'role': m.isUser ? 'user' : 'model',
        'content': m.arabic,
      }).toList();

      final result = await Supabase.instance.client.functions
          .invoke('conversation', body: {
        'messages': history,
        'scenario': _scenario,
      });

      final reply = result.data['reply'] as Map<String, dynamic>;
      setState(() {
        _messages.add(_Message(
          isUser: false,
          arabic: reply['arabic'] as String? ?? '',
          transliteration: reply['transliteration'] as String? ?? '',
          translation: reply['translation'] as String? ?? '',
          correction: reply['correction'] as String?,
        ));
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('ত্রুটি: $e')));
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_started) {
      return _ScenarioPicker(
        selected: _scenario,
        onSelect: (s) => setState(() => _scenario = s),
        onStart: _start,
      );
    }

    final scenarioLabel =
        _scenarios.firstWhere((s) => s.id == _scenario).titleBn;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/home')),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('আরবি কথোপকথন', style: TextStyle(fontSize: 15)),
            Text(scenarioLabel,
                style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              _messages.clear();
              _started = false;
            }),
            child: const Text('নতুন'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) {
                  return const _TypingBubble();
                }
                return _MessageBubble(msg: _messages[i]);
              },
            ),
          ),
          _InputBar(
            ctrl: _ctrl,
            loading: _loading,
            onSend: () => _send(_ctrl.text),
          ),
        ],
      ),
    );
  }
}

class _ScenarioPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onStart;
  const _ScenarioPicker({
    required this.selected,
    required this.onSelect,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/home')),
        title: const Text('কথোপকথন অনুশীলন'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'পরিস্থিতি বেছে নিন',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'AI একজন আরবিভাষী হিসেবে কথা বলবে। আপনি যা জানেন তা দিয়ে চেষ্টা করুন।',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: _scenarios.map((s) {
                  final isSelected = s.id == selected;
                  return GestureDetector(
                    onTap: () => onSelect(s.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(s.icon,
                              size: 32,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 8),
                          Text(s.titleBn,
                              style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : null)),
                          Text(s.subtitleBn,
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.chat_outlined),
              label: const Text('শুরু করুন'),
              onPressed: onStart,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _Message msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = msg.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                msg.arabic,
                style: TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 20,
                  height: 1.7,
                  color: isUser ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (!isUser && msg.transliteration.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                msg.transliteration,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic),
              ),
            ],
            if (!isUser && msg.translation.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                msg.translation,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            if (msg.correction != null) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tips_and_updates_outlined,
                        size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'সংশোধন: ${msg.correction}',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.brown),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
        ),
        child: Text('…',
            style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant, fontSize: 20)),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool loading;
  final VoidCallback onSend;
  const _InputBar(
      {required this.ctrl, required this.loading, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'আরবিতে লিখুন…',
                  hintTextDirection: TextDirection.ltr,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                style: const TextStyle(
                    fontFamily: 'NotoNaskhArabic', fontSize: 18, height: 1.5),
                onSubmitted: loading ? null : (_) => onSend(),
                enabled: !loading,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.send),
              onPressed: loading ? null : onSend,
            ),
          ],
        ),
      ),
    );
  }
}
