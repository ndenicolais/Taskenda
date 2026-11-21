// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
// NoteEditorScreen now only handles Notes and Checklists
import '../../l10n/l10n.dart';
import '../../models/audio_note.dart';
import '../../models/note_model.dart';
import '../../models/change_history.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/notes_undo_redo_provider.dart';
import '../../providers/settings/ui_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_font_sizes.dart';
import '../../theme/app_spacing.dart';
import '../../utils/audio_service.dart';
import '../../utils/link_utils.dart';
import '../../utils/markdown_format.dart';
import '../../utils/picker_defaults.dart';
import '../../widgets/reminder_banner.dart';
import '../../widgets/shared/app_dialogs.dart';
import '../../widgets/shared/collaborators_section.dart';
import '../../widgets/shared/collaborators_sheet.dart';
import '../../widgets/shared/error_feedback.dart';
import '../../widgets/shared/note_hero.dart';
import '../../widgets/style_editor/color_picker_widget.dart';
import '../../widgets/style_editor/style_editor_sheet.dart';
import '../../widgets/shared/date_time_picker_dialog.dart';
import 'note_audio_notes_section.dart';
import 'note_audio_recorder_sheet.dart';
import 'note_checklist_editor.dart';
import 'note_editor_app_bar.dart';
import 'note_editor_bottom_bar.dart';
import 'note_editor_controller.dart';
import 'note_format_bar.dart';
import 'note_insert_link_sheet.dart';
import 'note_markdown_style.dart';
import 'note_labels_section.dart';
import 'note_labels_sheet.dart';
import 'note_link_sheet.dart';
import 'note_linked_notes_section.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({
    super.key,
    required this.note,
    this.autoOpenRecorder = false,
  });
  final NoteModel note;

  /// When true, immediately opens the audio recorder sheet once the screen
  /// is shown — used by the "Audio" quick-create action.
  final bool autoOpenRecorder;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late NoteEditorController _controller;
  late TextEditingController _contentController;
  late TextEditingController _titleController;
  late FocusNode _titleFocusNode;
  late FocusNode _contentFocusNode;
  bool _isApplyingUndoRedo = false;

  /// Whether the content shows as an editable field; otherwise it shows
  /// formatted and a tap switches back. Empty content is always editable.
  late bool _editingContent;
  String _lastTitle = '';
  String _lastContent = '';

  NoteModel get _note => _controller.note;

  @override
  void initState() {
    super.initState();
    _controller = NoteEditorController(ref: ref, initialNote: widget.note);
    _controller.addListener(_onControllerChanged);

    _titleController = TextEditingController(text: _note.title);
    _contentController = TextEditingController(text: _note.content);

    _lastTitle = _titleController.text;
    _lastContent = _contentController.text;
    _editingContent = _note.content.trim().isEmpty;

    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();

    _titleFocusNode.addListener(_onTitleFocusChanged);
    _contentFocusNode.addListener(_onContentFocusChanged);
    _titleController.addListener(_onTitleTextChanged);
    _contentController.addListener(_onContentTextChanged);

    if (widget.autoOpenRecorder) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openAudioRecorder());
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _titleController.removeListener(_onTitleTextChanged);
    _contentController.removeListener(_onContentTextChanged);
    _titleFocusNode.removeListener(_onTitleFocusChanged);
    _contentFocusNode.removeListener(_onContentFocusChanged);
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onTitleFocusChanged() {
    if (!_titleFocusNode.hasFocus && !_isApplyingUndoRedo) {
      _commitTitleChange(_titleController.text);
    }
  }

  void _onContentFocusChanged() {
    final focused = _contentFocusNode.hasFocus;
    if (!focused && !_isApplyingUndoRedo) {
      _commitContentChange(_contentController.text);
    }
    // Rebuilds for the formatting bar; leaving the field shows the
    // formatted content again.
    setState(() {
      if (!focused && _contentController.text.trim().isNotEmpty) {
        _editingContent = false;
      }
    });
  }

  /// Switches the content to the editable field and focuses it, with the
  /// cursor at [offset] (the end by default).
  void _startEditingContent([int? offset]) {
    setState(() => _editingContent = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final text = _contentController.text;
      _contentController.selection = TextSelection.collapsed(
        offset: (offset ?? text.length).clamp(0, text.length),
      );
      _contentFocusNode.requestFocus();
    });
  }

  /// Commits and saves a content edit made by the formatting bar or by
  /// ticking a box in the formatted view.
  void _onContentEdited() {
    _commitContentChange(_contentController.text);
    _save();
  }

  void _toggleTaskItem(int index) {
    final text = toggleTaskItem(_contentController.text, index);
    if (text == _contentController.text) return;
    setState(() => _contentController.text = text);
    _onContentEdited();
  }

  void _onTitleTextChanged() {
    if (_isApplyingUndoRedo) return;
    final current = _titleController.text;
    if (_endsWithWordBoundary(current)) {
      _commitTitleChange(current);
    }
  }

  void _onContentTextChanged() {
    if (_isApplyingUndoRedo) return;
    final current = _contentController.text;
    if (_endsWithWordBoundary(current)) {
      _commitContentChange(current);
    }
  }

  bool _endsWithWordBoundary(String text) {
    if (text.isEmpty) return false;
    final last = text[text.length - 1];
    return last == ' ' ||
        last == '\n' ||
        last == '.' ||
        last == ',' ||
        last == '!' ||
        last == '?' ||
        last == ';' ||
        last == ':';
  }

  void _commitTitleChange(String newTitle) {
    if (newTitle == _lastTitle) return;
    ref
        .read(noteChangeHistoryProvider(_note.id).notifier)
        .addChange(NoteTitleChange(oldTitle: _lastTitle, newTitle: newTitle));
    _lastTitle = newTitle;
  }

  void _commitContentChange(String newContent) {
    if (newContent == _lastContent) return;
    ref
        .read(noteChangeHistoryProvider(_note.id).notifier)
        .addChange(NoteTextChange(oldText: _lastContent, newText: newContent));
    _lastContent = newContent;
  }

  void _save() {
    notifyOnError(
      _controller.save(_titleController.text, _contentController.text),
      context,
    );
  }

  // ─── Share ────────────────────────────────────────────────────────────────

  void _shareNote() {
    final title = _note.title.trim();
    final content =
        _note.type == NoteType.checklist
            ? _note.checklistItems
                .map((i) => '${i.isChecked ? '☑' : '☐'} ${i.text}')
                .join('\n')
            : _note.content.trim();

    final text = [
      if (title.isNotEmpty) title,
      if (content.isNotEmpty) content,
    ].join('\n\n');

    if (text.isEmpty) return;
    SharePlus.instance.share(ShareParams(text: text));
  }

  // ─── Reminder ─────────────────────────────────────────────────────────────

  Future<void> _setReminder() async {
    final now = DateTime.now();
    final initial = _note.reminder ?? now;
    final picked = await showDateTimePickerDialog(
      context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialTime: initialPickerTime(initial, TimeOfDay.fromDateTime(initial)),
      defaultTime:
          (date) => initialPickerTime(date, TimeOfDay.fromDateTime(initial)),
      timeRequired: true,
    );
    if (picked == null || !mounted) return;

    final scheduled = picked.combined;

    _controller.updateNote((n) => n.copyWith(reminder: scheduled));
    _save();

    try {
      await _controller.scheduleReminderNotification(scheduled);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.editorReminderFailed)),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.commonReminderScheduled(
              DateFormat('dd MMM, HH:mm').format(scheduled),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _removeReminder() async {
    await _controller.cancelReminderNotification();
    _controller.updateNote((n) => n.copyWith(clearReminder: true));
    _save();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.commonReminderRemoved)),
      );
    }
  }

  // ─── Undo / Redo ──────────────────────────────────────────────────────────

  void _performUndo() {
    _isApplyingUndoRedo = true;
    final undoneNote = _controller.performUndo();
    if (undoneNote != null) {
      _titleController.text = undoneNote.title;
      _contentController.text = undoneNote.content;
      _lastTitle = undoneNote.title;
      _lastContent = undoneNote.content;
    }
    _isApplyingUndoRedo = false;
  }

  void _performRedo() {
    _isApplyingUndoRedo = true;
    final redoneNote = _controller.performRedo();
    if (redoneNote != null) {
      _titleController.text = redoneNote.title;
      _contentController.text = redoneNote.content;
      _lastTitle = redoneNote.title;
      _lastContent = redoneNote.content;
    }
    _isApplyingUndoRedo = false;
  }

  // ─── Linked notes ─────────────────────────────────────────────────────────

  void _showLinkNoteDialog() {
    final allNotes =
        ref.read(activeNotesProvider).where((n) => n.id != _note.id).toList();

    showAppSheet(
      context,
      isScrollControlled: true,
      builder:
          (ctx) => NoteLinkSheet(
            allNotes: allNotes,
            linkedIds: _note.linkedNoteIds,
            onToggle: (noteId) {
              _controller.updateNote((n) {
                final current = List<String>.from(n.linkedNoteIds);
                if (current.contains(noteId)) {
                  current.remove(noteId);
                } else {
                  current.add(noteId);
                }
                return n.copyWith(linkedNoteIds: current);
              });
              _save();
            },
          ),
    );
  }

  // ─── Collaborators ────────────────────────────────────────────────────────

  /// Saves the note first: a collaborator must find it on the server with
  /// its latest content, and a new note only exists once saved.
  Future<void> _showCollaboratorsSheet() async {
    final saving = _controller.save(
      _titleController.text,
      _contentController.text,
    );
    notifyOnError(saving, context);
    if (!ref.read(notesByIdProvider).containsKey(_note.id)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.shareSaveFirst)));
      return;
    }
    await showCollaboratorsSheet(
      context,
      kind: ShareKind.note,
      itemId: _note.id,
      onLeft: () {
        _controller.markLeft();
        if (mounted) Navigator.pop(context);
      },
    );
  }

  // ─── Labels ───────────────────────────────────────────────────────────────

  void _showLabelsSheet() {
    showAppSheet(
      context,
      isScrollControlled: true,
      builder:
          (_) => NoteLabelsSheet(
            allLabels: ref.read(allTagsProvider),
            selected: _note.tags,
            onToggle: (tag) {
              _controller.toggleTag(tag);
              _save();
            },
            onCreate: (name) {
              notifyOnError(_controller.createTag(name), context);
              _save();
            },
          ),
    );
  }

  // ─── Web links ────────────────────────────────────────────────────────────

  /// Inserts a Markdown link at the cursor (replacing the selection, which
  /// pre-fills the link text), or at the end when there is no cursor.
  Future<void> _insertLink() async {
    final value = _contentController.value;
    final sel = value.selection;
    final hasCursor = sel.isValid && _editingContent;
    final link = await showInsertLinkSheet(
      context,
      initialText: hasCursor ? sel.textInside(value.text) : '',
    );
    if (link == null || !mounted) return;

    final text = value.text;
    final start = hasCursor ? sel.start : text.length;
    final end = hasCursor ? sel.end : text.length;
    final newText = text.replaceRange(start, end, link);
    _contentController.text = newText;
    _commitContentChange(newText);
    _save();
    // The sheet took the focus: go back to editing after the link.
    _startEditingContent(start + link.length);
  }

  Future<void> _openLink(String? href) async {
    if (href == null) return;
    final opened = await openExternalLink(href);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.commonLinkOpenFailed)),
      );
    }
  }

  // ─── Style helpers ────────────────────────────────────────────────────────

  TextStyle _titleStyle(BuildContext context) {
    final s = _note.style;
    final effectiveFg = s.fontColor ?? Theme.of(context).colorScheme.onSurface;
    return TextStyle(
      color: s.titleFontColor ?? effectiveFg,
      fontFamily: s.titleFontFamily ?? s.fontFamily,
      fontSize: s.titleFontSize ?? (s.fontSize + 4),
      fontWeight: (s.titleIsBold ?? true) ? FontWeight.bold : FontWeight.normal,
      fontStyle:
          (s.titleIsItalic ?? false) ? FontStyle.italic : FontStyle.normal,
    );
  }

  TextStyle _contentStyle(BuildContext context) {
    final s = _note.style;
    final effectiveFg = s.fontColor ?? Theme.of(context).colorScheme.onSurface;
    return TextStyle(
      color: effectiveFg,
      fontFamily: s.fontFamily,
      fontSize: s.fontSize,
    );
  }

  /// The content rendered as Markdown with the note's style: a tap edits
  /// it (links open instead), task boxes tick in place.
  Widget _formattedContent(BuildContext context) {
    final style = _contentStyle(context);
    // Boxes are built in text order, so the n-th one maps to the n-th task.
    var box = 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _startEditingContent,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: MarkdownBody(
          data: _contentController.text,
          styleSheet: noteMarkdownStyleSheet(style),
          onTapLink: (_, href, _) => _openLink(href),
          checkboxBuilder: (checked) {
            final index = box++;
            return GestureDetector(
              onTap: () => _toggleTaskItem(index),
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: Icon(
                  checked ? Icons.check_box : Icons.check_box_outline_blank,
                  size: (style.fontSize ?? 14) * 1.3,
                  color: style.color,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openStyleEditor() {
    showAppSheet(
      context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => StyleEditorSheet(
            style: _note.style,
            onChanged: (newStyle) {
              _controller.updateNote((n) => n.copyWith(style: newStyle));
              _save();
            },
          ),
    );
  }

  void _openBackgroundPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showAppSheet(
      context,
      builder:
          (ctx) => Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.editorChooseBackground,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.lg),
                ColorPickerWidget(
                  current:
                      _note.style.backgroundColor ??
                      Theme.of(context).colorScheme.surface,
                  isDark: isDark,
                  onPick: (color) {
                    _controller.updateNote(
                      (n) => n.copyWith(
                        style: n.style.copyWith(backgroundColor: color),
                      ),
                    );
                    _save();
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
    );
  }

  // ─── Audio notes ──────────────────────────────────────────────────────────

  Future<void> _openAudioRecorder() async {
    final recorded = await showAppSheet<AudioNote>(
      context,
      isScrollControlled: true,
      builder: (_) => const AudioRecorderSheet(),
    );
    if (recorded == null) return;
    _controller.addAudioNote(recorded);
    _save();
  }

  void _deleteAudioNote(AudioNote audioNote) {
    _controller.removeAudioNote(audioNote.id);
    _save();
    AudioRecordingService().deleteAudioFile(audioNote.filepath);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: context.l10n.editorDeleteNote,
      message: context.l10n.editorDeleteConfirm,
      confirmLabel: context.l10n.commonDelete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final pending = _controller.delete();
    if (pending != null) {
      notifyWithUndo(
        pending,
        context,
        message: context.l10n.noteTrashed,
        onUndo: _controller.restore,
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = _note.style;
    final effectiveBg =
        s.backgroundColor ?? Theme.of(context).colorScheme.surface;
    final effectiveFg = s.fontColor ?? Theme.of(context).colorScheme.onSurface;
    // uiFg is contrast-aware for the background, independent of content text color
    final uiFg = AppColors.contrastingTextColor(effectiveBg);
    final hasReminder = _note.reminder != null;
    final uid = ref.watch(currentUidProvider);
    // Sharing fields from the provider: the controller's copy may predate a
    // change made in the collaborators sheet.
    final shared = ref.watch(noteByIdProvider(_note.id)) ?? _note;
    final isForeign = shared.isForeignTo(uid);
    final otherMembers = shared.membersExcept(uid);
    final linkedNotes =
        ref
            .watch(activeNotesProvider)
            .where((n) => _note.linkedNoteIds.contains(n.id))
            .toList();

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _save();
      },
      child: NoteHero(
        noteId: _note.id,
        color: effectiveBg,
        isPage: true,
        child: Scaffold(
          backgroundColor: effectiveBg,
          appBar: NoteEditorAppBar(
            note: _note,
            effectiveBg: effectiveBg,
            uiFg: uiFg,
            isSaving: _controller.isSaving,
            onUndo: _performUndo,
            onRedo: _performRedo,
            onLabels: _showLabelsSheet,
            onPin: () {
              _controller.updateNote((n) => n.copyWith(isPinned: !n.isPinned));
              _save();
            },
            onArchive: () {
              _controller.updateNote(
                (n) => n.copyWith(isArchived: !n.isArchived),
              );
              _save();
              Navigator.pop(context);
            },
            onShare: _shareNote,
            onCollaborators: _showCollaboratorsSheet,
          ),
          body: Column(
            children: [
              if (hasReminder)
                ReminderBanner(
                  reminder: _note.reminder!,
                  onTap: _setReminder,
                  onRemove: _removeReminder,
                ),
              // Campo Titolo
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                child: TextField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  focusNode: _titleFocusNode,
                  style: _titleStyle(context),
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: context.l10n.editorTitleHint,
                    hintStyle: _titleStyle(context).copyWith(
                      color: (s.titleFontColor ?? effectiveFg).withAlpha(80),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              // Area Contenuto (Nota o Checklist)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  children: [
                    if (_note.type == NoteType.checklist)
                      NoteChecklistEditor(
                        items: _note.checklistItems,
                        textStyle: _contentStyle(context),
                        onChanged: (items) {
                          _controller.updateNote(
                            (n) => n.copyWith(checklistItems: items),
                          );
                          _save();
                        },
                      )
                    else if (!_editingContent)
                      _formattedContent(context)
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: TextField(
                          controller: _contentController,
                          textCapitalization: TextCapitalization.sentences,
                          focusNode: _contentFocusNode,
                          style: _contentStyle(context),
                          maxLines: null,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            hintText: context.l10n.editorContentHint,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    if (_note.tags.isNotEmpty)
                      NoteLabelsSection(
                        tags: _note.tags,
                        onTap: _showLabelsSheet,
                      ),
                    if (otherMembers.isNotEmpty)
                      CollaboratorsSection(
                        members: otherMembers,
                        onTap: _showCollaboratorsSheet,
                      ),
                    if (_note.linkedNoteIds.isNotEmpty)
                      NoteLinkedNotesSection(linkedNotes: linkedNotes),
                    if (_note.audioNotes.isNotEmpty)
                      NoteAudioNotesSection(
                        audioNotes: _note.audioNotes,
                        onDelete: _deleteAudioNote,
                      ),
                  ],
                ),
              ),
              if (_note.type == NoteType.note && _contentFocusNode.hasFocus)
                NoteFormatBar(
                  controller: _contentController,
                  color: uiFg,
                  background: effectiveBg,
                  onChanged: _onContentEdited,
                  onInsertLink: _insertLink,
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: 6,
                  ),
                  child: Text(
                    context.l10n.commonLastModified(
                      DateFormat('dd MMM, HH:mm').format(_note.updatedAt),
                    ),
                    style: TextStyle(
                      fontSize: AppFontSizes.sm,
                      color: effectiveFg.withAlpha(150),
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: NoteEditorBottomBar(
            effectiveBg: effectiveBg,
            uiFg: uiFg,
            hasReminder: hasReminder,
            isChecklist: _note.type == NoteType.checklist,
            onBackgroundPicker: _openBackgroundPicker,
            onStyleEditor: _openStyleEditor,
            onReminder: _setReminder,
            onLinkNote: isForeign ? null : _showLinkNoteDialog,
            onRecordAudio: isForeign ? null : _openAudioRecorder,
            onAddChecklistItem: () {
              _controller.updateNote(
                (n) => n.copyWith(
                  checklistItems: [
                    ...n.checklistItems,
                    ChecklistItem(text: ''),
                  ],
                ),
              );
              _save();
            },
            onDelete: _confirmDelete,
          ),
        ),
      ),
    );
  }
}
