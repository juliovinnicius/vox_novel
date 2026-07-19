import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/presentation/cubit/narration_cubit.dart';
import 'package:vox_novel/features/narration/presentation/cubit/narration_state.dart';
import 'package:vox_novel/features/narration/presentation/widgets/narration_player_bar.dart';
import 'package:vox_novel/features/narration/presentation/widgets/narration_settings_sheet.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';

typedef ReaderNarrationBuilder =
    Widget Function(BuildContext context, Widget playerBar);

class ReaderNarrationHost extends StatefulWidget {
  const ReaderNarrationHost({
    required this.content,
    required this.cubit,
    required this.onNarrationFocus,
    required this.builder,
    this.activation,
    this.closeCubit,
    super.key,
  });

  final ReaderBookContent content;
  final NarrationCubit cubit;
  final void Function(String chapterId, String blockId) onNarrationFocus;
  final ReaderNarrationBuilder builder;
  final Future<void>? activation;
  final Future<void> Function(NarrationCubit cubit)? closeCubit;

  @override
  State<ReaderNarrationHost> createState() => _ReaderNarrationHostState();
}

class _ReaderNarrationHostState extends State<ReaderNarrationHost>
    with WidgetsBindingObserver {
  Future<void> _lifecycleTail = Future.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_activate());
  }

  Future<void> _activate() async {
    await widget.activation;
    if (mounted) await widget.cubit.load(widget.content);
  }

  @override
  void didUpdateWidget(covariant ReaderNarrationHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content.book.activeContentRunId !=
        widget.content.book.activeContentRunId) {
      unawaited(widget.cubit.reloadContent(widget.content));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.inactive &&
        state != AppLifecycleState.paused &&
        state != AppLifecycleState.detached) {
      return;
    }
    final pause = widget.cubit.onAppLifecyclePause();
    _lifecycleTail = Future.wait([_lifecycleTail, pause]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_close());
    super.dispose();
  }

  Future<void> _close() async {
    await _lifecycleTail;
    await (widget.closeCubit?.call(widget.cubit) ?? widget.cubit.close());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: BlocListener<NarrationCubit, NarrationState>(
        listenWhen: (previous, current) =>
            current.status == NarrationStatus.playing &&
            (previous.status != NarrationStatus.playing ||
                previous.chapterId != current.chapterId ||
                previous.blockId != current.blockId),
        listener: (context, state) {
          final chapterId = state.chapterId;
          final blockId = state.blockId;
          if (chapterId != null && blockId != null) {
            widget.onNarrationFocus(chapterId, blockId);
          }
        },
        child: BlocBuilder<NarrationCubit, NarrationState>(
          builder: (context, state) => widget.builder(
            context,
            NarrationPlayerBar(
              state: state,
              onPlay: () => unawaited(widget.cubit.play()),
              onPause: () => unawaited(widget.cubit.pause()),
              onPrevious: () => unawaited(widget.cubit.previous()),
              onNext: () => unawaited(widget.cubit.next()),
              onSettings: () => _showSettings(context),
              onRetry: () => unawaited(widget.cubit.retryInitialization()),
            ),
          ),
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: widget.cubit,
        child: BlocBuilder<NarrationCubit, NarrationState>(
          builder: (context, state) => NarrationSettingsSheet(
            state: state,
            onVoiceSelected: (voice) =>
                unawaited(widget.cubit.selectVoice(voice)),
            onVoicePreview: (voice) =>
                unawaited(widget.cubit.previewVoice(voice)),
            onBookOverrideChanged: (enabled) => unawaited(
              enabled
                  ? widget.cubit.enableBookOverride()
                  : widget.cubit.removeBookOverride(),
            ),
            onRateChanged: (rate) => unawaited(widget.cubit.setRate(rate)),
          ),
        ),
      ),
    );
  }
}
