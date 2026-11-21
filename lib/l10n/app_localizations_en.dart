// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsAppearanceTitle => 'Appearance';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsStartScreenTitle => 'Start screen';

  @override
  String get settingsStartScreenSubtitle =>
      'The section you see when you open the app';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsDefaultAlertTime => 'Same-day alert';

  @override
  String get settingsDefaultAlertTimeSubtitle =>
      'For all-day events, birthdays and name days; also the time offered for task due dates';

  @override
  String get settingsDayBeforeAlertTime => 'Day-before alert';

  @override
  String get settingsDayBeforeAlertTimeSubtitle =>
      'For all-day events, birthdays and name days';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get changelog_dialog_title => 'What\'s new';

  @override
  String get changelog_dialog_close => 'Close';

  @override
  String get changelog_section_added => 'New';

  @override
  String get changelog_section_improved => 'Improvements';

  @override
  String get changelog_section_fixed => 'Fixes';

  @override
  String get changelog_section_security => 'Security';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonPassword => 'Password';

  @override
  String get commonGenericError => 'Something went wrong. Please try again.';

  @override
  String get loginTagline => 'Your digital notebook';

  @override
  String get loginTabSignIn => 'Sign in';

  @override
  String get loginTabRegister => 'Sign up';

  @override
  String get loginOr => 'or';

  @override
  String get loginContinueWithGoogle => 'Continue with Google';

  @override
  String get loginPrivacyNotice =>
      'By continuing, you confirm that you are at least 14 years old and have read the privacy policy.';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginSubmitSignIn => 'Sign in';

  @override
  String get loginConfirmPassword => 'Confirm password';

  @override
  String get loginSubmitRegister => 'Create account';

  @override
  String get loginShowPassword => 'Show password';

  @override
  String get loginHidePassword => 'Hide password';

  @override
  String get loginResetEmailSent => 'Password reset email sent.';

  @override
  String get loginResetTitle => 'Reset password';

  @override
  String get loginResetSend => 'Send';

  @override
  String get validationEmailEmpty => 'Enter your email.';

  @override
  String get validationEmailInvalid => 'Invalid email format.';

  @override
  String get validationPasswordEmpty => 'Enter your password.';

  @override
  String get validationPasswordTooShort => 'At least 6 characters.';

  @override
  String get validationPasswordMismatch => 'Passwords don\'t match.';

  @override
  String get authErrorUserNotFound => 'No account found with this email.';

  @override
  String get authErrorWrongPassword => 'Wrong password. Please try again.';

  @override
  String get authErrorInvalidCredential =>
      'Invalid credentials. Check your email and password.';

  @override
  String get authErrorEmailInUse =>
      'This email is already linked to an account.';

  @override
  String get authErrorWeakPassword =>
      'The password is too weak (at least 6 characters).';

  @override
  String get authErrorTooManyRequests => 'Too many attempts. Try again later.';

  @override
  String get authErrorNetwork => 'Network error. Check your connection.';

  @override
  String get authErrorUserMismatch =>
      'The chosen account is not the one you are signed in with.';

  @override
  String get authErrorRequiresRecentLogin =>
      'For security, sign out and sign in again before retrying.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Taskenda';

  @override
  String get onboardingWelcomeBody =>
      'Notes, tasks and calendar in one place, synced to your account and available on all your devices.';

  @override
  String get onboardingNotesTitle => 'Notes';

  @override
  String get onboardingNotesBody =>
      'Write notes with custom styles, Markdown, checklists and audio notes. Organize them with labels and link them together.';

  @override
  String get onboardingTasksTitle => 'Tasks';

  @override
  String get onboardingTasksBody =>
      'Create task lists with subtasks, dates and recurrences: add a time to get a notification. Swipe a task right to complete it.';

  @override
  String get onboardingCalendarTitle => 'Calendar';

  @override
  String get onboardingCalendarBody =>
      'Plan events with day, week, month, year and schedule views. Import and export your calendars in ICS format.';

  @override
  String get onboardingRemindersTitle => 'Notifications and backups';

  @override
  String get onboardingRemindersBody =>
      'Add a time to tasks and events to get a notification, or a reminder to notes. Export your notes and create manual or automatic backups from Settings.';

  @override
  String get bootErrorTitle => 'Unable to start Taskenda';

  @override
  String get bootErrorBody =>
      'Something went wrong during startup. Check your connection and try again.';

  @override
  String get unknownRouteTitle => 'Page not found';

  @override
  String get unknownRouteBody =>
      'The content you were looking for is not available.';

  @override
  String get unknownRouteHome => 'Back to home';

  @override
  String get commonClose => 'Close';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonUndo => 'Undo';

  @override
  String get commonHide => 'Hide';

  @override
  String get commonOk => 'OK';

  @override
  String get commonDone => 'Done';

  @override
  String get dateTimePickerAddTime => 'Add time';

  @override
  String get dateTimePickerRemoveTime => 'Remove time';

  @override
  String get commonPin => 'Pin';

  @override
  String get commonUnpin => 'Unpin';

  @override
  String get commonArchive => 'Archive';

  @override
  String get commonUnarchive => 'Unarchive';

  @override
  String get commonMoveToTrash => 'Move to trash';

  @override
  String get commonTrash => 'Trash';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonClearSearch => 'Clear search';

  @override
  String get commonUntitled => 'Untitled';

  @override
  String get commonBold => 'Bold';

  @override
  String get commonItalic => 'Italic';

  @override
  String get commonFont => 'Font';

  @override
  String get commonMoveEarlier => 'Move earlier';

  @override
  String get commonMoveLater => 'Move later';

  @override
  String get commonRemoveReminder => 'Remove reminder';

  @override
  String get commonSyncError =>
      'Sync error. Check your connection and try again.';

  @override
  String get commonLinkOpenFailed => 'Unable to open the link';

  @override
  String get appLogoLabel => 'Taskenda logo';

  @override
  String get navNotes => 'Notes';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navLabels => 'Labels';

  @override
  String get navArchive => 'Archive';

  @override
  String get navTrash => 'Trash';

  @override
  String get navSettings => 'Settings';

  @override
  String get navSignOut => 'Sign out';

  @override
  String get navExpandMenu => 'Expand menu';

  @override
  String get navCollapseMenu => 'Collapse menu';

  @override
  String get navOpenMenu => 'Open menu';

  @override
  String get syncChangeRejected =>
      'A change could not be synced and was undone.';

  @override
  String get syncPendingBanner =>
      'Changes not synced yet: they will be sent as soon as you are back online.';

  @override
  String get sortTitle => 'Sort by';

  @override
  String get sortCreatedDate => 'Date created';

  @override
  String get sortModifiedDate => 'Date modified';

  @override
  String get sortNewestFirst => 'Newest first';

  @override
  String get sortOldestFirst => 'Oldest first';

  @override
  String get homeSearchHint => 'Search notes...';

  @override
  String get homeSortTooltip => 'Sort notes';

  @override
  String get homeNewNote => 'New note';

  @override
  String get homeNoResults => 'No notes found';

  @override
  String get homeEmpty => 'No notes yet';

  @override
  String get homeCreateFirst => 'Create your first note';

  @override
  String get homePinnedSection => 'Pinned';

  @override
  String get homeOthersSection => 'Others';

  @override
  String get homeFabTask => 'Task';

  @override
  String get homeFabChecklist => 'Checklist';

  @override
  String get homeFabNote => 'Note';

  @override
  String get homeFabAudio => 'Audio';

  @override
  String get homeFabTemplate => 'Template';

  @override
  String get homeFabCloseMenu => 'Close quick actions menu';

  @override
  String get homeFabOpenMenu => 'New quick action';

  @override
  String get homeFabCloseTooltip => 'Close';

  @override
  String get homeFabOpenTooltip => 'New';

  @override
  String get noteArchived => 'Note archived';

  @override
  String get noteUnarchived => 'Note removed from archive';

  @override
  String get noteTrashed => 'Note moved to trash';

  @override
  String get noteOpenHint => 'Open note';

  @override
  String get noteReminderSetLabel => 'Reminder set';

  @override
  String get taskPinnedLabel => 'Pinned task';

  @override
  String noteChecklistMore(int count) {
    return '+$count more';
  }

  @override
  String get editorUndo => 'Undo';

  @override
  String get editorRedo => 'Redo';

  @override
  String get editorFormatHeading => 'Heading';

  @override
  String get editorFormatBulleted => 'Bulleted list';

  @override
  String get editorFormatNumbered => 'Numbered list';

  @override
  String get editorFormatCheckbox => 'Checkbox';

  @override
  String get editorInsertLink => 'Insert link';

  @override
  String get editorShare => 'Share';

  @override
  String get editorBackgroundColor => 'Background color';

  @override
  String get editorEditStyle => 'Edit style';

  @override
  String get editorReminder => 'Reminder';

  @override
  String get editorLinkNote => 'Link note';

  @override
  String get editorRecordAudio => 'Record audio';

  @override
  String get editorAddItem => 'Add item';

  @override
  String get editorDeleteNote => 'Delete note';

  @override
  String get editorDeleteConfirm => 'Move this note to the trash?';

  @override
  String get editorTitleHint => 'Title';

  @override
  String get editorContentHint => 'Note';

  @override
  String get editorItemHint => 'Item...';

  @override
  String get editorChooseBackground => 'Choose background color';

  @override
  String get editorReminderFailed => 'Unable to schedule the reminder.';

  @override
  String get editorReminderNotificationTitle => 'Note reminder';

  @override
  String get editorReminderNotificationBody =>
      'You have a reminder for this note';

  @override
  String get editorAudioSection => 'Audio';

  @override
  String get editorLinkedNotes => 'Linked notes';

  @override
  String get editorRecordingError =>
      'Unable to record audio. Check the microphone permission.';

  @override
  String get editorStopAndAttach => 'Stop and attach';

  @override
  String get editorLinkText => 'Text (optional)';

  @override
  String get editorLinkAddress => 'Address';

  @override
  String get editorLinkInvalid => 'Enter a valid address';

  @override
  String get editorLinkInsert => 'Insert';

  @override
  String get editorSearchNoteHint => 'Search note...';

  @override
  String get editorUntitledNote => 'Untitled note';

  @override
  String get styleTitle => 'Text style';

  @override
  String get styleSectionTitle => 'Title';

  @override
  String get styleSectionBody => 'Body';

  @override
  String styleSize(String size) {
    return 'Size: ${size}pt';
  }

  @override
  String get styleStrikethrough => 'Strikethrough';

  @override
  String get styleTextColor => 'Text color';

  @override
  String get styleTitleColor => 'Title color';

  @override
  String get styleResetTitle => 'Reset title style';

  @override
  String get templateChoose => 'Choose a template';

  @override
  String get templateSectionNotes => 'Notes';

  @override
  String get templateSectionChecklists => 'Checklists';

  @override
  String get templateMeetingName => 'Meeting notes';

  @override
  String get templateMeetingDescription =>
      'A structure for taking notes during a meeting';

  @override
  String get templateMeetingContent =>
      '## Meeting of [DATE]\n\n**Attendees:**\n- \n\n**Agenda:**\n1. \n\n**Topics discussed:**\n\n**Decisions made:**\n\n**Action items:**\n- \n\n**Next meeting:** ';

  @override
  String get templateJournalName => 'Daily journal';

  @override
  String get templateJournalDescription =>
      'Track your thoughts and goals for the day';

  @override
  String get templateJournalContent =>
      '## [DATE]\n\n**How I feel today:**\n\n**Three things I\'m grateful for:**\n1. \n2. \n3. \n\n**Today\'s goals:**\n\n**Reflections on the day:**\n';

  @override
  String get templateProjectName => 'Project plan';

  @override
  String get templateProjectDescription =>
      'Organize a project\'s goals, milestones and resources';

  @override
  String get templateProjectContent =>
      '## Project: [NAME]\n\n**Goal:**\n\n**Deadline:**\n\n**Milestones:**\n- [ ] \n- [ ] \n\n**Resources needed:**\n\n**Notes:**\n';

  @override
  String get templateShoppingName => 'Shopping list';

  @override
  String get templateShoppingDescription => 'A shopping list with checkboxes';

  @override
  String get templateShoppingItems => 'Fruit and vegetables\nMilk\nBread\nEggs';

  @override
  String get templateTravelName => 'Packing list';

  @override
  String get templateTravelDescription =>
      'Don\'t forget anything for your trip';

  @override
  String get templateTravelItems =>
      'Passport / Documents\nChargers\nClothes\nToiletries\nMedicines\nCash / Cards';

  @override
  String get templateIdeasName => 'Idea brainstorming';

  @override
  String get templateIdeasDescription => 'Free space to collect ideas';

  @override
  String get templateIdeasContent =>
      '## Idea: [TITLE]\n\n**Description:**\n\n**Pros:**\n- \n\n**Cons:**\n- \n\n**Next steps:**\n';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonShare => 'Share';

  @override
  String commonReminderScheduled(String date) {
    return 'Reminder: $date';
  }

  @override
  String get commonReminderRemoved => 'Reminder removed';

  @override
  String commonLastModified(String date) {
    return 'Last modified: $date';
  }

  @override
  String get tasksSearchHint => 'Search tasks...';

  @override
  String get tasksSortTooltip => 'Sort tasks';

  @override
  String get tasksNewTask => 'New task';

  @override
  String get tasksNewTaskHint => 'What do you need to do?';

  @override
  String get tasksNewList => 'New list';

  @override
  String get tasksListNameHint => 'List name';

  @override
  String get tasksCreate => 'Create';

  @override
  String get tasksDeleteList => 'Delete list';

  @override
  String tasksDeleteListConfirm(String name) {
    return 'Do you really want to delete the list \"$name\"?';
  }

  @override
  String get tasksTabAll => 'All';

  @override
  String get tasksTabStarred => 'Starred';

  @override
  String get tasksEmpty => 'No tasks found';

  @override
  String get tasksCompletedSection => 'Completed';

  @override
  String get tasksComplete => 'Complete';

  @override
  String get tasksReopen => 'Reopen';

  @override
  String get tasksCompleted => 'Task completed';

  @override
  String get tasksReopened => 'Task reopened';

  @override
  String get tasksTrashed => 'Task moved to trash';

  @override
  String get tasksUnarchived => 'Task removed from archive';

  @override
  String get tasksAddStar => 'Add to starred';

  @override
  String get tasksRemoveStar => 'Remove from starred';

  @override
  String get tasksMoveToList => 'Move to list';

  @override
  String get tasksDeleteTask => 'Delete task';

  @override
  String tasksDeleteTaskNamedConfirm(String title) {
    return 'Move \"$title\" to the trash?';
  }

  @override
  String get tasksDeleteTaskConfirm => 'Move this task to the trash?';

  @override
  String get tasksDeleteRecurringTitle => 'Delete recurring task';

  @override
  String get tasksDeleteThisOccurrence => 'This task';

  @override
  String get tasksDeleteAllOccurrences => 'This and all following tasks';

  @override
  String get tasksOccurrenceDeleted => 'Task deleted, moved to the next repeat';

  @override
  String get tasksMoveToListTitle => 'Move to a list';

  @override
  String get tasksAddDetails => 'Add details';

  @override
  String get tasksRemoveDueDate => 'Remove date';

  @override
  String get tasksNoList => 'No list';

  @override
  String get tasksUnknownList => 'Unknown';

  @override
  String get taskEditorTitle => 'Task';

  @override
  String get taskEditorUndo => 'Undo (Ctrl+Z)';

  @override
  String get taskEditorRedo => 'Redo (Ctrl+Y)';

  @override
  String get taskEditorUnpin => 'Unpin from top';

  @override
  String get taskEditorPin => 'Pin to top';

  @override
  String get taskEditorDueDate => 'Set date and time';

  @override
  String get taskEditorRecurrence => 'Set repeat';

  @override
  String get taskEditorRecurrenceTitle => 'Repeat';

  @override
  String get taskEditorTitleHint => 'Task title';

  @override
  String get taskEditorDescriptionHint => 'Description...';

  @override
  String taskEditorSubtasks(int completed, int total) {
    return 'Subtasks ($completed/$total)';
  }

  @override
  String get taskEditorAddSubtaskHint => 'Add subtask...';

  @override
  String get taskEditorReminderNotificationTitle => 'Task reminder';

  @override
  String get taskEditorReminderNotificationBody =>
      'You have a reminder for this task';

  @override
  String get recurrenceNone => 'None';

  @override
  String get recurrenceDaily => 'Daily';

  @override
  String get recurrenceWeekly => 'Weekly';

  @override
  String get recurrenceMonthly => 'Monthly';

  @override
  String get recurrenceYearly => 'Yearly';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRestore => 'Restore';

  @override
  String get commonUntitledParens => '(untitled)';

  @override
  String get commonTabNotes => 'Notes';

  @override
  String get commonTabTasks => 'Tasks';

  @override
  String get commonTabEvents => 'Events';

  @override
  String get commonToday => 'Today';

  @override
  String get commonTomorrow => 'Tomorrow';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String get tasksNoDateSection => 'No date';

  @override
  String get tasksNotificationTimeLabel => 'Notification time';

  @override
  String get tasksRecurringLabel => 'Recurring task';

  @override
  String get calendarSearchHint => 'Search events...';

  @override
  String get calendarChangeView => 'Change view';

  @override
  String get calendarViewDay => 'Day';

  @override
  String get calendarViewWeek => 'Week';

  @override
  String get calendarViewMonth => 'Month';

  @override
  String get calendarViewYear => 'Year';

  @override
  String get calendarViewSchedule => 'Schedule';

  @override
  String get calendarViewSevenDays => '7 days';

  @override
  String get calendarPreviousDay => 'Previous day';

  @override
  String get calendarNextDay => 'Next day';

  @override
  String get calendarPreviousMonth => 'Previous month';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String get calendarPreviousYear => 'Previous year';

  @override
  String get calendarNextYear => 'Next year';

  @override
  String get calendarNoEventsDay => 'No events for this day';

  @override
  String get calendarNoEventsScheduled => 'No upcoming events';

  @override
  String get calendarNoEventsFound => 'No events found';

  @override
  String get calendarAdd => 'Add';

  @override
  String get calendarAllDay => 'All day';

  @override
  String get calendarShowTasks => 'Show tasks';

  @override
  String get calendarHideTasks => 'Hide tasks';

  @override
  String get calendarAlerts => 'Alerts';

  @override
  String get calendarAlertDayBefore => 'The day before';

  @override
  String get calendarAlertSameDay => 'On the day';

  @override
  String get holidayNewYear => 'New Year\'s Day';

  @override
  String get holidayEpiphany => 'Epiphany';

  @override
  String get holidayValentinesDay => 'Valentine\'s Day';

  @override
  String get holidayWomensDay => 'International Women\'s Day';

  @override
  String get holidayFathersDay => 'Father\'s Day';

  @override
  String get holidayEaster => 'Easter Sunday';

  @override
  String get holidayEasterMonday => 'Easter Monday';

  @override
  String get holidayLiberationDay => 'Liberation Day';

  @override
  String get holidayLabourDay => 'Labour Day';

  @override
  String get holidayMothersDay => 'Mother\'s Day';

  @override
  String get holidayRepublicDay => 'Republic Day';

  @override
  String get holidayAssumption => 'Assumption Day';

  @override
  String get holidayStFrancis => 'St Francis of Assisi';

  @override
  String get holidayHalloween => 'Halloween';

  @override
  String get holidayAllSaints => 'All Saints\' Day';

  @override
  String get holidayImmaculateConception => 'Immaculate Conception';

  @override
  String get holidayChristmas => 'Christmas Day';

  @override
  String get holidayStStephen => 'St Stephen\'s Day';

  @override
  String get calendarHolidayPublic => 'National holiday';

  @override
  String get calendarHolidayObservance => 'Observance';

  @override
  String get settingsCalendarSection => 'Calendar';

  @override
  String get settingsShowHolidays => 'National holidays';

  @override
  String get settingsShowHolidaysSubtitle =>
      'New Year, Easter, Liberation Day, Christmas and the other Italian holidays';

  @override
  String get settingsShowObservances => 'Observances';

  @override
  String get settingsShowObservancesSubtitle =>
      'Mother\'s Day, Father\'s Day, Valentine\'s Day, Women\'s Day, Halloween';

  @override
  String get calendarAlert => 'Alert';

  @override
  String get eventAlertNone => 'No alert';

  @override
  String get eventAlertAtStart => 'At start time';

  @override
  String eventAlertMinutesBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes before',
      one: '1 minute before',
    );
    return '$_temp0';
  }

  @override
  String eventAlertHoursBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours before',
      one: '1 hour before',
    );
    return '$_temp0';
  }

  @override
  String eventAlertDaysBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days before',
      one: '1 day before',
    );
    return '$_temp0';
  }

  @override
  String get settingsEventAlertOffset => 'Event alert';

  @override
  String get settingsEventAlertOffsetSubtitle =>
      'Offered for new timed events and for imported ones without an alert';

  @override
  String calendarAlertAt(String time) {
    return 'At $time';
  }

  @override
  String calendarAlertBodyToday(String when) {
    return 'Today · $when';
  }

  @override
  String calendarAlertBodyTomorrow(String when) {
    return 'Tomorrow · $when';
  }

  @override
  String get calendarEndTime => 'End time';

  @override
  String get calendarNoEndTime => 'None';

  @override
  String get calendarRemoveEndTime => 'Remove end time';

  @override
  String get calendarBirthday => 'Birthday';

  @override
  String get calendarNameDay => 'Name day';

  @override
  String get calendarRecurrence => 'Repeat';

  @override
  String get calendarLocationHint => 'Add location';

  @override
  String get calendarLocationOpenMaps => 'Open in Maps';

  @override
  String get calendarColor => 'Color';

  @override
  String get calendarColorDefault => 'Default';

  @override
  String get calendarEventTitle => 'Event';

  @override
  String get calendarEntryTypeEvent => 'Event';

  @override
  String get calendarEntryTypeTask => 'Task';

  @override
  String get calendarDeleteEvent => 'Delete event';

  @override
  String get calendarDeleteEventConfirm => 'Move this event to the trash?';

  @override
  String get calendarEventTrashed => 'Event moved to trash';

  @override
  String get calendarEventUnarchived => 'Event removed from archive';

  @override
  String get calendarTitleHint => 'Title';

  @override
  String get calendarDescriptionHint => 'Description';

  @override
  String get calendarReminderNotificationTitle => 'Event reminder';

  @override
  String get eventRecurrenceNone => 'Does not repeat';

  @override
  String get eventRecurrenceDaily => 'Daily';

  @override
  String get eventRecurrenceWeekly => 'Weekly';

  @override
  String get eventRecurrenceMonthly => 'Monthly';

  @override
  String get eventRecurrenceYearly => 'Yearly';

  @override
  String recurrenceEveryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count days',
      one: 'Every day',
    );
    return '$_temp0';
  }

  @override
  String recurrenceEveryWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count weeks',
      one: 'Every week',
    );
    return '$_temp0';
  }

  @override
  String recurrenceEveryMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count months',
      one: 'Every month',
    );
    return '$_temp0';
  }

  @override
  String recurrenceEveryYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count years',
      one: 'Every year',
    );
    return '$_temp0';
  }

  @override
  String recurrenceUnitDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String recurrenceUnitWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'weeks',
      one: 'week',
    );
    return '$_temp0';
  }

  @override
  String recurrenceUnitMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'months',
      one: 'month',
    );
    return '$_temp0';
  }

  @override
  String recurrenceUnitYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'years',
      one: 'year',
    );
    return '$_temp0';
  }

  @override
  String recurrenceRuleDetail(String rule, String detail) {
    return '$rule $detail';
  }

  @override
  String recurrenceOnWeekdays(String days) {
    return 'on $days';
  }

  @override
  String recurrenceUntil(String rule, String date) {
    return '$rule, until $date';
  }

  @override
  String recurrenceMonthDay(int day) {
    return 'on day $day';
  }

  @override
  String recurrenceMonthWeekday(String ordinal, String weekday) {
    return 'on the $ordinal $weekday';
  }

  @override
  String recurrenceOrdinal(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'm1': 'first',
      'm2': 'second',
      'm3': 'third',
      'm4': 'fourth',
      'm5': 'fifth',
      'f1': 'first',
      'f2': 'second',
      'f3': 'third',
      'f4': 'fourth',
      'f5': 'fifth',
      'other': 'last',
    });
    return '$_temp0';
  }

  @override
  String recurrencePresetWeekly(String weekday) {
    return 'Every week on $weekday';
  }

  @override
  String get recurrencePresetWorkdays => 'Every weekday (Mon–Fri)';

  @override
  String recurrencePresetMonthlyDay(int day) {
    return 'Every month on day $day';
  }

  @override
  String recurrencePresetMonthlyWeekday(String ordinal, String weekday) {
    return 'Every month on the $ordinal $weekday';
  }

  @override
  String recurrencePresetYearly(String date) {
    return 'Every year on $date';
  }

  @override
  String get recurrenceCustom => 'Custom…';

  @override
  String get recurrenceCustomTitle => 'Custom recurrence';

  @override
  String get recurrenceRepeatEvery => 'Repeat every';

  @override
  String get recurrenceRepeatOn => 'Repeat on';

  @override
  String get recurrenceEnds => 'Ends';

  @override
  String get recurrenceEndsNever => 'Never';

  @override
  String get recurrenceEndsOn => 'On';

  @override
  String get recurrenceEndsAfter => 'After';

  @override
  String recurrenceOccurrences(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'occurrences',
      one: 'occurrence',
    );
    return '$_temp0';
  }

  @override
  String recurrenceExcludedDates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count excluded dates',
      one: '1 excluded date',
    );
    return '$_temp0';
  }

  @override
  String get recurrenceRestoreExcluded => 'Restore';

  @override
  String get calendarDeleteRecurringTitle => 'Delete recurring event';

  @override
  String get calendarDeleteThisOccurrence => 'This event';

  @override
  String get calendarDeleteWholeSeries => 'All events in the series';

  @override
  String get calendarOccurrenceDeleted => 'Event deleted';

  @override
  String settingsIcsApproximated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count recurrences were imported approximately: check them in the calendar.',
      one: '1 recurrence was imported approximately: check it in the calendar.',
    );
    return '$_temp0';
  }

  @override
  String get archiveEmptyNotes => 'No archived notes';

  @override
  String get archiveEmptyTasks => 'No archived tasks';

  @override
  String get archiveEmptyEvents => 'No archived events';

  @override
  String get trashEmptyAction => 'Empty';

  @override
  String get trashAutoDeleteInfo =>
      'Items are permanently deleted after 7 days.';

  @override
  String get trashEmptyTitle => 'Empty trash';

  @override
  String get trashEmptyConfirm =>
      'All items in the trash will be permanently deleted.';

  @override
  String get trashEmptyNotes => 'No notes in the trash';

  @override
  String get trashEmptyTasks => 'No tasks in the trash';

  @override
  String get trashEmptyEvents => 'No events in the trash';

  @override
  String get trashExpiresSoon => 'Expires soon (automatic deletion)';

  @override
  String get trashExpiresToday => 'Expires today';

  @override
  String trashExpiresInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Expires in $count days',
      one: 'Expires in 1 day',
    );
    return '$_temp0';
  }

  @override
  String get trashDeleteForever => 'Delete permanently';

  @override
  String get trashDeleteForeverConfirm =>
      'The note will be permanently deleted.';

  @override
  String get labelsNew => 'New label';

  @override
  String get labelsNameHint => 'Label name';

  @override
  String get labelsEmpty => 'No labels';

  @override
  String get labelsEmptyHint => 'Create a new label or add one from a note.';

  @override
  String get labelsRename => 'Rename';

  @override
  String get labelsRenameTitle => 'Rename label';

  @override
  String get labelsDeleteTitle => 'Delete label';

  @override
  String labelsDeleteConfirm(String tag) {
    return 'The label \"$tag\" will be removed from all notes.';
  }

  @override
  String labelsNoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
      zero: 'No notes',
    );
    return '$_temp0';
  }

  @override
  String get labelNotesEmpty => 'No notes with this label';

  @override
  String get editorLabels => 'Labels';

  @override
  String get editorLabelsSearchHint => 'Search or create a label...';

  @override
  String editorLabelsCreate(String name) {
    return 'Create \"$name\"';
  }

  @override
  String get editorLabelsEmpty => 'No labels: type a name to create one.';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsOverview => 'Overview';

  @override
  String get statsOpenTasks => 'Tasks to do';

  @override
  String get statsEventsThisWeek => 'Events this week';

  @override
  String get statsCreatedThisWeek => 'Created this week';

  @override
  String get statsOverdue => 'Overdue';

  @override
  String get statsDueToday => 'Today';

  @override
  String get statsDueThisWeek => 'By Sunday';

  @override
  String get statsNoDueDate => 'No due date';

  @override
  String get statsActivity => 'Activity';

  @override
  String get statsActivitySubtitle => 'Items created in the last 12 weeks';

  @override
  String get statsNoActivity => 'Nothing created in the last 12 weeks';

  @override
  String statsMostActiveDay(String day) {
    return 'Most active day: $day';
  }

  @override
  String statsItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get statsTopLabels => 'Most used labels';

  @override
  String get statsNoLabelsUsed => 'No labels in use';

  @override
  String get statsSummary => 'Summary';

  @override
  String get statsActive => 'Active';

  @override
  String get statsArchived => 'Archived';

  @override
  String get statsTrashed => 'Deleted';

  @override
  String get statsNoTasks => 'No tasks yet';

  @override
  String get statsTaskCompletion => 'Task completion';

  @override
  String get infoTitle => 'About Taskenda';

  @override
  String get infoTagline => 'Notes, tasks and reminders in one place';

  @override
  String get infoAboutTitle => 'What is Taskenda';

  @override
  String get infoFeaturesTitle => 'Features';

  @override
  String get infoFeatureNotesTitle => 'Notes';

  @override
  String get infoFeatureNotesText =>
      'Formatted text, checklists, voice notes and sharing with other users';

  @override
  String get infoFeatureTasksTitle => 'Tasks and calendar';

  @override
  String get infoFeatureTasksText => 'Plan your to-dos and events day by day';

  @override
  String get infoFeatureRemindersTitle => 'Notifications';

  @override
  String get infoFeatureRemindersText =>
      'Timely notifications and a Home screen widget';

  @override
  String get infoFeatureSyncTitle => 'Sync and backup';

  @override
  String get infoFeatureSyncText =>
      'Data on your account, backups and export to PDF, TXT, JSON, CSV and HTML';

  @override
  String get infoLinksTitle => 'Links';

  @override
  String get infoLinkSource => 'Source code';

  @override
  String get infoLinkDeveloper => 'GitHub profile';

  @override
  String get infoLinkContact => 'Contact the developer';

  @override
  String get infoLinkError => 'Couldn\'t open the link';

  @override
  String get infoLinkWebsite => 'Project page';

  @override
  String get infoLinkWebApp => 'Web version';

  @override
  String get infoShareApp => 'Share Taskenda';

  @override
  String infoShareText(String url) {
    return 'Try Taskenda, the app for notes, tasks and calendar: $url';
  }

  @override
  String infoMadeBy(String name) {
    return 'Made by $name';
  }

  @override
  String get infoGuideOpen => 'Introduction';

  @override
  String get infoChangelogTitle => 'What\'s new';

  @override
  String get infoLicensesTitle => 'Open source licenses';

  @override
  String get exportTitle => 'Export notes';

  @override
  String get exportDestinationTitle => 'Export';

  @override
  String get exportSaveToDevice => 'Save to device';

  @override
  String get exportSaveToDeviceSubtitle =>
      'Choose the folder: Downloads, Drive, SD card…';

  @override
  String get exportShareSubtitle => 'Send to Drive, email or another app';

  @override
  String exportFileDone(String format) {
    return '$format exported';
  }

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get exportIntro =>
      'Export all active notes (excluding those in the trash).';

  @override
  String get exportPdfSubtitle => 'Save the notes to a .pdf file';

  @override
  String get exportTxtSubtitle => 'Save the notes to a .txt file';

  @override
  String get exportJsonSubtitle => 'Save the notes to a .json file';

  @override
  String get exportCsvSubtitle => 'Save the notes to a .csv file';

  @override
  String get exportHtmlSubtitle => 'Save the notes to a .html file';

  @override
  String get exportDownload => 'Download';

  @override
  String get settingsBackupDataTitle => 'Backup and data';

  @override
  String get settingsBackupDataSubtitle =>
      'Automatic backup, export, import and deletion of your data';

  @override
  String get settingsBackupTitle => 'Backup';

  @override
  String get settingsAutoBackup => 'Automatic backup';

  @override
  String get settingsAutoBackupSubtitle => 'Save your data automatically';

  @override
  String get settingsBackupFrequency => 'Backup frequency';

  @override
  String get settingsViewBackups => 'View backups';

  @override
  String get settingsViewBackupsSubtitle => 'Manage saved backups';

  @override
  String get settingsExportCalendarJson => 'Export calendar JSON';

  @override
  String get settingsExportCalendarJsonSubtitle =>
      'Download the events as a .json file';

  @override
  String get settingsImportCalendarJson => 'Import calendar JSON';

  @override
  String get settingsImportCalendarJsonSubtitle =>
      'Restore the events from a .json file';

  @override
  String get settingsExportIcs => 'Export ICS calendar';

  @override
  String get settingsExportIcsSubtitle => 'Export all events to an .ics file';

  @override
  String get settingsImportIcs => 'Import from Google Calendar';

  @override
  String get settingsImportIcsSubtitle => 'Import events from an .ics file';

  @override
  String get settingsClearCalendar => 'Clear calendar events';

  @override
  String get settingsClearCalendarSubtitle =>
      'Removes all events from the calendar';

  @override
  String get settingsGlobalBackupTitle => 'Full backup';

  @override
  String get settingsExportFullBackup => 'Export full backup';

  @override
  String get settingsExportFullBackupSubtitle =>
      'Download a .json file with notes, tasks and events';

  @override
  String get settingsImportFullBackup => 'Import full backup';

  @override
  String get settingsImportFullBackupSubtitle =>
      'Restore data from a .json backup file';

  @override
  String get settingsClearAll => 'Clear all data';

  @override
  String get settingsClearAllSubtitle =>
      'Permanently delete notes, tasks and events';

  @override
  String get settingsAccountTitle => 'Account';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteAccountSubtitle =>
      'Permanently delete the account and all its data';

  @override
  String get settingsExportNotesSubtitle =>
      'Export all notes in several formats';

  @override
  String get settingsExportNotesJson => 'Export notes JSON';

  @override
  String get settingsExportNotesJsonSubtitle =>
      'Download the notes as a .json file';

  @override
  String get settingsImportNotesJson => 'Import notes JSON';

  @override
  String get settingsImportNotesJsonSubtitle =>
      'Restore the notes from a .json file';

  @override
  String get settingsClearNotes => 'Clear notes';

  @override
  String get settingsClearNotesSubtitle => 'Removes all notes';

  @override
  String get settingsLayout => 'Layout';

  @override
  String get settingsLayoutGrid => 'Grid';

  @override
  String get settingsLayoutList => 'List';

  @override
  String get settingsFabMenu => '+ button menu';

  @override
  String get settingsFabMenuOn =>
      'Choose between note, checklist, task, audio and template';

  @override
  String get settingsFabMenuOff => 'The + button creates a new note right away';

  @override
  String get settingsExportTasksJson => 'Export tasks JSON';

  @override
  String get settingsExportTasksJsonSubtitle =>
      'Download the tasks as a .json file';

  @override
  String get settingsImportTasksJson => 'Import tasks JSON';

  @override
  String get settingsImportTasksJsonSubtitle =>
      'Restore the tasks from a .json file';

  @override
  String get settingsClearTasks => 'Clear tasks';

  @override
  String get settingsClearTasksSubtitle => 'Removes all tasks';

  @override
  String get settingsShowCompleted => 'Show completed tasks';

  @override
  String get settingsShowCompletedSubtitle =>
      'Show the tasks marked as completed';

  @override
  String get settingsGroupByPriority => 'Group by priority';

  @override
  String get settingsGroupByPrioritySubtitle =>
      'Sort tasks by priority (starred at the top)';

  @override
  String get settingsRestoreBackup => 'Restore backup';

  @override
  String get settingsReplaceAllConfirm =>
      'Your current data (notes, tasks and events) will be replaced with the backup. Continue?';

  @override
  String get settingsRestoreSettingsToo => 'Also restore settings';

  @override
  String get settingsRestoreSettingsTooSubtitle =>
      'Theme, language, start screen, views and calendar, tasks and notes preferences';

  @override
  String get settingsBackupReadFailed => 'Unable to read the backup.';

  @override
  String get settingsBackupRestored => 'Backup restored successfully.';

  @override
  String get settingsNoBackups => 'No backups available';

  @override
  String get settingsBackupsAvailable => 'Available backups';

  @override
  String get settingsImport => 'Import';

  @override
  String get settingsBackupExported => 'Backup exported';

  @override
  String get settingsImportBackupTitle => 'Import backup';

  @override
  String get settingsBackupImported => 'Backup imported successfully.';

  @override
  String get settingsBackupWrongApp => 'This file is not a Taskenda backup.';

  @override
  String get settingsBackupTooNew =>
      'This backup was made by a newer version of Taskenda: update the app to import it.';

  @override
  String get settingsClearAllConfirm =>
      'All data (notes, tasks and events) will be permanently deleted. This cannot be undone. Continue?';

  @override
  String get settingsAllCleared => 'All data has been deleted.';

  @override
  String get settingsDeleteAll => 'Delete all';

  @override
  String get settingsNotesExported => 'Notes exported';

  @override
  String get settingsImportNotesTitle => 'Import notes';

  @override
  String get settingsReplaceNotesConfirm =>
      'Your current notes will be replaced with the ones in the file. Continue?';

  @override
  String get settingsNotesImported => 'Notes imported successfully.';

  @override
  String get settingsClearNotesConfirm =>
      'All notes will be permanently deleted. Continue?';

  @override
  String get settingsNotesCleared => 'All notes have been deleted.';

  @override
  String get settingsTasksExported => 'Tasks exported';

  @override
  String get settingsImportTasksTitle => 'Import tasks';

  @override
  String get settingsReplaceTasksConfirm =>
      'Your current tasks will be replaced with the ones in the file. Continue?';

  @override
  String get settingsTasksImported => 'Tasks imported successfully.';

  @override
  String get settingsClearTasksConfirm =>
      'All tasks will be permanently deleted. Continue?';

  @override
  String get settingsTasksCleared => 'All tasks have been deleted.';

  @override
  String get settingsCalendarExported => 'Calendar exported';

  @override
  String get settingsImportCalendarTitle => 'Import calendar';

  @override
  String get settingsReplaceCalendarConfirm =>
      'Your current events will be replaced with the ones in the file. Continue?';

  @override
  String get settingsCalendarImported => 'Calendar imported successfully.';

  @override
  String get settingsClearEventsTitle => 'Clear events';

  @override
  String get settingsClearCalendarConfirm =>
      'All calendar events will be permanently deleted. Continue?';

  @override
  String get settingsCalendarCleared => 'All events have been deleted.';

  @override
  String get settingsNoEventsToExport => 'No events to export.';

  @override
  String get settingsIcsExported => 'ICS calendar exported';

  @override
  String get settingsNoEventsInFile => 'No events found in the file.';

  @override
  String get settingsDeleteAccountConfirm =>
      'The account and all its data (notes, tasks and events) will be permanently deleted from all devices. This cannot be undone: if you want to keep your data, export a full backup first. Continue?';

  @override
  String get settingsConfirmPassword => 'Confirm your password';

  @override
  String get settingsDeleteAccountFailed =>
      'Unable to delete the account. Check your connection and try again.';

  @override
  String get settingsAccountDeleted => 'Account deleted.';

  @override
  String settingsImportError(String error) {
    return 'Import error: $error';
  }

  @override
  String settingsBackupsLoadError(String error) {
    return 'Error loading backups: $error';
  }

  @override
  String settingsIcsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events imported into the calendar.',
      one: '1 event imported into the calendar.',
    );
    return '$_temp0';
  }

  @override
  String infoVersion(String version) {
    return 'Version $version';
  }

  @override
  String get infoDescription =>
      'Taskenda brings together notes, checklists, tasks and calendar events, synced to your account and available on every device.';

  @override
  String statsCompletedOf(int completed, int total) {
    return 'Completed: $completed / $total';
  }

  @override
  String exportPdfError(String error) {
    return 'PDF error: $error';
  }

  @override
  String get exportEmptyNote => '(empty note)';

  @override
  String exportModified(String date) {
    return 'Modified: $date';
  }

  @override
  String exportLabels(String labels) {
    return 'Labels: $labels';
  }

  @override
  String get exportDateTimePattern => 'd MMM y \'at\' HH:mm';

  @override
  String get exportCsvHeader =>
      'id,title,content,type,labels,pinned,created,modified';

  @override
  String exportHtmlHeading(String date) {
    return 'Notes export – $date';
  }

  @override
  String get notificationChannelName => 'Reminders';

  @override
  String get notificationChannelDescription =>
      'Notifications for Taskenda reminders';

  @override
  String get notificationTargetNotFound => 'Reminder item not found';

  @override
  String get widgetNotesEmpty => 'No notes';

  @override
  String get widgetTasksEmpty => 'No tasks to do';

  @override
  String get widgetCalendarEmpty => 'Nothing planned in the next two weeks';

  @override
  String get infoPrivacyOpen => 'Privacy policy';

  @override
  String get privacyPolicyTitle => 'Privacy policy';

  @override
  String get privacyPolicyIntro =>
      'Taskenda is an app for notes, tasks and calendar. This policy explains which data it processes, why, and how you can control it. Taskenda shows no ads, uses no analytics or tracking tools, and does not sell or hand over your data.';

  @override
  String privacyPolicyLastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get privacyPolicyOnlineVersion => 'Online version';

  @override
  String get privacyPolicyOnlineVersionSubtitle => 'Read the policy on the web';

  @override
  String get policy_section_controller_title => '1. Data controller';

  @override
  String policy_section_controller_text(String name, String email) {
    return 'The data controller is $name, developer of Taskenda. For any privacy question or to exercise your rights you can write to $email.';
  }

  @override
  String get policy_section_data_title => '2. Data we collect';

  @override
  String get policy_section_data_text =>
      '• Account: the email address you sign up with; the password is handled by Firebase Authentication and is never visible to the developer. If you sign in with Google, Google shares your name, email, profile photo and Google account ID with Firebase. Firebase also records when the account was created and when you last signed in.\n• Content: notes (title, text, checklists, labels, colors and style, reminders, links between notes, edit history), tasks and lists (subtasks, due dates, recurrence, priority), calendar events (location included) and labels.\n• Audio notes: recordings stay on your device only; just the file name, duration and path are synced with the note.\n• Sharing: so that other users can share notes, tasks and events with you, your email and name are saved in a directory that can only be looked up by the exact email. When you share an item, the people you add see its content, your name and your email, and you see theirs; pins, archive, reminders, alerts and labels stay personal. To tell you when someone shares something with you, the app saves a push notification identifier for each device (Firebase Cloud Messaging token) and the app language; it is deleted when you sign out on that device.\n• On your device: app preferences (language, theme, layout, sorting, note and task options, intro guide and what\'s new already seen, backup settings), automatic backups, a copy of your data for offline use, scheduled reminders and the data shown by the Home screen widgets (titles and previews of notes, tasks and upcoming entries). On the web, preferences are saved in the browser.';

  @override
  String get policy_section_use_title => '3. How we use data';

  @override
  String get policy_section_use_text =>
      'Data is used only to make Taskenda work: signing in to your account, saving your content and syncing it across your devices, sending you the notifications and reminders you set and creating backups. Your email is used only to sign in and, if you ask, to send you a password reset link. No profiling, no ads, no analytics and no automatic crash reporting.';

  @override
  String get policy_section_storage_title => '4. Where it is stored';

  @override
  String get policy_section_storage_text =>
      'Account and content are stored on Google Firebase (Firebase Authentication and Cloud Firestore), services provided by Google. Content is stored on servers in the European Union, while Firebase Authentication may also process data outside the European Union: the transfer takes place with the safeguards provided by the Google Firebase terms. Data travels encrypted and the database security rules make sure only your account can read and change your content, plus the people you choose to share an item with. Sharing notifications are sent through Firebase Cloud Messaging, a Google service. The developer does not look at your content and does not share it with anyone.\n\nWhile you type the location of an event, the typed text, the app language and the country set on the device go through Taskenda\'s server (Firebase Cloud Functions) to Google\'s Places service to suggest places and addresses: nothing else is sent, neither your position nor your account data, and Google does not receive your IP address. If you tap the location to open it in Maps, the search is handed to the Google Maps app or website.';

  @override
  String get policy_section_device_title => '5. On-device processing';

  @override
  String get policy_section_device_text =>
      'Some features work only on your device and send nothing to the developer or to third parties:\n• recording and playing audio notes;\n• exporting notes to PDF, TXT, JSON, CSV and HTML, exporting and importing backups and calendars (ICS);\n• automatic backups, saved in a private app folder (at most the latest 30);\n• statistics, reminders and the Home screen widget.\nFiles you export or share go wherever you choose (for example a folder or another app).';

  @override
  String get policy_section_permissions_title => '6. Permissions';

  @override
  String get policy_section_permissions_text =>
      'On Android Taskenda uses these permissions:\n• Microphone: only to record audio notes, when you start a recording.\n• Notifications: to show you reminders and task and event notifications.\n• Alarms and exact reminders: to fire reminders at the time you set.\n• Run at startup: to schedule reminders again after the phone restarts.\n• Keep the device awake and vibration: to deliver reminders even in standby.\n• Foreground service: required by the Android component that runs background work, such as updating the Home screen widget.\n• Internet and network state: to sync data with Firebase and detect when you are offline.\nTaskenda does not access your location, contacts, camera, photos or phone files: you pick the files to import yourself from the system picker.';

  @override
  String get policy_section_retention_title => '7. Retention and deletion';

  @override
  String policy_section_retention_text(String email) {
    return 'Your data is kept as long as you keep your account. Items in the trash are permanently deleted after 7 days. You can delete your account and all your data from Settings > Account > Delete account: the account and the content on Firebase are deleted, including the notes, tasks and events you shared (which disappear for the collaborators too) and the notification identifiers, you are removed from the items others shared with you, your email leaves the directory used for sharing and, on this device, reminders and automatic backups are deleted too. Before that you can export everything from Settings > Backup and data > Full backup. Any residual copies in Google\'s systems are removed within the time frames set by Firebase. Signing out does not delete data; uninstalling the app removes the data saved on the device, audio notes included. You can also ask for deletion by writing to $email.';
  }

  @override
  String get policy_section_rights_title => '8. Your rights';

  @override
  String policy_section_rights_text(String email) {
    return 'Under the GDPR you have the right to:\n• access your data and export it (also directly from the app);\n• correct it;\n• erase it;\n• ask for information on how it is processed.\nTo exercise them write to $email. You also have the right to lodge a complaint with the supervisory authority of your country (in Italy, the Garante per la protezione dei dati personali).';
  }

  @override
  String get policy_section_children_title => '9. Children';

  @override
  String get policy_section_children_text =>
      'Taskenda is not intended for children under 14, the minimum age in Italy to consent to online services on their own. Below that age you may use it only with the consent of a parent or guardian. In countries that set a different age, the one set by local law applies.';

  @override
  String get policy_section_changes_title => '10. Changes';

  @override
  String get policy_section_changes_text =>
      'If this policy changes, the new version will be available in the app (App info > Privacy policy) and online, with the date of the last update.';

  @override
  String get shareCollaboratorsTitle => 'Collaborators';

  @override
  String get shareEmailHint => 'Email of a Taskenda user';

  @override
  String get shareAdd => 'Add';

  @override
  String get shareOwner => 'Owner';

  @override
  String shareYouSuffix(String name) {
    return '$name (you)';
  }

  @override
  String get shareRemoveTooltip => 'Remove collaborator';

  @override
  String get shareErrorNotFound =>
      'Nobody uses Taskenda with this email. Ask them to install the app and sign in at least once.';

  @override
  String get shareErrorSelf => 'You can\'t add yourself.';

  @override
  String get shareErrorAlreadyAdded => 'This person is already a collaborator.';

  @override
  String get sharePersonalInfo =>
      'Collaborators see and edit the title, text, checklist and colors. Pinning, archive, reminders, labels and trash stay personal. Audio notes and links to other notes are not shared.';

  @override
  String get shareLeave => 'Remove me from sharing';

  @override
  String get shareLeaveConfirmTitle => 'Leave this shared item?';

  @override
  String get shareLeaveConfirmMessage =>
      'You won\'t see it any more. The owner can add you again.';

  @override
  String get shareLeaveConfirm => 'Remove me';

  @override
  String get shareLeft => 'You left the shared item';

  @override
  String get shareSaveFirst =>
      'Write something in the note before adding collaborators';

  @override
  String get shareSharedLabel => 'Shared';

  @override
  String get shareNotificationChannelName => 'Shared notes';

  @override
  String get shareNotificationChannelDescription =>
      'Alerts when someone shares a note with you';

  @override
  String get shareTaskPersonalInfo =>
      'Collaborators see and edit the title, description, due date, recurrence, subtasks and completion. Star, pin, archive, list, labels and trash stay personal.';

  @override
  String get shareEventPersonalInfo =>
      'Collaborators see and edit the title, description, date and times, location, color and recurrence. Pin, archive, alerts, labels and trash stay personal.';

  @override
  String get navShared => 'Shared';

  @override
  String get sharedEmpty =>
      'Nothing shared. Open a note, task or event and add a collaborator by email.';

  @override
  String get sharedWithMeSection => 'Shared with me';

  @override
  String get sharedByMeSection => 'Shared by me';
}
