// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/calendar_model.dart';
import '../models/note_model.dart';
import '../models/sharing.dart';
import '../models/task_model.dart';
import 'auth_provider.dart';
import 'calendar_provider.dart';
import 'notes_provider.dart';
import 'tasks_provider.dart';

/// The shared items not in the trash (archived ones included), for the
/// Shared section: first those shared with the user, then those they share.
List<T> _shared<T extends Shareable<T>>(List<T> items, String uid) => [
  for (final i in items)
    if (i.deletedAt == null && i.isForeignTo(uid)) i,
  for (final i in items)
    if (i.deletedAt == null && i.isShared && !i.isForeignTo(uid)) i,
];

final sharedNotesProvider = Provider<List<NoteModel>>((ref) {
  return _shared(ref.watch(notesProvider), ref.watch(currentUidProvider));
});

final sharedTasksProvider = Provider<List<TaskModel>>((ref) {
  return _shared(ref.watch(tasksProvider), ref.watch(currentUidProvider));
});

final sharedEventsProvider = Provider<List<CalendarEventModel>>((ref) {
  return _shared(ref.watch(calendarProvider), ref.watch(currentUidProvider));
});
