// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/l10n.dart';
import '../../models/calendar_model.dart';
import '../../models/note_model.dart';
import '../../models/task_model.dart';
import '../../providers/settings/data_actions.dart';
import '../../widgets/shared/error_feedback.dart';
import '../../widgets/shared/app_dialogs.dart';
import 'app_router.dart';

/// Text shared to Taskenda from another app's "Share" sheet (a link from
/// the browser, a message, a description...).
@immutable
class SharedText {
  const SharedText({this.subject = '', this.text = ''});

  /// From the map sent by `MainActivity.kt`, or null if there is no text.
  static SharedText? fromMap(Object? map) {
    if (map is! Map) return null;
    final shared = SharedText(
      subject: (map['subject'] as String? ?? '').trim(),
      text: (map['text'] as String? ?? '').trim(),
    );
    return shared.subject.isEmpty && shared.text.isEmpty ? null : shared;
  }

  /// Longest single line still used as a title instead of a body.
  static const maxTitleLength = 100;

  /// The sender's subject (e.g. a page title, with its link in [text]).
  final String subject;
  final String text;

  /// The subject; without one, a short single-line text.
  String get title {
    if (subject.isNotEmpty) return subject;
    return _isShortLine ? text : '';
  }

  /// The text, unless it already became the [title].
  String get body {
    if (subject.isNotEmpty) return text == subject ? '' : text;
    return _isShortLine ? '' : text;
  }

  bool get _isShortLine =>
      !text.contains('\n') && text.length <= maxTitleLength;

  @override
  bool operator ==(Object other) =>
      other is SharedText && other.subject == subject && other.text == text;

  @override
  int get hashCode => Object.hash(subject, text);
}

/// What shared text becomes.
enum SharedTextTarget { note, task, event }

/// Receives the text shared to Taskenda from other apps (Android "Share"
/// sheet, see `MainActivity.kt`), asks whether to make it a note, a task or
/// an event, and opens that editor filled in. A calendar file (.ics) shared
/// or opened with Taskenda has its events imported after a confirmation.
///
/// Wraps the signed-in home, under `MaterialApp`'s navigator, like
/// [HomeWidgetLaunchHandler]. A cold start's text is taken once per
/// process. Android only; on web it just returns [child].
class SharedTextLaunchHandler extends ConsumerStatefulWidget {
  const SharedTextLaunchHandler({super.key, required this.child});

  final Widget child;

  static const channel = MethodChannel('com.ndn21.taskenda/share');

  @visibleForTesting
  static bool initialShareHandled = false;

  @override
  ConsumerState<SharedTextLaunchHandler> createState() =>
      _SharedTextLaunchHandlerState();
}

class _SharedTextLaunchHandlerState
    extends ConsumerState<SharedTextLaunchHandler> {
  static bool get _enabled =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    if (!_enabled) return;
    // Text shared while the app is open (singleTop: onNewIntent).
    SharedTextLaunchHandler.channel.setMethodCallHandler((call) async {
      if (call.method == 'shared') _handleShare(call.arguments);
    });
    if (!SharedTextLaunchHandler.initialShareHandled) {
      SharedTextLaunchHandler.initialShareHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final map = await SharedTextLaunchHandler.channel
              .invokeMethod<Object?>('takeInitialShare');
          _handleShare(map);
        } on PlatformException {
          // No text to take.
        } on MissingPluginException {
          // Not running in MainActivity (tests).
        }
      });
    }
  }

  @override
  void dispose() {
    if (_enabled) SharedTextLaunchHandler.channel.setMethodCallHandler(null);
    super.dispose();
  }

  /// The map from `MainActivity.kt`: an .ics file's content or a text.
  void _handleShare(Object? map) {
    final ics = map is Map ? map['ics'] : null;
    if (ics is String) {
      _importCalendar(ics);
    } else {
      _handle(SharedText.fromMap(map));
    }
  }

  Future<void> _importCalendar(String ics) async {
    if (!mounted) return;
    final l10n = context.l10n;
    final actions = ref.read(dataActionsProvider);
    final preview = actions.icsPreview(ics);
    if (preview.count == 0) {
      _showSnack(l10n.settingsNoEventsInFile);
      return;
    }
    final name = preview.name;
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.sharedIcsTitle,
      message:
          name == null
              ? l10n.sharedIcsMessage(preview.count)
              : l10n.sharedIcsMessageNamed(preview.count, name),
      confirmLabel: l10n.sharedIcsImport,
    );
    if (!confirmed || !mounted) return;
    final result = actions.importIcs(ics);
    notifyOnError(result.saved, context);
    final imported = l10n.settingsIcsImported(result.count);
    _showSnack(
      result.approximated == 0
          ? imported
          : '$imported ${l10n.settingsIcsApproximated(result.approximated)}',
      seconds: result.approximated == 0 ? 3 : 8,
    );
  }

  void _showSnack(String message, {int seconds = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: seconds)),
    );
  }

  Future<void> _handle(SharedText? shared) async {
    if (shared == null || !mounted) return;
    final target = await showAppSheet<SharedTextTarget>(
      context,
      builder: (ctx) => _SharedTextTargetSheet(shared: shared),
    );
    if (target == null || !mounted) return;
    switch (target) {
      case SharedTextTarget.note:
        AppNav.openNote(
          context,
          NoteModel(
            type: NoteType.note,
            title: shared.title,
            content: shared.body,
          ),
        );
      case SharedTextTarget.task:
        AppNav.openTask(
          context,
          TaskModel(title: shared.title, description: shared.body),
        );
      case SharedTextTarget.event:
        final now = DateTime.now();
        AppNav.openEvent(
          context,
          CalendarEventModel(
            title: shared.title,
            description: shared.body,
            startTime: now,
            endTime: now,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// "Save to Taskenda as": a preview of the shared text and the three kinds.
class _SharedTextTargetSheet extends StatelessWidget {
  const _SharedTextTargetSheet({required this.shared});

  final SharedText shared;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final preview = shared.title.isNotEmpty ? shared.title : shared.body;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          title: Text(l10n.sharedTextTitle, style: theme.textTheme.titleMedium),
          subtitle: Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        const Divider(height: 1),
        for (final (target, icon, label) in [
          (SharedTextTarget.note, Icons.note_outlined, l10n.sharedTextAsNote),
          (SharedTextTarget.task, Icons.task_alt, l10n.calendarEntryTypeTask),
          (
            SharedTextTarget.event,
            Icons.event_outlined,
            l10n.calendarEntryTypeEvent,
          ),
        ])
          ListTile(
            leading: Icon(icon),
            title: Text(label),
            onTap: () => Navigator.pop(context, target),
          ),
      ],
    );
  }
}
