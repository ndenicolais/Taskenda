// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get settingsAppearanceTitle => 'Aspetto';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Chiaro';

  @override
  String get settingsThemeDark => 'Scuro';

  @override
  String get settingsLanguageTitle => 'Lingua';

  @override
  String get settingsStartScreenTitle => 'Schermata iniziale';

  @override
  String get settingsStartScreenSubtitle =>
      'La sezione che vedi quando apri l\'app';

  @override
  String get settingsNotificationsTitle => 'Notifiche';

  @override
  String get settingsDefaultAlertTime => 'Avviso il giorno stesso';

  @override
  String get settingsDefaultAlertTimeSubtitle =>
      'Per eventi di tutto il giorno, compleanni e onomastici; è anche l\'orario proposto per le scadenze dei task';

  @override
  String get settingsDayBeforeAlertTime => 'Avviso il giorno prima';

  @override
  String get settingsDayBeforeAlertTimeSubtitle =>
      'Per eventi di tutto il giorno, compleanni e onomastici';

  @override
  String get settingsLanguageSystem => 'Sistema';

  @override
  String get changelog_dialog_title => 'Novità';

  @override
  String get changelog_dialog_close => 'Chiudi';

  @override
  String get changelog_section_added => 'Novità';

  @override
  String get changelog_section_improved => 'Miglioramenti';

  @override
  String get changelog_section_fixed => 'Correzioni';

  @override
  String get changelog_section_security => 'Sicurezza';

  @override
  String get commonCancel => 'Annulla';

  @override
  String get commonRetry => 'Riprova';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonPassword => 'Password';

  @override
  String get commonGenericError => 'Si è verificato un errore. Riprova.';

  @override
  String get loginTagline => 'Il tuo taccuino digitale';

  @override
  String get loginTabSignIn => 'Accedi';

  @override
  String get loginTabRegister => 'Registrati';

  @override
  String get loginOr => 'oppure';

  @override
  String get loginContinueWithGoogle => 'Continua con Google';

  @override
  String get loginPrivacyNotice =>
      'Continuando confermi di avere almeno 14 anni e di aver letto l\'informativa sulla privacy.';

  @override
  String get loginForgotPassword => 'Password dimenticata?';

  @override
  String get loginSubmitSignIn => 'Accedi';

  @override
  String get loginConfirmPassword => 'Conferma password';

  @override
  String get loginSubmitRegister => 'Crea account';

  @override
  String get loginShowPassword => 'Mostra password';

  @override
  String get loginHidePassword => 'Nascondi password';

  @override
  String get loginResetEmailSent => 'Email di reimpostazione inviata.';

  @override
  String get loginResetTitle => 'Reimposta password';

  @override
  String get loginResetSend => 'Invia';

  @override
  String get validationEmailEmpty => 'Inserisci la tua email.';

  @override
  String get validationEmailInvalid => 'Formato email non valido.';

  @override
  String get validationPasswordEmpty => 'Inserisci la password.';

  @override
  String get validationPasswordTooShort => 'Minimo 6 caratteri.';

  @override
  String get validationPasswordMismatch => 'Le password non coincidono.';

  @override
  String get authErrorUserNotFound =>
      'Nessun account trovato con questa email.';

  @override
  String get authErrorWrongPassword => 'Password errata. Riprova.';

  @override
  String get authErrorInvalidCredential =>
      'Credenziali non valide. Controlla email e password.';

  @override
  String get authErrorEmailInUse =>
      'Questa email è già associata a un account.';

  @override
  String get authErrorWeakPassword =>
      'La password è troppo debole (min. 6 caratteri).';

  @override
  String get authErrorTooManyRequests => 'Troppi tentativi. Riprova più tardi.';

  @override
  String get authErrorNetwork => 'Errore di rete. Controlla la connessione.';

  @override
  String get authErrorUserMismatch =>
      'L\'account scelto non è quello con cui hai effettuato l\'accesso.';

  @override
  String get authErrorRequiresRecentLogin =>
      'Per sicurezza, esci e accedi di nuovo prima di riprovare.';

  @override
  String get onboardingSkip => 'Salta';

  @override
  String get onboardingNext => 'Avanti';

  @override
  String get onboardingStart => 'Inizia';

  @override
  String get onboardingTagline => 'Calendario · Attività · Note';

  @override
  String get onboardingFeaturesTitle =>
      'Tutto quello che ti serve, in un unico posto';

  @override
  String get onboardingWelcomeTitle => 'Benvenuto in Taskenda';

  @override
  String get onboardingWelcomeBody =>
      'Note, attività e calendario in un unico posto, sincronizzati sul tuo account e disponibili su tutti i tuoi dispositivi.';

  @override
  String get onboardingNotesTitle => 'Note';

  @override
  String get onboardingNotesBody =>
      'Scrivi note con stili personalizzati, Markdown, liste di controllo e note audio. Organizzale con etichette e collegale tra loro.';

  @override
  String get onboardingTasksTitle => 'Attività';

  @override
  String get onboardingTasksBody =>
      'Crea elenchi di attività con sottoattività, date e ricorrenze: se aggiungi un orario ricevi una notifica. Scorri un\'attività verso destra per completarla.';

  @override
  String get onboardingCalendarTitle => 'Calendario';

  @override
  String get onboardingCalendarBody =>
      'Pianifica eventi con vista giorno, settimana, mese, anno e programma. Importa ed esporta i tuoi calendari in formato ICS.';

  @override
  String get onboardingRemindersTitle => 'Notifiche e backup';

  @override
  String get onboardingRemindersBody =>
      'Aggiungi un orario ad attività ed eventi per ricevere una notifica, o un promemoria alle note. Esporta le note e crea backup manuali o automatici dalle Impostazioni.';

  @override
  String get onboardingWebSyncTitle => 'Sincronizzazione e backup';

  @override
  String get onboardingWebSyncBody =>
      'I tuoi dati sono salvati sul tuo account e restano aggiornati su tutti i dispositivi. Dalle Impostazioni puoi esportare le note e scaricare un backup completo. Per le notifiche usa l\'app Android.';

  @override
  String get bootErrorTitle => 'Impossibile avviare Taskenda';

  @override
  String get bootErrorBody =>
      'Si è verificato un problema durante l\'avvio. Controlla la connessione e riprova.';

  @override
  String get unknownRouteTitle => 'Pagina non trovata';

  @override
  String get unknownRouteBody => 'Il contenuto che cercavi non è disponibile.';

  @override
  String get unknownRouteHome => 'Torna alla home';

  @override
  String get commonClose => 'Chiudi';

  @override
  String get commonDelete => 'Elimina';

  @override
  String get commonUndo => 'Annulla';

  @override
  String get commonHide => 'Nascondi';

  @override
  String get commonOk => 'OK';

  @override
  String get commonDone => 'Fine';

  @override
  String get dateTimePickerAddTime => 'Aggiungi orario';

  @override
  String get dateTimePickerRemoveTime => 'Rimuovi orario';

  @override
  String get commonPin => 'Fissa';

  @override
  String get commonUnpin => 'Rimuovi pin';

  @override
  String get commonArchive => 'Archivia';

  @override
  String get commonUnarchive => 'Ripristina';

  @override
  String get commonMoveToTrash => 'Sposta nel cestino';

  @override
  String get commonTrash => 'Cestino';

  @override
  String get commonLoading => 'Caricamento…';

  @override
  String get commonClearSearch => 'Cancella ricerca';

  @override
  String get commonUntitled => 'Senza titolo';

  @override
  String get commonBold => 'Grassetto';

  @override
  String get commonItalic => 'Corsivo';

  @override
  String get commonFont => 'Font';

  @override
  String get commonMoveEarlier => 'Sposta prima';

  @override
  String get commonMoveLater => 'Sposta dopo';

  @override
  String get commonRemoveReminder => 'Rimuovi promemoria';

  @override
  String get commonSyncError =>
      'Errore di sincronizzazione. Verifica la connessione e riprova.';

  @override
  String get commonLinkOpenFailed => 'Impossibile aprire il link';

  @override
  String get appLogoLabel => 'Logo Taskenda';

  @override
  String get navNotes => 'Note';

  @override
  String get navTasks => 'Task';

  @override
  String get navCalendar => 'Calendario';

  @override
  String get navLabels => 'Etichette';

  @override
  String get navArchive => 'Archivio';

  @override
  String get navTrash => 'Cestino';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get navSignOut => 'Esci';

  @override
  String get navExpandMenu => 'Espandi menu';

  @override
  String get navCollapseMenu => 'Comprimi menu';

  @override
  String get navOpenMenu => 'Apri menu';

  @override
  String get syncChangeRejected =>
      'Una modifica non è stata sincronizzata ed è stata annullata.';

  @override
  String get syncPendingBanner =>
      'Modifiche non ancora sincronizzate: verranno inviate appena torni online.';

  @override
  String get sortTitle => 'Ordina per';

  @override
  String get sortCreatedDate => 'Data di creazione';

  @override
  String get sortModifiedDate => 'Data di modifica';

  @override
  String get sortNewestFirst => 'Più recenti prima';

  @override
  String get sortOldestFirst => 'Più vecchie prima';

  @override
  String get homeSearchHint => 'Cerca nelle note...';

  @override
  String get homeSortTooltip => 'Ordina note';

  @override
  String get homeNewNote => 'Nuova nota';

  @override
  String get homeNoResults => 'Nessuna nota trovata';

  @override
  String get homeEmpty => 'Ancora nessuna nota';

  @override
  String get homeCreateFirst => 'Crea la prima nota';

  @override
  String get homePinnedSection => 'Fissate';

  @override
  String get homeOthersSection => 'Altre';

  @override
  String get homeFabTask => 'Task';

  @override
  String get homeFabChecklist => 'Lista';

  @override
  String get homeFabNote => 'Nota';

  @override
  String get homeFabAudio => 'Audio';

  @override
  String get homeFabTemplate => 'Modello';

  @override
  String get homeFabCloseMenu => 'Chiudi menu azioni rapide';

  @override
  String get homeFabOpenMenu => 'Nuova azione rapida';

  @override
  String get homeFabCloseTooltip => 'Chiudi';

  @override
  String get homeFabOpenTooltip => 'Nuovo';

  @override
  String get noteArchived => 'Nota archiviata';

  @override
  String get noteUnarchived => 'Nota rimossa dall\'archivio';

  @override
  String get noteTrashed => 'Nota spostata nel cestino';

  @override
  String get noteOpenHint => 'Apri nota';

  @override
  String get noteReminderSetLabel => 'Promemoria impostato';

  @override
  String get taskPinnedLabel => 'Task fissato';

  @override
  String noteChecklistMore(int count) {
    return '+$count altri';
  }

  @override
  String get editorUndo => 'Annulla';

  @override
  String get editorRedo => 'Ripeti';

  @override
  String get editorFormatHeading => 'Titoletto';

  @override
  String get editorFormatBulleted => 'Elenco puntato';

  @override
  String get editorFormatNumbered => 'Elenco numerato';

  @override
  String get editorFormatCheckbox => 'Casella di spunta';

  @override
  String get editorInsertLink => 'Inserisci link';

  @override
  String get editorShare => 'Condividi';

  @override
  String get editorBackgroundColor => 'Colore sfondo';

  @override
  String get editorEditStyle => 'Modifica stile';

  @override
  String get editorReminder => 'Promemoria';

  @override
  String get editorLinkNote => 'Collega nota';

  @override
  String get editorRecordAudio => 'Registra audio';

  @override
  String get editorAddItem => 'Aggiungi elemento';

  @override
  String get editorDeleteNote => 'Elimina nota';

  @override
  String get editorDeleteConfirm => 'Vuoi spostare questa nota nel cestino?';

  @override
  String get editorTitleHint => 'Titolo';

  @override
  String get editorContentHint => 'Nota';

  @override
  String get editorItemHint => 'Elemento...';

  @override
  String get editorChooseBackground => 'Scegli colore sfondo';

  @override
  String get editorReminderFailed => 'Impossibile pianificare il promemoria.';

  @override
  String get editorReminderNotificationTitle => 'Promemoria nota';

  @override
  String get editorReminderNotificationBody =>
      'Hai un promemoria per questa nota';

  @override
  String get editorAudioSection => 'Audio';

  @override
  String get editorLinkedNotes => 'Note collegate';

  @override
  String get editorRecordingError =>
      'Impossibile registrare l\'audio. Controlla il permesso del microfono.';

  @override
  String get editorStopAndAttach => 'Ferma e allega';

  @override
  String get editorLinkText => 'Testo (facoltativo)';

  @override
  String get editorLinkAddress => 'Indirizzo';

  @override
  String get editorLinkInvalid => 'Inserisci un indirizzo valido';

  @override
  String get editorLinkInsert => 'Inserisci';

  @override
  String get editorSearchNoteHint => 'Cerca nota...';

  @override
  String get editorUntitledNote => 'Nota senza titolo';

  @override
  String get styleTitle => 'Stile testo';

  @override
  String get styleSectionTitle => 'Titolo';

  @override
  String get styleSectionBody => 'Corpo';

  @override
  String styleSize(String size) {
    return 'Dimensione: ${size}pt';
  }

  @override
  String get styleStrikethrough => 'Sbarrato';

  @override
  String get styleTextColor => 'Colore testo';

  @override
  String get styleTitleColor => 'Colore titolo';

  @override
  String get styleResetTitle => 'Ripristina stile titolo';

  @override
  String get templateChoose => 'Scegli un modello';

  @override
  String get templateSectionNotes => 'Note';

  @override
  String get templateSectionChecklists => 'Checklist';

  @override
  String get templateMeetingName => 'Note riunione';

  @override
  String get templateMeetingDescription =>
      'Struttura per prendere appunti durante una riunione';

  @override
  String get templateMeetingContent =>
      '## Riunione del [DATA]\n\n**Partecipanti:**\n- \n\n**Ordine del giorno:**\n1. \n\n**Punti discussi:**\n\n**Decisioni prese:**\n\n**Azioni da fare:**\n- \n\n**Prossima riunione:** ';

  @override
  String get templateJournalName => 'Diario giornaliero';

  @override
  String get templateJournalDescription =>
      'Traccia i tuoi pensieri e obiettivi del giorno';

  @override
  String get templateJournalContent =>
      '## [DATA]\n\n**Come mi sento oggi:**\n\n**Tre cose per cui sono grato:**\n1. \n2. \n3. \n\n**Obiettivi di oggi:**\n\n**Riflessioni della giornata:**\n';

  @override
  String get templateProjectName => 'Piano di progetto';

  @override
  String get templateProjectDescription =>
      'Organizza obiettivi, milestones e risorse di un progetto';

  @override
  String get templateProjectContent =>
      '## Progetto: [NOME]\n\n**Obiettivo:**\n\n**Scadenza:**\n\n**Milestones:**\n- [ ] \n- [ ] \n\n**Risorse necessarie:**\n\n**Note:**\n';

  @override
  String get templateShoppingName => 'Lista spesa';

  @override
  String get templateShoppingDescription =>
      'Lista della spesa con caselle di controllo';

  @override
  String get templateShoppingItems => 'Frutta e verdura\nLatte\nPane\nUova';

  @override
  String get templateTravelName => 'Lista viaggio';

  @override
  String get templateTravelDescription =>
      'Non dimenticare nulla per il tuo viaggio';

  @override
  String get templateTravelItems =>
      'Passaporto / Documenti\nCaricabatterie\nVestiti\nProdotti da toilette\nMedicinali\nContanti / Carte';

  @override
  String get templateIdeasName => 'Brainstorming idee';

  @override
  String get templateIdeasDescription => 'Spazio libero per raccogliere idee';

  @override
  String get templateIdeasContent =>
      '## Idea: [TITOLO]\n\n**Descrizione:**\n\n**Pro:**\n- \n\n**Contro:**\n- \n\n**Prossimi passi:**\n';

  @override
  String get commonEdit => 'Modifica';

  @override
  String get commonShare => 'Condividi';

  @override
  String commonReminderScheduled(String date) {
    return 'Promemoria: $date';
  }

  @override
  String get commonReminderRemoved => 'Promemoria rimosso';

  @override
  String commonLastModified(String date) {
    return 'Ultima modifica: $date';
  }

  @override
  String get tasksSearchHint => 'Cerca tra i task...';

  @override
  String get tasksSortTooltip => 'Ordina task';

  @override
  String get tasksNewTask => 'Nuovo task';

  @override
  String get tasksNewTaskHint => 'Cosa devi fare?';

  @override
  String get tasksNewList => 'Nuovo elenco';

  @override
  String get tasksListNameHint => 'Nome elenco';

  @override
  String get tasksCreate => 'Crea';

  @override
  String get tasksDeleteList => 'Elimina elenco';

  @override
  String tasksDeleteListConfirm(String name) {
    return 'Vuoi davvero eliminare l\'elenco \"$name\"?';
  }

  @override
  String get tasksTabAll => 'Tutte';

  @override
  String get tasksTabStarred => 'Speciali';

  @override
  String get tasksEmpty => 'Nessun task trovato';

  @override
  String get tasksCompletedSection => 'Completati';

  @override
  String get tasksComplete => 'Completa';

  @override
  String get tasksReopen => 'Riapri';

  @override
  String get tasksCompleted => 'Task completato';

  @override
  String get tasksReopened => 'Task riaperto';

  @override
  String get tasksTrashed => 'Task spostato nel cestino';

  @override
  String get tasksUnarchived => 'Task rimosso dall\'archivio';

  @override
  String get tasksAddStar => 'Aggiungi agli speciali';

  @override
  String get tasksRemoveStar => 'Rimuovi dagli speciali';

  @override
  String get tasksMoveToList => 'Sposta in elenco';

  @override
  String get tasksDeleteTask => 'Elimina task';

  @override
  String tasksDeleteTaskNamedConfirm(String title) {
    return 'Vuoi spostare \"$title\" nel cestino?';
  }

  @override
  String get tasksDeleteTaskConfirm => 'Vuoi spostare questo task nel cestino?';

  @override
  String get tasksDeleteRecurringTitle => 'Elimina task ricorrente';

  @override
  String get tasksDeleteThisOccurrence => 'Solo questo task';

  @override
  String get tasksDeleteAllOccurrences => 'Questo e tutti i successivi';

  @override
  String get tasksOccurrenceDeleted =>
      'Task eliminato, passato alla prossima ripetizione';

  @override
  String get tasksMoveToListTitle => 'Sposta in un elenco';

  @override
  String get tasksAddDetails => 'Aggiungi dettagli';

  @override
  String get tasksRemoveDueDate => 'Rimuovi data';

  @override
  String get tasksNoList => 'Nessun elenco';

  @override
  String get tasksUnknownList => 'Sconosciuto';

  @override
  String get taskEditorTitle => 'Task';

  @override
  String get taskEditorUndo => 'Annulla (Ctrl+Z)';

  @override
  String get taskEditorRedo => 'Ripeti (Ctrl+Y)';

  @override
  String get taskEditorUnpin => 'Sposta in alto';

  @override
  String get taskEditorPin => 'Fissa in alto';

  @override
  String get taskEditorDueDate => 'Imposta data e ora';

  @override
  String get taskEditorRecurrence => 'Imposta ripetizione';

  @override
  String get taskEditorRecurrenceTitle => 'Ripetizione';

  @override
  String get taskEditorTitleHint => 'Titolo task';

  @override
  String get taskEditorDescriptionHint => 'Descrizione...';

  @override
  String taskEditorSubtasks(int completed, int total) {
    return 'Sottoattività ($completed/$total)';
  }

  @override
  String get taskEditorAddSubtaskHint => 'Aggiungi sottoattività...';

  @override
  String get taskEditorReminderNotificationTitle => 'Promemoria task';

  @override
  String get taskEditorReminderNotificationBody =>
      'Hai un promemoria per questo task';

  @override
  String get recurrenceNone => 'Nessuna';

  @override
  String get recurrenceDaily => 'Giornaliero';

  @override
  String get recurrenceWeekly => 'Settimanale';

  @override
  String get recurrenceMonthly => 'Mensile';

  @override
  String get recurrenceYearly => 'Annuale';

  @override
  String get commonSave => 'Salva';

  @override
  String get commonRestore => 'Ripristina';

  @override
  String get commonUntitledParens => '(senza titolo)';

  @override
  String get commonTabNotes => 'Note';

  @override
  String get commonTabTasks => 'Task';

  @override
  String get commonTabEvents => 'Eventi';

  @override
  String get commonToday => 'Oggi';

  @override
  String get commonTomorrow => 'Domani';

  @override
  String get commonYesterday => 'Ieri';

  @override
  String get tasksNoDateSection => 'Senza data';

  @override
  String get tasksNotificationTimeLabel => 'Orario notifica';

  @override
  String get tasksRecurringLabel => 'Task ricorrente';

  @override
  String get calendarSearchHint => 'Cerca eventi...';

  @override
  String get calendarChangeView => 'Cambia visualizzazione';

  @override
  String get calendarViewDay => 'Giorno';

  @override
  String get calendarViewWeek => 'Settimana';

  @override
  String get calendarViewMonth => 'Mese';

  @override
  String get calendarViewYear => 'Anno';

  @override
  String get calendarViewSchedule => 'Programma';

  @override
  String get calendarViewSevenDays => '7 giorni';

  @override
  String get calendarPreviousDay => 'Giorno precedente';

  @override
  String get calendarNextDay => 'Giorno successivo';

  @override
  String get calendarPreviousMonth => 'Mese precedente';

  @override
  String get calendarNextMonth => 'Mese successivo';

  @override
  String get calendarPreviousYear => 'Anno precedente';

  @override
  String get calendarNextYear => 'Anno successivo';

  @override
  String get calendarNoEventsDay => 'Nessun evento per questo giorno';

  @override
  String get calendarNoEventsScheduled => 'Nessun evento in programma';

  @override
  String get calendarNoEventsFound => 'Nessun evento trovato';

  @override
  String get calendarAdd => 'Aggiungi';

  @override
  String get calendarAllDay => 'Tutto il giorno';

  @override
  String get calendarShowTasks => 'Mostra i task';

  @override
  String get calendarHideTasks => 'Nascondi i task';

  @override
  String get calendarAlerts => 'Avvisi';

  @override
  String get calendarAlertDayBefore => 'Il giorno prima';

  @override
  String get calendarAlertSameDay => 'Il giorno stesso';

  @override
  String get holidayNewYear => 'Capodanno';

  @override
  String get holidayEpiphany => 'Epifania';

  @override
  String get holidayValentinesDay => 'San Valentino';

  @override
  String get holidayWomensDay => 'Festa della donna';

  @override
  String get holidayFathersDay => 'Festa del papà';

  @override
  String get holidayEaster => 'Pasqua';

  @override
  String get holidayEasterMonday => 'Lunedì dell\'Angelo';

  @override
  String get holidayLiberationDay => 'Festa della Liberazione';

  @override
  String get holidayLabourDay => 'Festa del Lavoro';

  @override
  String get holidayMothersDay => 'Festa della mamma';

  @override
  String get holidayRepublicDay => 'Festa della Repubblica';

  @override
  String get holidayAssumption => 'Ferragosto';

  @override
  String get holidayStFrancis => 'San Francesco d\'Assisi';

  @override
  String get holidayHalloween => 'Halloween';

  @override
  String get holidayAllSaints => 'Ognissanti';

  @override
  String get holidayImmaculateConception => 'Immacolata Concezione';

  @override
  String get holidayChristmas => 'Natale';

  @override
  String get holidayStStephen => 'Santo Stefano';

  @override
  String get calendarHolidayPublic => 'Festività nazionale';

  @override
  String get calendarHolidayObservance => 'Ricorrenza';

  @override
  String get settingsCalendarSection => 'Calendario';

  @override
  String get settingsShowHolidays => 'Festività nazionali';

  @override
  String get settingsShowHolidaysSubtitle =>
      'Capodanno, Pasqua, 25 aprile, Natale e le altre festività italiane';

  @override
  String get settingsShowObservances => 'Ricorrenze';

  @override
  String get settingsShowObservancesSubtitle =>
      'Festa della mamma, Festa del papà, San Valentino, Festa della donna, Halloween';

  @override
  String get calendarAlert => 'Avviso';

  @override
  String get eventAlertNone => 'Nessun avviso';

  @override
  String get eventAlertAtStart => 'All\'inizio';

  @override
  String eventAlertMinutesBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuti prima',
      one: '1 minuto prima',
    );
    return '$_temp0';
  }

  @override
  String eventAlertHoursBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ore prima',
      one: '1 ora prima',
    );
    return '$_temp0';
  }

  @override
  String eventAlertDaysBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni prima',
      one: '1 giorno prima',
    );
    return '$_temp0';
  }

  @override
  String get settingsEventAlertOffset => 'Avviso degli eventi';

  @override
  String get settingsEventAlertOffsetSubtitle =>
      'Proposto per i nuovi eventi con orario e per quelli importati senza avviso';

  @override
  String calendarAlertAt(String time) {
    return 'Alle $time';
  }

  @override
  String calendarAlertBodyToday(String when) {
    return 'Oggi · $when';
  }

  @override
  String calendarAlertBodyTomorrow(String when) {
    return 'Domani · $when';
  }

  @override
  String get calendarEndTime => 'Ora di fine';

  @override
  String get calendarNoEndTime => 'Nessuna';

  @override
  String get calendarRemoveEndTime => 'Rimuovi ora di fine';

  @override
  String get calendarBirthday => 'Compleanno';

  @override
  String get calendarNameDay => 'Onomastico';

  @override
  String get calendarRecurrence => 'Ricorrenza';

  @override
  String get calendarLocationHint => 'Aggiungi luogo';

  @override
  String get calendarLocationOpenMaps => 'Apri in Maps';

  @override
  String get calendarColor => 'Colore';

  @override
  String get calendarColorDefault => 'Predefinito';

  @override
  String get calendarEventTitle => 'Evento';

  @override
  String get calendarEntryTypeEvent => 'Evento';

  @override
  String get calendarEntryTypeTask => 'Task';

  @override
  String get calendarDeleteEvent => 'Elimina evento';

  @override
  String get calendarDeleteEventConfirm =>
      'Vuoi spostare questo evento nel cestino?';

  @override
  String get calendarEventTrashed => 'Evento spostato nel cestino';

  @override
  String get calendarEventUnarchived => 'Evento rimosso dall\'archivio';

  @override
  String get calendarTitleHint => 'Titolo';

  @override
  String get calendarDescriptionHint => 'Descrizione';

  @override
  String get calendarReminderNotificationTitle => 'Promemoria evento';

  @override
  String get eventRecurrenceNone => 'Non ripetere';

  @override
  String get eventRecurrenceDaily => 'Giornalmente';

  @override
  String get eventRecurrenceWeekly => 'Settimanalmente';

  @override
  String get eventRecurrenceMonthly => 'Mensilmente';

  @override
  String get eventRecurrenceYearly => 'Annualmente';

  @override
  String recurrenceEveryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ogni $count giorni',
      one: 'Ogni giorno',
    );
    return '$_temp0';
  }

  @override
  String recurrenceEveryWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ogni $count settimane',
      one: 'Ogni settimana',
    );
    return '$_temp0';
  }

  @override
  String recurrenceEveryMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ogni $count mesi',
      one: 'Ogni mese',
    );
    return '$_temp0';
  }

  @override
  String recurrenceEveryYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ogni $count anni',
      one: 'Ogni anno',
    );
    return '$_temp0';
  }

  @override
  String recurrenceUnitDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'giorni',
      one: 'giorno',
    );
    return '$_temp0';
  }

  @override
  String recurrenceUnitWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'settimane',
      one: 'settimana',
    );
    return '$_temp0';
  }

  @override
  String recurrenceUnitMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'mesi',
      one: 'mese',
    );
    return '$_temp0';
  }

  @override
  String recurrenceUnitYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'anni',
      one: 'anno',
    );
    return '$_temp0';
  }

  @override
  String recurrenceRuleDetail(String rule, String detail) {
    return '$rule: $detail';
  }

  @override
  String recurrenceOnWeekdays(String days) {
    return '$days';
  }

  @override
  String recurrenceUntil(String rule, String date) {
    return '$rule, fino al $date';
  }

  @override
  String recurrenceMonthDay(int day) {
    return 'il giorno $day';
  }

  @override
  String recurrenceMonthWeekday(String ordinal, String weekday) {
    return '$ordinal $weekday';
  }

  @override
  String recurrenceOrdinal(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'm1': 'il primo',
      'm2': 'il secondo',
      'm3': 'il terzo',
      'm4': 'il quarto',
      'm5': 'il quinto',
      'mlast': 'l\'ultimo',
      'f1': 'la prima',
      'f2': 'la seconda',
      'f3': 'la terza',
      'f4': 'la quarta',
      'f5': 'la quinta',
      'other': 'l\'ultima',
    });
    return '$_temp0';
  }

  @override
  String recurrencePresetWeekly(String weekday) {
    return 'Ogni settimana di $weekday';
  }

  @override
  String get recurrencePresetWorkdays => 'Ogni giorno feriale (lun–ven)';

  @override
  String recurrencePresetMonthlyDay(int day) {
    return 'Ogni mese il giorno $day';
  }

  @override
  String recurrencePresetMonthlyWeekday(String ordinal, String weekday) {
    return 'Ogni mese, $ordinal $weekday';
  }

  @override
  String recurrencePresetYearly(String date) {
    return 'Ogni anno il $date';
  }

  @override
  String get recurrenceCustom => 'Personalizza…';

  @override
  String get recurrenceCustomTitle => 'Ricorrenza personalizzata';

  @override
  String get recurrenceRepeatEvery => 'Ripeti ogni';

  @override
  String get recurrenceRepeatOn => 'Ripeti di';

  @override
  String get recurrenceEnds => 'Termina';

  @override
  String get recurrenceEndsNever => 'Mai';

  @override
  String get recurrenceEndsOn => 'Il giorno';

  @override
  String get recurrenceEndsAfter => 'Dopo';

  @override
  String recurrenceOccurrences(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'volte',
      one: 'volta',
    );
    return '$_temp0';
  }

  @override
  String recurrenceExcludedDates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count date escluse',
      one: '1 data esclusa',
    );
    return '$_temp0';
  }

  @override
  String get recurrenceRestoreExcluded => 'Ripristina';

  @override
  String get calendarDeleteRecurringTitle => 'Elimina evento ricorrente';

  @override
  String get calendarDeleteThisOccurrence => 'Solo questo evento';

  @override
  String get calendarDeleteWholeSeries => 'Tutti gli eventi della serie';

  @override
  String get calendarOccurrenceDeleted => 'Evento eliminato';

  @override
  String settingsIcsApproximated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count ricorrenze sono state importate in modo approssimato: controllale nel calendario.',
      one:
          '1 ricorrenza è stata importata in modo approssimato: controllala nel calendario.',
    );
    return '$_temp0';
  }

  @override
  String get archiveEmptyNotes => 'Nessuna nota archiviata';

  @override
  String get archiveEmptyTasks => 'Nessun task archiviato';

  @override
  String get archiveEmptyEvents => 'Nessun evento archiviato';

  @override
  String get trashEmptyAction => 'Svuota';

  @override
  String get trashAutoDeleteInfo =>
      'Gli elementi vengono eliminati definitivamente dopo 7 giorni.';

  @override
  String get trashEmptyTitle => 'Svuota cestino';

  @override
  String get trashEmptyConfirm =>
      'Tutti gli elementi nel cestino verranno eliminati definitivamente.';

  @override
  String get trashEmptyNotes => 'Nessuna nota nel cestino';

  @override
  String get trashEmptyTasks => 'Nessun task nel cestino';

  @override
  String get trashEmptyEvents => 'Nessun evento nel cestino';

  @override
  String get trashExpiresSoon => 'Scade tra poco (eliminazione automatica)';

  @override
  String get trashExpiresToday => 'Scade oggi';

  @override
  String trashExpiresInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Scade tra $count giorni',
      one: 'Scade tra 1 giorno',
    );
    return '$_temp0';
  }

  @override
  String get trashDeleteForever => 'Elimina definitivamente';

  @override
  String get trashDeleteForeverConfirm =>
      'La nota verrà eliminata in modo permanente.';

  @override
  String get labelsNew => 'Nuova etichetta';

  @override
  String get labelsNameHint => 'Nome etichetta';

  @override
  String get labelsEmpty => 'Nessuna etichetta';

  @override
  String get labelsEmptyHint =>
      'Crea una nuova etichetta o aggiungila da una nota.';

  @override
  String get labelsRename => 'Rinomina';

  @override
  String get labelsRenameTitle => 'Rinomina etichetta';

  @override
  String get labelsDeleteTitle => 'Elimina etichetta';

  @override
  String labelsDeleteConfirm(String tag) {
    return 'L\'etichetta \"$tag\" verrà rimossa da tutte le note.';
  }

  @override
  String labelsNoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count note',
      one: '1 nota',
      zero: 'Nessuna nota',
    );
    return '$_temp0';
  }

  @override
  String get labelNotesEmpty => 'Nessuna nota con questa etichetta';

  @override
  String get editorLabels => 'Etichette';

  @override
  String get editorLabelsSearchHint => 'Cerca o crea un\'etichetta...';

  @override
  String editorLabelsCreate(String name) {
    return 'Crea \"$name\"';
  }

  @override
  String get editorLabelsEmpty =>
      'Nessuna etichetta: scrivi un nome per crearne una.';

  @override
  String get statsTitle => 'Statistiche';

  @override
  String get statsOverview => 'Panoramica';

  @override
  String get statsOpenTasks => 'Task da fare';

  @override
  String get statsEventsThisWeek => 'Eventi questa settimana';

  @override
  String get statsCreatedThisWeek => 'Creati questa settimana';

  @override
  String get statsOverdue => 'Scaduti';

  @override
  String get statsDueToday => 'Oggi';

  @override
  String get statsDueThisWeek => 'Entro domenica';

  @override
  String get statsNoDueDate => 'Senza scadenza';

  @override
  String get statsActivity => 'Attività';

  @override
  String get statsActivitySubtitle =>
      'Elementi creati nelle ultime 12 settimane';

  @override
  String get statsNoActivity =>
      'Nessun elemento creato nelle ultime 12 settimane';

  @override
  String statsMostActiveDay(String day) {
    return 'Giorno più attivo: $day';
  }

  @override
  String statsItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementi',
      one: '1 elemento',
    );
    return '$_temp0';
  }

  @override
  String get statsTopLabels => 'Etichette più usate';

  @override
  String get statsNoLabelsUsed => 'Nessuna etichetta usata';

  @override
  String get statsSummary => 'Riepilogo';

  @override
  String get statsActive => 'Attivi';

  @override
  String get statsArchived => 'Archiviati';

  @override
  String get statsTrashed => 'Eliminati';

  @override
  String get statsNoTasks => 'Nessun task presente';

  @override
  String get statsTaskCompletion => 'Completamento task';

  @override
  String get infoTitle => 'Info su Taskenda';

  @override
  String get infoTagline => 'Note, attività e promemoria in un unico posto';

  @override
  String get infoAboutTitle => 'Cos\'è Taskenda';

  @override
  String get infoFeaturesTitle => 'Funzionalità';

  @override
  String get infoFeatureNotesTitle => 'Note';

  @override
  String get infoFeatureNotesText =>
      'Testo formattato, liste di controllo, note vocali e condivisione con altri utenti';

  @override
  String get infoFeatureTasksTitle => 'Attività e calendario';

  @override
  String get infoFeatureTasksText =>
      'Organizza impegni ed eventi giorno per giorno';

  @override
  String get infoFeatureRemindersTitle => 'Notifiche';

  @override
  String get infoFeatureRemindersText =>
      'Notifiche puntuali e widget nella schermata Home';

  @override
  String get infoFeatureSyncTitle => 'Sincronizzazione e backup';

  @override
  String get infoFeatureSyncText =>
      'Dati sul tuo account, backup ed esportazione in PDF, TXT, JSON, CSV e HTML';

  @override
  String get infoLinksTitle => 'Link';

  @override
  String get infoLinkSource => 'Codice sorgente';

  @override
  String get infoLinkDeveloper => 'Profilo GitHub';

  @override
  String get infoLinkContact => 'Contatta lo sviluppatore';

  @override
  String get infoLinkError => 'Impossibile aprire il link';

  @override
  String get infoLinkWebsite => 'Pagina del progetto';

  @override
  String get infoLinkWebApp => 'Versione web';

  @override
  String get infoShareApp => 'Condividi Taskenda';

  @override
  String infoShareText(String url) {
    return 'Prova Taskenda, l\'app per note, task e calendario: $url';
  }

  @override
  String infoMadeBy(String name) {
    return 'Realizzato da $name';
  }

  @override
  String get infoGuideOpen => 'Guida introduttiva';

  @override
  String get infoChangelogTitle => 'Novità';

  @override
  String get infoLicensesTitle => 'Licenze open source';

  @override
  String get exportTitle => 'Esporta note';

  @override
  String get exportDestinationTitle => 'Esporta';

  @override
  String get exportSaveToDevice => 'Salva sul dispositivo';

  @override
  String get exportSaveToDeviceSubtitle =>
      'Scegli la cartella: Download, Drive, scheda SD…';

  @override
  String get exportShareSubtitle => 'Invia a Drive, email o un\'altra app';

  @override
  String exportFileDone(String format) {
    return '$format esportato';
  }

  @override
  String exportFailed(String error) {
    return 'Esportazione non riuscita: $error';
  }

  @override
  String get exportIntro =>
      'Esporta tutte le note attive (escluse quelle nel cestino).';

  @override
  String get exportPdfSubtitle => 'Salva le note in un file .pdf';

  @override
  String get exportTxtSubtitle => 'Salva le note in un file .txt';

  @override
  String get exportJsonSubtitle => 'Salva le note in un file .json';

  @override
  String get exportCsvSubtitle => 'Salva le note in un file .csv';

  @override
  String get exportHtmlSubtitle => 'Salva le note in un file .html';

  @override
  String get exportDownload => 'Scarica';

  @override
  String get settingsBackupDataTitle => 'Backup e dati';

  @override
  String get settingsBackupDataSubtitle =>
      'Backup automatico, esportazione, importazione ed eliminazione dei dati';

  @override
  String get settingsBackupTitle => 'Backup';

  @override
  String get settingsAutoBackup => 'Backup automatico';

  @override
  String get settingsAutoBackupSubtitle => 'Salva automaticamente i tuoi dati';

  @override
  String get settingsBackupFrequency => 'Frequenza backup';

  @override
  String get settingsViewBackups => 'Visualizza backup';

  @override
  String get settingsViewBackupsSubtitle => 'Gestisci i backup salvati';

  @override
  String get settingsExportCalendarJson => 'Esporta calendario JSON';

  @override
  String get settingsExportCalendarJsonSubtitle =>
      'Scarica gli eventi come file .json';

  @override
  String get settingsImportCalendarJson => 'Importa calendario JSON';

  @override
  String get settingsImportCalendarJsonSubtitle =>
      'Ripristina gli eventi da un file .json';

  @override
  String get settingsExportIcs => 'Esporta calendario ICS';

  @override
  String get settingsExportIcsSubtitle =>
      'Esporta tutti gli eventi in un file .ics';

  @override
  String get settingsImportIcs => 'Importa da Google Calendar';

  @override
  String get settingsImportIcsSubtitle => 'Importa eventi da un file .ics';

  @override
  String get settingsClearCalendar => 'Cancella eventi calendario';

  @override
  String get settingsClearCalendarSubtitle =>
      'Rimuove tutti gli eventi dal calendario';

  @override
  String get settingsGlobalBackupTitle => 'Backup globale';

  @override
  String get settingsExportFullBackup => 'Esporta backup completo';

  @override
  String get settingsExportFullBackupSubtitle =>
      'Scarica un file .json con note, task ed eventi';

  @override
  String get settingsImportFullBackup => 'Importa backup completo';

  @override
  String get settingsImportFullBackupSubtitle =>
      'Ripristina dati da un file .json di backup';

  @override
  String get settingsClearAll => 'Cancella tutti i dati';

  @override
  String get settingsClearAllSubtitle =>
      'Elimina definitivamente note, task ed eventi';

  @override
  String get settingsAccountTitle => 'Account';

  @override
  String get settingsDeleteAccount => 'Elimina account';

  @override
  String get settingsDeleteAccountSubtitle =>
      'Elimina definitivamente l\'account e tutti i suoi dati';

  @override
  String get settingsExportNotesSubtitle =>
      'Esporta tutte le note in diversi formati';

  @override
  String get settingsExportNotesJson => 'Esporta note JSON';

  @override
  String get settingsExportNotesJsonSubtitle =>
      'Scarica le note come file .json';

  @override
  String get settingsImportNotesJson => 'Importa note JSON';

  @override
  String get settingsImportNotesJsonSubtitle =>
      'Ripristina le note da un file .json';

  @override
  String get settingsClearNotes => 'Cancella note';

  @override
  String get settingsClearNotesSubtitle => 'Rimuove tutte le note';

  @override
  String get settingsLayout => 'Layout';

  @override
  String get settingsLayoutGrid => 'Griglia';

  @override
  String get settingsLayoutList => 'Lista';

  @override
  String get settingsFabMenu => 'Menu del pulsante +';

  @override
  String get settingsFabMenuOn =>
      'Scegli tra nota, lista, task, audio e modello';

  @override
  String get settingsFabMenuOff => 'Il pulsante + crea subito una nuova nota';

  @override
  String get settingsExportTasksJson => 'Esporta task JSON';

  @override
  String get settingsExportTasksJsonSubtitle =>
      'Scarica i task come file .json';

  @override
  String get settingsImportTasksJson => 'Importa task JSON';

  @override
  String get settingsImportTasksJsonSubtitle =>
      'Ripristina i task da un file .json';

  @override
  String get settingsClearTasks => 'Cancella task';

  @override
  String get settingsClearTasksSubtitle => 'Rimuove tutti i task';

  @override
  String get settingsShowCompleted => 'Mostra task completati';

  @override
  String get settingsShowCompletedSubtitle =>
      'Visualizza i task marcati come completati';

  @override
  String get settingsGroupByPriority => 'Raggruppa per priorità';

  @override
  String get settingsGroupByPrioritySubtitle =>
      'Ordina task per priorità (speciali in alto)';

  @override
  String get settingsRestoreBackup => 'Ripristina backup';

  @override
  String get settingsReplaceAllConfirm =>
      'I dati attuali (note, task ed eventi) verranno sostituiti con quelli del backup. Continuare?';

  @override
  String get settingsRestoreSettingsToo => 'Ripristina anche le impostazioni';

  @override
  String get settingsRestoreSettingsTooSubtitle =>
      'Tema, lingua, schermata iniziale, viste e preferenze di calendario, attività e note';

  @override
  String get settingsBackupReadFailed => 'Impossibile leggere il backup.';

  @override
  String get settingsBackupRestored => 'Backup ripristinato con successo.';

  @override
  String get settingsNoBackups => 'Nessun backup disponibile';

  @override
  String get settingsBackupsAvailable => 'Backup disponibili';

  @override
  String get settingsImport => 'Importa';

  @override
  String get settingsBackupExported => 'Backup esportato';

  @override
  String get settingsImportBackupTitle => 'Importa backup';

  @override
  String get settingsBackupImported => 'Backup importato con successo.';

  @override
  String get settingsBackupWrongApp =>
      'Questo file non è un backup di Taskenda.';

  @override
  String get settingsBackupTooNew =>
      'Questo backup è stato creato da una versione più recente di Taskenda: aggiorna l\'app per importarlo.';

  @override
  String get settingsClearAllConfirm =>
      'Tutti i dati (note, task ed eventi) verranno eliminati definitivamente. Questa operazione è irreversibile. Continuare?';

  @override
  String get settingsAllCleared => 'Tutti i dati sono stati eliminati.';

  @override
  String get settingsDeleteAll => 'Elimina tutto';

  @override
  String get settingsNotesExported => 'Note esportate';

  @override
  String get settingsImportNotesTitle => 'Importa note';

  @override
  String get settingsReplaceNotesConfirm =>
      'Le note attuali verranno sostituite con quelle del file. Continuare?';

  @override
  String get settingsNotesImported => 'Note importate con successo.';

  @override
  String get settingsClearNotesConfirm =>
      'Tutte le note verranno eliminate definitivamente. Continuare?';

  @override
  String get settingsNotesCleared => 'Tutte le note sono state eliminate.';

  @override
  String get settingsTasksExported => 'Task esportati';

  @override
  String get settingsImportTasksTitle => 'Importa task';

  @override
  String get settingsReplaceTasksConfirm =>
      'I task attuali verranno sostituiti con quelli del file. Continuare?';

  @override
  String get settingsTasksImported => 'Task importati con successo.';

  @override
  String get settingsClearTasksConfirm =>
      'Tutti i task verranno eliminati definitivamente. Continuare?';

  @override
  String get settingsTasksCleared => 'Tutti i task sono stati eliminati.';

  @override
  String get settingsCalendarExported => 'Calendario esportato';

  @override
  String get settingsImportCalendarTitle => 'Importa calendario';

  @override
  String get settingsReplaceCalendarConfirm =>
      'Gli eventi attuali verranno sostituiti con quelli del file. Continuare?';

  @override
  String get settingsCalendarImported => 'Calendario importato con successo.';

  @override
  String get settingsClearEventsTitle => 'Cancella eventi';

  @override
  String get settingsClearCalendarConfirm =>
      'Tutti gli eventi del calendario verranno eliminati definitivamente. Continuare?';

  @override
  String get settingsCalendarCleared =>
      'Tutti gli eventi sono stati eliminati.';

  @override
  String get settingsNoEventsToExport => 'Nessun evento da esportare.';

  @override
  String get settingsIcsExported => 'Calendario ICS esportato';

  @override
  String get settingsNoEventsInFile => 'Nessun evento trovato nel file.';

  @override
  String get settingsDeleteAccountConfirm =>
      'L\'account e tutti i suoi dati (note, task ed eventi) verranno eliminati definitivamente da tutti i dispositivi. Questa operazione è irreversibile: se vuoi conservare i dati, esporta prima un backup completo. Continuare?';

  @override
  String get settingsConfirmPassword => 'Conferma la password';

  @override
  String get settingsDeleteAccountFailed =>
      'Impossibile eliminare l\'account. Controlla la connessione e riprova.';

  @override
  String get settingsAccountDeleted => 'Account eliminato.';

  @override
  String settingsImportError(String error) {
    return 'Errore durante l\'importazione: $error';
  }

  @override
  String settingsBackupsLoadError(String error) {
    return 'Errore nel caricamento dei backup: $error';
  }

  @override
  String settingsIcsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventi importati nel calendario.',
      one: '1 evento importato nel calendario.',
    );
    return '$_temp0';
  }

  @override
  String infoVersion(String version) {
    return 'Versione $version';
  }

  @override
  String get infoDescription =>
      'Taskenda raccoglie note, liste di controllo, attività ed eventi del calendario, sincronizzati sul tuo account e disponibili su ogni dispositivo.';

  @override
  String statsCompletedOf(int completed, int total) {
    return 'Completati: $completed / $total';
  }

  @override
  String exportPdfError(String error) {
    return 'Errore PDF: $error';
  }

  @override
  String get exportEmptyNote => '(nota vuota)';

  @override
  String exportModified(String date) {
    return 'Modificata: $date';
  }

  @override
  String exportLabels(String labels) {
    return 'Etichette: $labels';
  }

  @override
  String get exportDateTimePattern => 'd MMM y \'alle\' HH:mm';

  @override
  String get exportCsvHeader =>
      'id,titolo,contenuto,tipo,etichette,fissata,creata,modificata';

  @override
  String exportHtmlHeading(String date) {
    return 'Export note – $date';
  }

  @override
  String get notificationChannelName => 'Promemoria';

  @override
  String get notificationChannelDescription =>
      'Notifiche per i promemoria di Taskenda';

  @override
  String get notificationTargetNotFound =>
      'Elemento del promemoria non trovato';

  @override
  String get widgetNotesEmpty => 'Nessuna nota';

  @override
  String get widgetTasksEmpty => 'Nessun task da completare';

  @override
  String get widgetCalendarEmpty =>
      'Nessun impegno nelle prossime due settimane';

  @override
  String get infoPrivacyOpen => 'Informativa sulla privacy';

  @override
  String get privacyPolicyTitle => 'Informativa sulla privacy';

  @override
  String get privacyPolicyIntro =>
      'Taskenda è un\'app per note, task e calendario. Questa informativa spiega quali dati tratta, perché e come puoi controllarli. Taskenda non mostra pubblicità, non usa strumenti di analisi o di tracciamento e non vende né cede i tuoi dati.';

  @override
  String privacyPolicyLastUpdated(String date) {
    return 'Ultimo aggiornamento: $date';
  }

  @override
  String get privacyPolicyOnlineVersion => 'Versione online';

  @override
  String get privacyPolicyOnlineVersionSubtitle =>
      'Leggi l\'informativa sul web';

  @override
  String get policy_section_controller_title => '1. Titolare del trattamento';

  @override
  String policy_section_controller_text(String name, String email) {
    return 'Il titolare del trattamento è $name, sviluppatore di Taskenda. Per qualsiasi domanda sulla privacy o per esercitare i tuoi diritti puoi scrivere a $email.';
  }

  @override
  String get policy_section_data_title => '2. Dati che raccogliamo';

  @override
  String get policy_section_data_text =>
      '• Account: l\'indirizzo email con cui ti registri; la password è gestita da Firebase Authentication e non è mai visibile allo sviluppatore. Se accedi con Google, Google condivide con Firebase nome, email, foto del profilo e identificativo del tuo account Google. Firebase registra anche la data di creazione dell\'account e dell\'ultimo accesso.\n• Contenuti: note (titolo, testo, liste di controllo, etichette, colori e stile, promemoria, collegamenti tra note, cronologia delle modifiche), task ed elenchi (sottotask, scadenze, ricorrenze, priorità), eventi del calendario (compreso il luogo) ed etichette.\n• Note audio: le registrazioni restano solo sul dispositivo; con la nota vengono sincronizzati soltanto nome, durata e percorso del file.\n• Condivisione: per permettere ad altri di condividere note, task ed eventi con te, la tua email e il tuo nome vengono salvati in un elenco consultabile solo conoscendo l\'email esatta. Quando condividi un elemento, le persone che aggiungi ne vedono il contenuto, il tuo nome e la tua email, e tu vedi i loro; pin, archivio, promemoria, avvisi ed etichette restano personali. Per avvisarti quando qualcuno condivide qualcosa con te, l\'app salva per ogni dispositivo un identificativo per le notifiche push (token di Firebase Cloud Messaging) e la lingua dell\'app; viene cancellato quando esci dall\'account su quel dispositivo.\n• Sul dispositivo: preferenze dell\'app (lingua, tema, layout, ordinamento, opzioni di note e task, guida introduttiva e novità già viste, impostazioni dei backup), i backup automatici, una copia dei dati per l\'uso offline, i promemoria programmati e i dati mostrati dai widget della schermata Home (titoli e anteprime di note, task e impegni). Sul web le preferenze sono salvate nel browser.';

  @override
  String get policy_section_use_title => '3. Come usiamo i dati';

  @override
  String get policy_section_use_text =>
      'I dati servono solo a far funzionare Taskenda: accedere al tuo account, salvare i tuoi contenuti e sincronizzarli tra i tuoi dispositivi, inviarti le notifiche e i promemoria che imposti e creare i backup. La tua email viene usata solo per l\'accesso e, se lo chiedi, per inviarti il link per reimpostare la password. Nessuna profilazione, nessuna pubblicità, nessuna analisi statistica né segnalazione automatica degli errori.';

  @override
  String get policy_section_storage_title => '4. Dove sono conservati';

  @override
  String get policy_section_storage_text =>
      'Account e contenuti sono conservati su Google Firebase (Firebase Authentication e Cloud Firestore), servizi forniti da Google. I contenuti sono conservati su server nell\'Unione europea, mentre Firebase Authentication può trattare i dati anche fuori dall\'Unione europea: il trasferimento avviene con le garanzie previste dai termini di Google Firebase. I dati viaggiano cifrati e le regole di sicurezza del database fanno sì che solo il tuo account possa leggere e modificare i tuoi contenuti, oltre alle persone con cui scegli di condividere un elemento. Le notifiche di condivisione sono inviate tramite Firebase Cloud Messaging, un servizio di Google. Lo sviluppatore non consulta i tuoi contenuti e non li condivide con nessuno.\n\nMentre scrivi il luogo di un evento, il testo digitato, la lingua dell\'app e il paese impostato sul dispositivo passano dal server di Taskenda (Firebase Cloud Functions) al servizio Google Places di Google per suggerirti luoghi e indirizzi: non viene inviato nient\'altro, né la tua posizione né i dati del tuo account, e Google non riceve il tuo indirizzo IP. Se tocchi il luogo per aprirlo in Maps, la ricerca passa all\'app o al sito di Google Maps.';

  @override
  String get policy_section_device_title => '5. Elaborazione sul dispositivo';

  @override
  String get policy_section_device_text =>
      'Alcune funzioni lavorano solo sul dispositivo e non inviano nulla allo sviluppatore né a terzi:\n• registrazione e riproduzione delle note audio;\n• esportazione delle note in PDF, TXT, JSON, CSV e HTML, esportazione e importazione di backup e calendari (ICS);\n• backup automatici, salvati in una cartella privata dell\'app (al massimo gli ultimi 30);\n• statistiche, promemoria e widget della schermata Home.\nI file che esporti o condividi finiscono dove scegli tu (ad esempio una cartella o un\'altra app).';

  @override
  String get policy_section_permissions_title => '6. Permessi';

  @override
  String get policy_section_permissions_text =>
      'Su Android Taskenda usa questi permessi:\n• Microfono: solo per registrare le note audio, quando avvii una registrazione.\n• Notifiche: per mostrarti i promemoria e le notifiche di task ed eventi.\n• Sveglie e promemoria esatti: per far scattare i promemoria all\'orario impostato.\n• Avvio all\'accensione: per riprogrammare i promemoria dopo il riavvio del telefono.\n• Mantenere attivo il dispositivo e vibrazione: per consegnare i promemoria anche in standby.\n• Servizio in primo piano: richiesto dal componente di Android che esegue le attività in background, come l\'aggiornamento del widget della schermata Home.\n• Internet e stato della rete: per sincronizzare i dati con Firebase e capire quando sei offline.\nTaskenda non accede a posizione, contatti, fotocamera, foto o file del telefono: i file da importare li scegli tu dal selettore di sistema.';

  @override
  String get policy_section_retention_title =>
      '7. Conservazione e cancellazione';

  @override
  String policy_section_retention_text(String email) {
    return 'I tuoi dati restano finché mantieni l\'account. Gli elementi nel cestino vengono eliminati definitivamente dopo 7 giorni. Puoi eliminare l\'account e tutti i dati da Impostazioni > Account > Elimina account: vengono cancellati l\'account e i contenuti su Firebase, compresi note, task ed eventi che hai condiviso (che spariscono anche per i collaboratori) e gli identificativi per le notifiche, vieni rimosso dagli elementi che altri hanno condiviso con te, la tua email esce dall\'elenco usato per la condivisione e, su questo dispositivo, vengono cancellati i promemoria e i backup automatici. Prima puoi esportare tutto da Impostazioni > Backup e dati > Backup globale. Eventuali copie residue nei sistemi di Google vengono rimosse nei tempi previsti da Firebase. Uscire dall\'account non cancella i dati; disinstallando l\'app vengono rimossi i dati salvati sul dispositivo, comprese le note audio. Puoi anche chiedere la cancellazione scrivendo a $email.';
  }

  @override
  String get policy_section_rights_title => '8. I tuoi diritti';

  @override
  String policy_section_rights_text(String email) {
    return 'In base al GDPR hai diritto di:\n• accedere ai tuoi dati ed esportarli (anche direttamente dall\'app);\n• correggerli;\n• cancellarli;\n• chiedere informazioni su come vengono trattati.\nPer esercitarli scrivi a $email. Hai anche il diritto di presentare reclamo all\'autorità di controllo del tuo Paese (in Italia il Garante per la protezione dei dati personali).';
  }

  @override
  String get policy_section_children_title => '9. Minori';

  @override
  String get policy_section_children_text =>
      'Taskenda non è rivolta ai minori di 14 anni, l\'età minima in Italia per acconsentire da soli ai servizi online. Sotto questa età puoi usarla solo con il consenso di un genitore o di chi ne fa le veci. Nei Paesi che prevedono un\'età diversa vale quella stabilita dalla legge locale.';

  @override
  String get policy_section_changes_title => '10. Modifiche';

  @override
  String get policy_section_changes_text =>
      'Se questa informativa cambia, la nuova versione sarà disponibile nell\'app (Info app > Informativa sulla privacy) e online, con la data dell\'ultimo aggiornamento.';

  @override
  String get shareCollaboratorsTitle => 'Collaboratori';

  @override
  String get shareEmailHint => 'Email di chi usa Taskenda';

  @override
  String get shareAdd => 'Aggiungi';

  @override
  String get shareOwner => 'Proprietario';

  @override
  String shareYouSuffix(String name) {
    return '$name (tu)';
  }

  @override
  String get shareRemoveTooltip => 'Rimuovi collaboratore';

  @override
  String get shareErrorNotFound =>
      'Nessuno usa Taskenda con questa email. Chiedi alla persona di installare l\'app e accedere almeno una volta.';

  @override
  String get shareErrorSelf => 'Non puoi aggiungere te stesso.';

  @override
  String get shareErrorAlreadyAdded =>
      'Questa persona è già tra i collaboratori.';

  @override
  String get sharePersonalInfo =>
      'I collaboratori vedono e modificano titolo, testo, checklist e colori. Fissate, archivio, promemoria, etichette e cestino restano personali. Le note audio e i collegamenti ad altre note non vengono condivisi.';

  @override
  String get shareLeave => 'Rimuovimi dalla condivisione';

  @override
  String get shareLeaveConfirmTitle => 'Uscire dalla condivisione?';

  @override
  String get shareLeaveConfirmMessage =>
      'Non lo vedrai più. Il proprietario potrà aggiungerti di nuovo.';

  @override
  String get shareLeaveConfirm => 'Rimuovimi';

  @override
  String get shareLeft => 'Non fai più parte della condivisione';

  @override
  String get shareSaveFirst =>
      'Scrivi qualcosa nella nota prima di aggiungere collaboratori';

  @override
  String get shareSharedLabel => 'Condiviso';

  @override
  String get shareNotificationChannelName => 'Note condivise';

  @override
  String get shareNotificationChannelDescription =>
      'Avvisi quando qualcuno condivide una nota con te';

  @override
  String get shareTaskPersonalInfo =>
      'I collaboratori vedono e modificano titolo, descrizione, scadenza, ripetizione, sottotask e completamento. Stella, fissato, archivio, elenco, etichette e cestino restano personali.';

  @override
  String get shareEventPersonalInfo =>
      'I collaboratori vedono e modificano titolo, descrizione, data e orari, luogo, colore e ripetizione. Fissato, archivio, avvisi, etichette e cestino restano personali.';

  @override
  String get navShared => 'Condivisi';

  @override
  String get sharedEmpty =>
      'Niente di condiviso. Apri una nota, un task o un evento e aggiungi un collaboratore tramite email.';

  @override
  String get sharedWithMeSection => 'Condivisi con me';

  @override
  String get sharedByMeSection => 'Condivisi da me';
}
