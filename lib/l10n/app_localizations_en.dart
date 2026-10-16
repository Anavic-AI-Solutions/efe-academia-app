import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSearchHint => 'Search...';

  @override
  String get commonUser => 'User';

  @override
  String get navHome => 'Home';

  @override
  String get navClasses => 'Classrooms';

  @override
  String get navChat => 'Chat';

  @override
  String get navProfile => 'Profile';

  @override
  String get authWelcomeBack => 'Welcome back';

  @override
  String get authSignInSubtitle => 'Sign in to your account';

  @override
  String get authEmailLabel => 'Email address';

  @override
  String get authEmailRequired => 'Email is required';

  @override
  String get authEmailInvalid => 'Enter a valid email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordRequired => 'Password is required';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authSignIn => 'Sign In';

  @override
  String get authForgotPasswordTitle => 'Forgot Password';

  @override
  String get authResetSubtitle => 'Reset your password';

  @override
  String get authCheckEmail => 'Check Your Email';

  @override
  String get authResetInstructions => 'Enter your email and we\'ll send you a link to reset your password.';

  @override
  String authResetLinkSent(String email) {
    return 'We\'ve sent a password reset link to\n$email';
  }

  @override
  String get authSendResetLink => 'Send Reset Link';

  @override
  String get authBackToSignIn => 'Back to Sign In';

  @override
  String get validationRequired => 'Required';

  @override
  String get validationInvalidEmail => 'Invalid email';

  @override
  String get validationPasswordLength => 'Password must be at least 8 characters';

  @override
  String get validationPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String validationFieldRequired(String field) {
    return '$field is required';
  }

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}m ago',
      one: '1m ago',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}h ago',
      one: '1h ago',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}d ago',
      one: '1d ago',
    );
    return '$_temp0';
  }

  @override
  String get profileAccount => 'Account';

  @override
  String get profileEditProfile => 'Edit Profile';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profilePreferences => 'Preferences';

  @override
  String get profileTheme => 'Theme';

  @override
  String get profileSelectTheme => 'Select theme';

  @override
  String get profileThemeLight => 'Light';

  @override
  String get profileThemeDark => 'Dark';

  @override
  String get profileThemeSystem => 'System';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileSelectLanguage => 'Select language';

  @override
  String get profileAbout => 'About';

  @override
  String get profileHelpSupport => 'Help & Support';

  @override
  String get profileLogout => 'Logout';

  @override
  String get profileLogoutConfirm => 'Are you sure you want to logout?';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleBranch => 'Branch Director';

  @override
  String get roleProfessor => 'Professor';

  @override
  String get roleParent => 'Parent';

  @override
  String get roleStudent => 'Student';

  @override
  String get dashboardLoadError => 'Failed to load dashboard';

  @override
  String get dashboardQuickActions => 'Quick Actions';

  @override
  String get dashboardStudents => 'Students';

  @override
  String get dashboardNews => 'News';

  @override
  String get dashboardEvents => 'Events';

  @override
  String get dashboardFees => 'Fees';

  @override
  String get dashboardSearch => 'Search';

  @override
  String dashboardWelcome(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get dashboardClassrooms => 'Classrooms';

  @override
  String get dashboardAttendance => 'Attendance';

  @override
  String get dashboardPendingFees => 'Pending Fees';

  @override
  String get classroomsTitle => 'Classrooms';

  @override
  String get classroomsSearchHint => 'Search classrooms...';

  @override
  String get classroomsLoadError => 'Failed to load classrooms';

  @override
  String get classroomsEmptyTitle => 'No classrooms found';

  @override
  String get classroomsEmptyFiltered => 'Try adjusting or clearing your filters';

  @override
  String get classroomsEmptySearch => 'Try a different search term';

  @override
  String get classroomsEmptySubtitle => 'No classrooms available';

  @override
  String get classroomsClearFilters => 'Clear filters';

  @override
  String get classroomsDetailTitle => 'Classroom';

  @override
  String get classroomsDetailLoadError => 'Failed to load classroom';

  @override
  String get classroomsName => 'Name';

  @override
  String get classroomsDescription => 'Description';

  @override
  String get classroomsStatus => 'Status';

  @override
  String get classroomsShift => 'Shift';

  @override
  String get classroomsDay => 'Day';

  @override
  String get classroomsHour => 'Hour';

  @override
  String get classroomsRoom => 'Room';

  @override
  String get classroomsYear => 'Year';

  @override
  String get classroomsBranch => 'Branch';

  @override
  String get classroomsLevel => 'Level';

  @override
  String get classroomsStudents => 'Students';

  @override
  String get classroomsFiltersTitle => 'Filters';

  @override
  String get classroomsFilterClearAll => 'Clear all';

  @override
  String get classroomsFilterApply => 'Apply filters';

  @override
  String get classroomsFilterClear => 'Clear';

  @override
  String get classroomsStatusActive => 'Active';

  @override
  String get classroomsStatusArchived => 'Archived';

  @override
  String get classroomsFiltersLoadError => 'Could not load filters';

  @override
  String get classroomsFiltersLoadErrorDetail => 'Check your connection and try again.';

  @override
  String classroomsFilterChipBranch(String value) {
    return 'Branch: $value';
  }

  @override
  String classroomsFilterChipLevel(String value) {
    return 'Level: $value';
  }

  @override
  String classroomsFilterChipYear(String value) {
    return 'Year: $value';
  }

  @override
  String classroomsFilterChipStatus(String value) {
    return 'Status: $value';
  }

  @override
  String paginationShowing(int from, int to, int total) {
    return 'Showing $from–$to of $total';
  }

  @override
  String get paginationPrevious => 'Previous page';

  @override
  String get paginationNext => 'Next page';

  @override
  String paginationPage(int page) {
    return 'Page $page';
  }

  @override
  String get classroomsTabSummary => 'Summary';

  @override
  String get classroomsTabStudents => 'Students';

  @override
  String get classroomsTabProfessors => 'Professors';

  @override
  String get classroomsTabMaterials => 'Materials';

  @override
  String get classroomsSectionSchedule => 'Schedule';

  @override
  String get classroomsSectionAcademic => 'Academic';

  @override
  String get classroomsSectionLocation => 'Location';

  @override
  String get classroomsGrade => 'Grade';

  @override
  String get classroomsBook => 'Book';

  @override
  String get classroomsCommission => 'Commission';

  @override
  String get classroomsCourseDays => 'Course days';

  @override
  String get classroomsNoDescription => 'No description';

  @override
  String get classroomsNoStudents => 'No students';

  @override
  String get classroomsNoProfessors => 'No professors';

  @override
  String get classroomsNoMaterials => 'No materials';

  @override
  String get classroomsRelatedLoadError => 'Could not load data';

  @override
  String classroomsMaterialDownloads(int count) {
    return '$count downloads';
  }

  @override
  String get studentsTitle => 'Students';

  @override
  String get studentsSearchHint => 'Search students...';

  @override
  String get studentsFilterAll => 'All';

  @override
  String get studentsFilterActive => 'Active';

  @override
  String get studentsFilterInactive => 'Inactive';

  @override
  String get studentsFilterYear => 'Year';

  @override
  String get studentsFilterBranch => 'Branch';

  @override
  String studentsFilterOptionAll(String label) {
    return '$label: All';
  }

  @override
  String studentsFilterOption(String label, String value) {
    return '$label: $value';
  }

  @override
  String get studentsLoadError => 'Failed to load students';

  @override
  String get studentsEmptyTitle => 'No students found';

  @override
  String get studentsEmptySearch => 'Try a different search term';

  @override
  String get studentsEmptyFilters => 'No students match the selected filters';

  @override
  String get studentsDetailFallbackTitle => 'Student';

  @override
  String get studentsDetailLoadError => 'Failed to load student';

  @override
  String get studentsTabGrades => 'Grades';

  @override
  String get studentsTabAbsences => 'Absences';

  @override
  String get studentsTabFees => 'Fees';

  @override
  String get studentsTabInfo => 'Info';

  @override
  String get studentsNoGrades => 'No grades available';

  @override
  String get studentsNoAbsences => 'No absences available';

  @override
  String get studentsNoFees => 'No fees available';

  @override
  String get studentsNoClassroom => 'No classroom';

  @override
  String get studentsInfoFullName => 'Full Name';

  @override
  String get studentsInfoEmail => 'Email';

  @override
  String get studentsInfoYear => 'Year';

  @override
  String get studentsInfoIdentityNumber => 'Identity Number';

  @override
  String get studentsInfoBranch => 'Branch';

  @override
  String get studentsInfoClassrooms => 'Classrooms';

  @override
  String get studentsSectionPersonal => 'Personal details';

  @override
  String get studentsSectionInstitutional => 'Institutional';

  @override
  String get studentsRelatedLoadError => 'Could not load data';

  @override
  String get studentsGradeTitle => 'Grade';

  @override
  String studentsGradePeriod(String period) {
    return 'Period $period';
  }

  @override
  String get gradesGridTitle => 'Grades by period';

  @override
  String get gradesGridPeriod => 'Period';

  @override
  String get gradesGridPerformance => 'Performance';

  @override
  String get gradesGridAttitude => 'Attitude';

  @override
  String get gradesGridWritten => 'Written';

  @override
  String get gradesGridOral => 'Oral';

  @override
  String get gradesGridHomework => 'Homework';

  @override
  String get gradesGridDiscipline => 'Discipline';

  @override
  String get gradesGridParticipation => 'Participation';

  @override
  String get gradesGridAttendance => 'Attendance';

  @override
  String get gradesGridExam => 'Midterm';

  @override
  String get gradesGridAverage => 'Average';

  @override
  String gradesGridTerm(int term) {
    return 'Term $term';
  }

  @override
  String get gradesGridClassroomFallback => 'Classroom';

  @override
  String get studentsAbsenceTitle => 'Absence';

  @override
  String get studentsStatusApproved => 'Approved';

  @override
  String get studentsStatusPending => 'Pending';

  @override
  String get studentsStatusRejected => 'Rejected';

  @override
  String get feesStatusPaid => 'Paid';

  @override
  String get feesStatusPartial => 'Partial';

  @override
  String get feesStatusPending => 'Pending';

  @override
  String get feesStatusOverdue => 'Overdue';

  @override
  String get studentsAbsenceJustified => 'Justified';

  @override
  String get studentsAbsenceUnjustified => 'Unjustified';

  @override
  String get studentsAbsencePending => 'Pending';

  @override
  String get feesTitle => 'Fees';

  @override
  String get feesSearchHint => 'Search fees...';

  @override
  String get feesLoadError => 'Failed to load fees';

  @override
  String get feesEmptyTitle => 'No fees found';

  @override
  String get feesEmptySearchSubtitle => 'Try a different search term';

  @override
  String get feesEmptySubtitle => 'No fees available';

  @override
  String feesDetailTitle(int number) {
    return 'Fee #$number';
  }

  @override
  String get feesDetailFallbackTitle => 'Fee';

  @override
  String get feesDetailLoadError => 'Failed to load fee';

  @override
  String get feesDetailFeeNumber => 'Fee Number';

  @override
  String get feesDetailMonth => 'Month';

  @override
  String get feesDetailYear => 'Year';

  @override
  String get feesDetailToPay => 'To Pay';

  @override
  String get feesDetailPaid => 'Paid';

  @override
  String get feesDetailTotal => 'Total';

  @override
  String get feesDetailStatus => 'Status';

  @override
  String get feesDetailPaymentMethod => 'Payment Method';

  @override
  String get feesDetailPaymentDate => 'Payment Date';

  @override
  String get feesUnknownStudent => 'Unknown';

  @override
  String feesCardSubtitle(int number, String month, String year) {
    return 'Fee #$number · $month $year';
  }

  @override
  String get qualificationsTitle => 'Qualifications';

  @override
  String get qualificationsSearchHint => 'Search qualifications...';

  @override
  String get qualificationsLoadError => 'Failed to load qualifications';

  @override
  String get qualificationsEmptyTitle => 'No qualifications found';

  @override
  String get qualificationsEmptySearchSubtitle => 'Try a different search term';

  @override
  String get qualificationsEmptySubtitle => 'No qualifications available';

  @override
  String get qualificationsUnknownStudent => 'Unknown Student';

  @override
  String get qualificationsUnknownClassroom => 'Unknown Classroom';

  @override
  String get notificationsMarkAllRead => 'Mark all read';

  @override
  String get notificationsLoadError => 'Failed to load notifications';

  @override
  String get notificationsEmptyTitle => 'No notifications';

  @override
  String get notificationsEmptySubtitle => 'You\'re all caught up!';

  @override
  String get notificationsToday => 'Today';

  @override
  String get notificationsYesterday => 'Yesterday';

  @override
  String get notificationsEarlier => 'Earlier';

  @override
  String get chatLoadError => 'Failed to load chats';

  @override
  String get chatEmptyTitle => 'No conversations';

  @override
  String get chatEmptySubtitle => 'Start a conversation with your classmates';

  @override
  String get chatMessagesLoadError => 'Failed to load messages';

  @override
  String get chatMessagesEmpty => 'No messages yet\nStart the conversation!';

  @override
  String get chatInputHint => 'Type a message...';

  @override
  String get chatTimeNow => 'Now';

  @override
  String chatTimeMinutesShort(int count) {
    return '${count}m';
  }

  @override
  String get chatNewTitle => 'New chat';

  @override
  String get chatNewSearchHint => 'Search people…';

  @override
  String get chatNewEmptyTitle => 'No linked people';

  @override
  String get chatNewEmptySubtitle => 'You don\'t have anyone to chat with yet';

  @override
  String chatNewNoResults(String query) {
    return 'No results for “$query”';
  }

  @override
  String get chatNewStart => 'Start conversation';

  @override
  String get relationRoleStudent => 'Student';

  @override
  String get relationRoleProfessor => 'Professor';

  @override
  String get relationRoleParent => 'Parent';

  @override
  String get relationRoleAdmin => 'Admin';

  @override
  String get chatTyping => 'typing…';

  @override
  String get chatOnline => 'online';

  @override
  String get chatConnectionLost => 'Offline — tap to retry';

  @override
  String get chatSendFailed => 'Couldn\'t send';

  @override
  String get chatRetry => 'Retry';

  @override
  String chatUnreadLabel(int count) {
    return '$count unread messages';
  }

  @override
  String get newsTitle => 'News';

  @override
  String get newsErrorTitle => 'Failed to load news';

  @override
  String get newsEmptyTitle => 'No news';

  @override
  String get newsEmptySubtitle => 'Check back later for updates';

  @override
  String get eventsTitle => 'Events';

  @override
  String get eventsErrorTitle => 'Failed to load events';

  @override
  String get eventsEmptyTitle => 'No events';

  @override
  String get eventsEmptySubtitle => 'No upcoming events scheduled';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchHint => 'Search students, classrooms, news...';

  @override
  String get searchErrorTitle => 'Search failed';

  @override
  String get searchEmptySubtitle => 'Search for students, classrooms, or news';

  @override
  String get searchNoResultsTitle => 'No results';

  @override
  String searchNoResultsSubtitle(String query) {
    return 'No results found for \"$query\"';
  }

  @override
  String get professorGreetingMorning => 'Good morning';

  @override
  String get professorGreetingAfternoon => 'Good afternoon';

  @override
  String get professorGreetingEvening => 'Good evening';

  @override
  String professorHomeTitle(String name) {
    return 'Prof. $name';
  }

  @override
  String get professorStatClassrooms => 'Classrooms';

  @override
  String get professorStatStudents => 'Students';

  @override
  String get professorStatAbsences => 'Absent today';

  @override
  String get professorMyClassrooms => 'My classrooms';

  @override
  String get professorMyClassroomsEmpty => 'You have no classrooms assigned yet';

  @override
  String professorClassroomsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count classrooms',
      one: '1 classroom',
      zero: 'No classrooms assigned',
    );
    return '$_temp0';
  }

  @override
  String professorStudentsCount(int count) {
    return '$count students';
  }

  @override
  String get professorTakeAttendance => 'Take attendance';

  @override
  String get professorLoadGrade => 'Add grade';

  @override
  String get professorLoadError => 'Failed to load the home screen';

  @override
  String get homeCalendar => 'Calendar';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeCalendarEmpty => 'No upcoming events';

  @override
  String get homeBirthdays => 'Birthdays';

  @override
  String get homeBirthdaysEmpty => 'No birthdays today';

  @override
  String get homeBirthdaysSoon => 'Coming soon';

  @override
  String attendanceTitle(String classroom) {
    return 'Attendance · $classroom';
  }

  @override
  String attendanceSubtitle(String date, int count) {
    return '$date · $count students';
  }

  @override
  String get attendancePresent => 'P';

  @override
  String get attendanceAbsent => 'A';

  @override
  String get attendanceToday => 'Today';

  @override
  String get attendanceSave => 'Save attendance';

  @override
  String get attendanceSaved => 'Attendance saved';

  @override
  String get attendanceLoadError => 'Failed to load attendance';

  @override
  String get attendanceSaveError => 'Failed to save attendance';

  @override
  String get attendanceEmpty => 'This classroom has no students';

  @override
  String get attendanceUnsavedTitle => 'Unsaved changes';

  @override
  String get attendanceUnsavedMessage => 'If you leave now, attendance changes will be lost.';

  @override
  String get attendanceUnsavedStay => 'Stay';

  @override
  String get attendanceUnsavedLeave => 'Leave without saving';

  @override
  String get gradesTitle => 'Grades';

  @override
  String get gradesClassroomAverage => 'Classroom average';

  @override
  String get gradesLoadGrade => '+ Add grade';

  @override
  String get gradesLoadError => 'Failed to load grades';

  @override
  String get gradeFormTitle => 'Add grade';

  @override
  String get gradeFormStudent => 'Student';

  @override
  String get gradeFormType => 'Type';

  @override
  String get gradeFormPeriod => 'Period';

  @override
  String get gradeFormScore => 'Grade';

  @override
  String get gradeFormScoreHint => 'e.g. 8.5';

  @override
  String get gradeFormDescription => 'Description (optional)';

  @override
  String get gradeFormSave => 'Save';

  @override
  String get gradeFormScoreInvalid => 'Enter a grade between 0 and 10';

  @override
  String get gradeFormSaved => 'Grade saved';

  @override
  String get gradeFormError => 'Failed to save the grade';

  @override
  String get studentGradeFromDetail => 'Add grade';

  @override
  String get studentGradeClassroom => 'Classroom';

  @override
  String get studentGradeNoClassrooms => 'No classrooms assigned';

  @override
  String get absenceMarkTitle => 'Mark absence';

  @override
  String get absenceMarkClassroom => 'Classroom';

  @override
  String get absenceMarkDate => 'Date';

  @override
  String get absenceMarkInfo => 'Adds to the day\'s roll without removing the other absent students.';

  @override
  String get absenceMarked => 'Absence recorded';

  @override
  String get absenceAlreadyMarked => 'Already marked absent that day';

  @override
  String get absenceMarkError => 'Could not record the absence';

  @override
  String get materialFormTitleNew => 'New material';

  @override
  String get materialFormTitleEdit => 'Edit material';

  @override
  String get materialFormName => 'Name';

  @override
  String get materialFormCategory => 'Category';

  @override
  String get materialFormCategoryNone => 'No category';

  @override
  String get materialFormDescription => 'Description (optional)';

  @override
  String get materialFormFiles => 'Files';

  @override
  String get materialFormPickFiles => 'Choose files';

  @override
  String get materialFormVisibility => 'Visibility';

  @override
  String get materialFormVisibilityAll => 'Everyone';

  @override
  String get materialFormVisibilitySpecific => 'Specific students';

  @override
  String get materialFormAvailableUntil => 'Available until (optional)';

  @override
  String get materialFormClearDate => 'Clear date';

  @override
  String get materialFormSave => 'Save';

  @override
  String get materialFormNameRequired => 'Enter a name';

  @override
  String get materialFormFilesRequired => 'Choose at least one file';

  @override
  String get materialFormFilesTooMany => 'Maximum 10 files';

  @override
  String get materialFormFileTooLarge => 'Each file can weigh up to 50 MB';

  @override
  String get materialFormStudentsRequired => 'Choose at least one student';

  @override
  String get materialFormError => 'Could not save the material';

  @override
  String get materialFormDetailError => 'Could not load the material';

  @override
  String get materialsAdd => 'Add material';

  @override
  String get materialsCreated => 'Material published';

  @override
  String get materialsUpdated => 'Material updated';

  @override
  String get materialsDeleted => 'Material deleted';

  @override
  String get materialsDeleteError => 'Could not delete the material';

  @override
  String get materialsEdit => 'Edit';

  @override
  String get materialsDelete => 'Delete';

  @override
  String get materialsDeleteTitle => 'Delete material?';

  @override
  String get materialsDeleteMessage => 'Its files will also be deleted.';

  @override
  String get materialsDeleteCancel => 'Cancel';

  @override
  String get materialsDeleteConfirm => 'Delete';

  @override
  String materialsStudentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students',
      one: '1 student',
    );
    return '$_temp0';
  }

  @override
  String get documentsTitle => 'Documents';

  @override
  String get documentsEmpty => 'No documents';

  @override
  String get documentsOpen => 'Open / Download';

  @override
  String get documentsOpenError => 'Could not open the document';

  @override
  String get homeDocuments => 'Documents';

  @override
  String get homeNews => 'News';

  @override
  String get homeNewsEmpty => 'No news yet';

  @override
  String homeSummaryDocumentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents',
      one: '1 document',
    );
    return '$_temp0';
  }

  @override
  String homeSummaryBirthdaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count today',
      one: '1 today',
    );
    return '$_temp0';
  }

  @override
  String get calendarViewList => 'View list';

  @override
  String get parentGreeting => 'Hi';

  @override
  String parentFamilyTitle(String surname) {
    return 'The $surname Family';
  }

  @override
  String parentOverdueFeesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count overdue installments',
      one: '1 overdue installment',
    );
    return '$_temp0';
  }

  @override
  String get parentMoraTotal => 'Total overdue';

  @override
  String get parentPayAction => 'Pay';

  @override
  String get navPayments => 'Payments';

  @override
  String get parentActionBoletin => 'Report Card';

  @override
  String get parentChooseChild => 'Choose a child';

  @override
  String get feesUploadProofAction => 'Upload receipt';

  @override
  String get feesReplaceProofAction => 'Replace receipt';

  @override
  String get feesInvoiceAction => 'View invoice';

  @override
  String get feesInvoiceUnavailable => 'Invoice unavailable';

  @override
  String get feesChooseFeeTitle => 'Choose the installment';

  @override
  String get feesProofStatusReview => 'Receipt under review';

  @override
  String get feesProofPickFile => 'Choose file';

  @override
  String get feesProofHint => 'JPG, PNG or PDF · up to 10 MB';

  @override
  String get feesProofSuccess => 'Receipt uploaded. An administrator will review it.';

  @override
  String get feesProofError => 'Could not upload the receipt';

  @override
  String get feesStatusUnderReview => 'Under review';

  @override
  String feesPartialOwed(String amount) {
    return 'owes $amount';
  }
}
