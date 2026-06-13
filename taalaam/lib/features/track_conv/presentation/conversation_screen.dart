import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';

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
    if (!_started) {
      return _ScenarioPicker(
        selected: _scenario,
        onSelect: (s) => setState(() => _scenario = s),
        onStart: _start,
      );
    }

    final scenarioLabel =
        _scenarios.firstWhere((s) => s.id == _scenario).titleBn;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? null : AppColors.cream,
      body: Column(
        children: [
          _ChatHeader(
            scenarioLabel: scenarioLabel,
            onBack: () => context.go('/home'),
            onReset: () => setState(() {
              _messages.clear();
              _started = false;
            }),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
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

/// `.chh` — teal gradient chat header with avatar (`.chav`), title and
/// subtitle, matching the demo's Muhadathah header.
class _ChatHeader extends StatelessWidget {
  final String scenarioLabel;
  final VoidCallback onBack;
  final VoidCallback onReset;
  const _ChatHeader({
    required this.scenarioLabel,
    required this.onBack,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 6, 12, 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.gradientConversational,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        boxShadow: AppShadows.pop,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const _ChatAvatar(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'উস্তায ইউসুফ',
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'AI কথোপকথন সঙ্গী · $scenarioLabel',
                  style: const TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 10.5,
                    color: Color(0xBFFFFFFF),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onReset,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('নতুন', style: TextStyle(fontFamily: 'HindSiliguri', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// `.chav` — 38px circular avatar with the Arabic letter ي and an online
/// indicator dot (`.chav i`).
class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0x2EFFFFFF),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              'ي',
              style: GoogleFonts.amiri(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),
          ),
          Positioned(
            bottom: -1,
            right: -1,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: const Color(0xFF5EDB8A),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.teal, width: 2),
              ),
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/home')),
        title: const Text('কথোপকথন অনুশীলন', style: TextStyle(fontFamily: 'HindSiliguri')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'পরিস্থিতি বেছে নিন',
              style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'AI একজন আরবিভাষী হিসেবে কথা বলবে। আপনি যা জানেন তা দিয়ে চেষ্টা করুন।',
              style: TextStyle(
                fontFamily: 'HindSiliguri',
                fontSize: 12.5,
                height: 1.4,
                color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.ink2,
              ),
            ),
            const SizedBox(height: 22),
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
                      duration: AppMotion.fast,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: AppRadius.lgBorder,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.gold
                              : (isDark ? AppColors.darkOutlineVariant : AppColors.line),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: AppShadows.card,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            s.icon,
                            size: 30,
                            color: isSelected
                                ? AppColors.goldDeep
                                : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.teal),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            s.titleBn,
                            style: TextStyle(
                              fontFamily: 'HindSiliguri',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.goldDeep
                                  : (isDark ? AppColors.darkOnSurface : AppColors.ink),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.subtitleBn,
                            style: const TextStyle(fontFamily: 'HindSiliguri', fontSize: 10.5, color: AppColors.ink2),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.gold, AppColors.goldDeep]),
                  borderRadius: AppRadius.mdBorder,
                  boxShadow: AppShadows.card,
                ),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
                  ),
                  icon: const Icon(Icons.chat_outlined, color: Colors.white),
                  label: const Text('শুরু করুন', style: TextStyle(fontFamily: 'HindSiliguri', fontWeight: FontWeight.w700, color: Colors.white)),
                  onPressed: onStart,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.bub` — chat bubble. `.bub.bot`/`.bub.me` for the two sides, plus a
/// `.bub.sys`-style gold pill for the AI's correction note.
class _MessageBubble extends StatelessWidget {
  final _Message msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = msg.isUser;

    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8),
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: isUser
                  ? AppColors.forestGreen
                  : (isDark ? AppColors.darkCard : Colors.white),
              border: isUser
                  ? null
                  : Border.all(color: isDark ? AppColors.darkOutlineVariant : AppColors.line),
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: isUser ? const Radius.circular(5) : null,
                bottomLeft: !isUser ? const Radius.circular(5) : null,
              ),
              boxShadow: AppShadows.card,
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
                      height: 1.6,
                      color: isUser ? AppColors.cream : (isDark ? AppColors.darkOnSurface : AppColors.ink),
                    ),
                  ),
                ),
                if (!isUser && msg.transliteration.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    msg.transliteration,
                    style: const TextStyle(
                      fontFamily: 'HindSiliguri',
                      fontSize: 10.5,
                      color: AppColors.ink2,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (msg.translation.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    msg.translation,
                    style: TextStyle(
                      fontFamily: 'HindSiliguri',
                      fontSize: 10.5,
                      color: isUser ? const Color(0xB3F5F0E8) : AppColors.ink2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (msg.correction != null)
          Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF3DE),
              border: Border.all(color: const Color(0xFFEAD9A8)),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tips_and_updates_outlined, size: 14, color: AppColors.goldDeep),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'সংশোধন: ${msg.correction}',
                    style: const TextStyle(fontFamily: 'HindSiliguri', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.goldDeep),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          border: Border.all(color: isDark ? AppColors.darkOutlineVariant : AppColors.line),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(5),
          ),
          boxShadow: AppShadows.card,
        ),
        child: Text('…',
            style: TextStyle(
                color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.ink2, fontSize: 20)),
      ),
    );
  }
}

/// `.chbar` — bottom input bar with a pill-shaped text field (`.fld`) and a
/// gold gradient send button (`.mic`).
class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool loading;
  final VoidCallback onSend;
  const _InputBar(
      {required this.ctrl, required this.loading, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkOutlineVariant : AppColors.line;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'আরবিতে লিখুন…',
                  hintTextDirection: TextDirection.ltr,
                  hintStyle: const TextStyle(fontFamily: 'HindSiliguri', fontSize: 12, color: Color(0xFFB9AF97)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(99),
                      borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(99),
                      borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(99),
                      borderSide: BorderSide(color: borderColor)),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 11),
                ),
                style: const TextStyle(
                    fontFamily: 'NotoNaskhArabic', fontSize: 18, height: 1.5),
                onSubmitted: loading ? null : (_) => onSend(),
                enabled: !loading,
              ),
            ),
            const SizedBox(width: 10),
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.gold, AppColors.goldDeep]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x8CA87B0A), offset: Offset(0, 6), blurRadius: 16, spreadRadius: -4),
                ],
              ),
              child: IconButton(
                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: loading ? null : onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
