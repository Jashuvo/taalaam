import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio_service.dart';

class ArabicAudioButton extends ConsumerWidget {
  final String? audioUrl;
  final double iconSize;

  const ArabicAudioButton({this.audioUrl, this.iconSize = 24, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (audioUrl == null || audioUrl!.isEmpty) return const SizedBox.shrink();
    return IconButton(
      icon: Icon(Icons.volume_up_rounded, size: iconSize),
      color: Theme.of(context).colorScheme.primary,
      tooltip: 'শুনুন',
      onPressed: () => ref.read(audioServiceProvider).playUrl(audioUrl!),
    );
  }
}
