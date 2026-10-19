import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonSearchHint => 'Buscar...';

  @override
  String get commonUser => 'Usuario';

  @override
  String get navHome => 'Inicio';

  @override
  String get navClasses => 'Aulas';

  @override
  String get navChat => 'Chat';

  @override
  String get navProfile => 'Perfil';

  @override
  String get authWelcomeBack => 'Bienvenido de nuevo';

  @override
  String get authSignInSubtitle => 'Iniciá sesión en tu cuenta';

  @override
  String get authEmailLabel => 'Correo electrónico';

  @override
  String get authEmailRequired => 'El correo electrónico es obligatorio';

  @override
  String get authEmailInvalid => 'Ingresá un correo electrónico válido';

  @override
  String get authPasswordLabel => 'Contraseña';

  @override
  String get authPasswordRequired => 'La contraseña es obligatoria';

  @override
  String get authForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get authSignIn => 'Iniciar sesión';

  @override
  String get authForgotPasswordTitle => 'Recuperar contraseña';

  @override
  String get authResetSubtitle => 'Restablecé tu contraseña';

  @override
  String get authCheckEmail => 'Revisá tu correo';

  @override
  String get authResetInstructions => 'Ingresá tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.';

  @override
  String authResetLinkSent(String email) {
    return 'Te enviamos un enlace para restablecer tu contraseña a\n$email';
  }

  @override
  String get authSendResetLink => 'Enviar enlace de restablecimiento';

  @override
  String get authBackToSignIn => 'Volver a iniciar sesión';

  @override
  String get validationRequired => 'Obligatorio';

  @override
  String get validationInvalidEmail => 'Correo electrónico inválido';

  @override
  String get validationPasswordLength => 'La contraseña debe tener al menos 8 caracteres';

  @override
  String get validationPasswordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String validationFieldRequired(String field) {
    return '$field es obligatorio';
  }

  @override
  String get timeJustNow => 'Justo ahora';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hace $count minutos',
      one: 'Hace 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hace $count horas',
      one: 'Hace 1 hora',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hace $count días',
      one: 'Hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get profileAccount => 'Cuenta';

  @override
  String get profileEditProfile => 'Editar perfil';

  @override
  String get profileNotifications => 'Notificaciones';

  @override
  String get profilePreferences => 'Preferencias';

  @override
  String get profileTheme => 'Tema';

  @override
  String get profileSelectTheme => 'Seleccionar tema';

  @override
  String get profileThemeLight => 'Claro';

  @override
  String get profileThemeDark => 'Oscuro';

  @override
  String get profileThemeSystem => 'Sistema';

  @override
  String get profileLanguage => 'Idioma';

  @override
  String get profileSelectLanguage => 'Seleccionar idioma';

  @override
  String get profileAbout => 'Acerca de';

  @override
  String get profileHelpSupport => 'Ayuda y soporte';

  @override
  String get profileLogout => 'Cerrar sesión';

  @override
  String get profileLogoutConfirm => '¿Estás seguro de que querés cerrar sesión?';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get roleAdmin => 'Administrador';

  @override
  String get roleBranch => 'Director de sede';

  @override
  String get roleProfessor => 'Profesor';

  @override
  String get roleParent => 'Tutor';

  @override
  String get roleStudent => 'Estudiante';

  @override
  String get dashboardLoadError => 'No se pudo cargar el panel principal';

  @override
  String get dashboardQuickActions => 'Acciones rápidas';

  @override
  String get dashboardStudents => 'Estudiantes';

  @override
  String get dashboardNews => 'Novedades';

  @override
  String get dashboardEvents => 'Eventos';

  @override
  String get dashboardFees => 'Cuotas';

  @override
  String get dashboardSearch => 'Buscar';

  @override
  String dashboardWelcome(String name) {
    return '¡Hola, $name!';
  }

  @override
  String get dashboardClassrooms => 'Clases';

  @override
  String get dashboardAttendance => 'Asistencia';

  @override
  String get dashboardPendingFees => 'Cuotas pendientes';

  @override
  String get classroomsTitle => 'Clases';

  @override
  String get classroomsSearchHint => 'Buscar clases...';

  @override
  String get classroomsLoadError => 'No se pudieron cargar las clases';

  @override
  String get classroomsEmptyTitle => 'No se encontraron clases';

  @override
  String get classroomsEmptyFiltered => 'Intentá ajustar o limpiar los filtros';

  @override
  String get classroomsEmptySearch => 'Intentá con otro término de búsqueda';

  @override
  String get classroomsEmptySubtitle => 'No hay clases disponibles';

  @override
  String get classroomsClearFilters => 'Limpiá los filtros';

  @override
  String get classroomsDetailTitle => 'Clase';

  @override
  String get classroomsDetailLoadError => 'No se pudo cargar la clase';

  @override
  String get classroomsName => 'Nombre';

  @override
  String get classroomsDescription => 'Descripción';

  @override
  String get classroomsStatus => 'Estado';

  @override
  String get classroomsShift => 'Turno';

  @override
  String get classroomsDay => 'Día';

  @override
  String get classroomsHour => 'Horario';

  @override
  String get classroomsRoom => 'Aula';

  @override
  String get classroomsYear => 'Año';

  @override
  String get classroomsBranch => 'Sucursal';

  @override
  String get classroomsLevel => 'Nivel';

  @override
  String get classroomsStudents => 'Estudiantes';

  @override
  String get classroomsFiltersTitle => 'Filtros';

  @override
  String get classroomsFilterClearAll => 'Limpiá todo';

  @override
  String get classroomsFilterApply => 'Aplicar filtros';

  @override
  String get classroomsFilterClear => 'Limpiá';

  @override
  String get classroomsStatusActive => 'Activo';

  @override
  String get classroomsStatusArchived => 'Archivado';

  @override
  String get classroomsFiltersLoadError => 'No se pudieron cargar los filtros';

  @override
  String get classroomsFiltersLoadErrorDetail => 'Revisá tu conexión e intentá de nuevo.';

  @override
  String classroomsFilterChipBranch(String value) {
    return 'Sucursal: $value';
  }

  @override
  String classroomsFilterChipLevel(String value) {
    return 'Nivel: $value';
  }

  @override
  String classroomsFilterChipYear(String value) {
    return 'Año: $value';
  }

  @override
  String classroomsFilterChipStatus(String value) {
    return 'Estado: $value';
  }

  @override
  String paginationShowing(int from, int to, int total) {
    return 'Mostrando $from–$to de $total';
  }

  @override
  String get paginationPrevious => 'Página anterior';

  @override
  String get paginationNext => 'Página siguiente';

  @override
  String paginationPage(int page) {
    return 'Página $page';
  }

  @override
  String get classroomsTabSummary => 'Resumen';

  @override
  String get classroomsTabStudents => 'Estudiantes';

  @override
  String get classroomsTabProfessors => 'Profesores';

  @override
  String get classroomsTabMaterials => 'Materiales';

  @override
  String get classroomsSectionSchedule => 'Horario';

  @override
  String get classroomsSectionAcademic => 'Académico';

  @override
  String get classroomsSectionLocation => 'Ubicación';

  @override
  String get classroomsGrade => 'Grado';

  @override
  String get classroomsBook => 'Libro';

  @override
  String get classroomsCommission => 'Comisión';

  @override
  String get classroomsCourseDays => 'Días de cursada';

  @override
  String get classroomsNoDescription => 'Sin descripción';

  @override
  String get classroomsNoStudents => 'Sin estudiantes';

  @override
  String get classroomsNoProfessors => 'Sin profesores';

  @override
  String get classroomsNoMaterials => 'Sin materiales';

  @override
  String get classroomsRelatedLoadError => 'No se pudieron cargar los datos';

  @override
  String classroomsMaterialDownloads(int count) {
    return '$count descargas';
  }

  @override
  String get studentsTitle => 'Estudiantes';

  @override
  String get studentsSearchHint => 'Buscar estudiantes...';

  @override
  String get studentsFilterAll => 'Todos';

  @override
  String get studentsFilterActive => 'Activos';

  @override
  String get studentsFilterInactive => 'Inactivos';

  @override
  String get studentsFilterYear => 'Año';

  @override
  String get studentsFilterBranch => 'Sede';

  @override
  String studentsFilterOptionAll(String label) {
    return '$label: Todos';
  }

  @override
  String studentsFilterOption(String label, String value) {
    return '$label: $value';
  }

  @override
  String get studentsLoadError => 'No se pudieron cargar los estudiantes';

  @override
  String get studentsEmptyTitle => 'No se encontraron estudiantes';

  @override
  String get studentsEmptySearch => 'Probá con otro término de búsqueda';

  @override
  String get studentsEmptyFilters => 'Ningún estudiante coincide con los filtros seleccionados';

  @override
  String get studentsDetailFallbackTitle => 'Estudiante';

  @override
  String get studentsDetailLoadError => 'No se pudo cargar el estudiante';

  @override
  String get studentsTabGrades => 'Notas';

  @override
  String get studentsTabAbsences => 'Inasistencias';

  @override
  String get studentsTabFees => 'Cuotas';

  @override
  String get studentsTabInfo => 'Información';

  @override
  String get studentsNoGrades => 'No hay notas disponibles';

  @override
  String get studentsNoAbsences => 'No hay inasistencias registradas';

  @override
  String get studentsNoFees => 'No hay cuotas disponibles';

  @override
  String get studentsNoClassroom => 'Sin clases';

  @override
  String get studentsInfoFullName => 'Nombre completo';

  @override
  String get studentsInfoEmail => 'Correo electrónico';

  @override
  String get studentsInfoYear => 'Año';

  @override
  String get studentsInfoIdentityNumber => 'Número de documento';

  @override
  String get studentsInfoBranch => 'Sede';

  @override
  String get studentsInfoClassrooms => 'Clases';

  @override
  String get studentsSectionPersonal => 'Datos personales';

  @override
  String get studentsSectionInstitutional => 'Institucional';

  @override
  String get studentsRelatedLoadError => 'No se pudieron cargar los datos';

  @override
  String get studentsGradeTitle => 'Nota';

  @override
  String studentsGradePeriod(String period) {
    return 'Período $period';
  }

  @override
  String get gradesGridTitle => 'Calificaciones por período';

  @override
  String get gradesGridPeriod => 'Período';

  @override
  String get gradesGridPerformance => 'Desempeño';

  @override
  String get gradesGridAttitude => 'Actitud';

  @override
  String get gradesGridWritten => 'Escrito';

  @override
  String get gradesGridOral => 'Oral';

  @override
  String get gradesGridHomework => 'Tareas';

  @override
  String get gradesGridDiscipline => 'Disciplina';

  @override
  String get gradesGridParticipation => 'Participación';

  @override
  String get gradesGridAttendance => 'Asistencia';

  @override
  String get gradesGridExam => 'Parcial';

  @override
  String get gradesGridAverage => 'Promedio';

  @override
  String gradesGridTerm(int term) {
    return '$term° Trimestre';
  }

  @override
  String get gradesGridClassroomFallback => 'Aula';

  @override
  String get studentsAbsenceTitle => 'Inasistencia';

  @override
  String get studentsStatusApproved => 'Aprobado';

  @override
  String get studentsStatusPending => 'Pendiente';

  @override
  String get studentsStatusRejected => 'Rechazado';

  @override
  String get feesStatusPaid => 'Pagado';

  @override
  String get feesStatusPartial => 'Parcial';

  @override
  String get feesStatusPending => 'Pendiente';

  @override
  String get feesStatusOverdue => 'Vencido';

  @override
  String get studentsAbsenceJustified => 'Justificada';

  @override
  String get studentsAbsenceUnjustified => 'Sin justificar';

  @override
  String get studentsAbsencePending => 'Pendiente';

  @override
  String get feesTitle => 'Cuotas';

  @override
  String get feesSearchHint => 'Buscar cuotas...';

  @override
  String get feesLoadError => 'No se pudieron cargar las cuotas';

  @override
  String get feesEmptyTitle => 'No se encontraron cuotas';

  @override
  String get feesEmptySearchSubtitle => 'Probá con otro término de búsqueda';

  @override
  String get feesEmptySubtitle => 'No hay cuotas disponibles';

  @override
  String feesDetailTitle(int number) {
    return 'Cuota #$number';
  }

  @override
  String get feesDetailFallbackTitle => 'Cuota';

  @override
  String get feesDetailLoadError => 'No se pudo cargar la cuota';

  @override
  String get feesDetailFeeNumber => 'Número de cuota';

  @override
  String get feesDetailMonth => 'Mes';

  @override
  String get feesDetailYear => 'Año';

  @override
  String get feesDetailToPay => 'A pagar';

  @override
  String get feesDetailPaid => 'Pagado';

  @override
  String get feesDetailTotal => 'Total';

  @override
  String get feesDetailStatus => 'Estado';

  @override
  String get feesDetailPaymentMethod => 'Método de pago';

  @override
  String get feesDetailPaymentDate => 'Fecha de pago';

  @override
  String get feesUnknownStudent => 'Desconocido';

  @override
  String feesCardSubtitle(int number, String month, String year) {
    return 'Cuota #$number · $month $year';
  }

  @override
  String get qualificationsTitle => 'Calificaciones';

  @override
  String get qualificationsSearchHint => 'Buscar calificaciones...';

  @override
  String get qualificationsLoadError => 'No se pudieron cargar las calificaciones';

  @override
  String get qualificationsEmptyTitle => 'No se encontraron calificaciones';

  @override
  String get qualificationsEmptySearchSubtitle => 'Probá con otro término de búsqueda';

  @override
  String get qualificationsEmptySubtitle => 'No hay calificaciones disponibles';

  @override
  String get qualificationsUnknownStudent => 'Estudiante desconocido';

  @override
  String get qualificationsUnknownClassroom => 'Clase desconocida';

  @override
  String get notificationsMarkAllRead => 'Marcar todas como leídas';

  @override
  String get notificationsLoadError => 'No se pudieron cargar las notificaciones';

  @override
  String get notificationsEmptyTitle => 'No hay notificaciones';

  @override
  String get notificationsEmptySubtitle => '¡Estás al día!';

  @override
  String get notificationsToday => 'Hoy';

  @override
  String get notificationsYesterday => 'Ayer';

  @override
  String get notificationsEarlier => 'Anteriores';

  @override
  String get chatLoadError => 'No se pudieron cargar los chats';

  @override
  String get chatEmptyTitle => 'No hay conversaciones';

  @override
  String get chatEmptySubtitle => 'Iniciá una conversación con tus compañeros';

  @override
  String get chatMessagesLoadError => 'No se pudieron cargar los mensajes';

  @override
  String get chatMessagesEmpty => 'Todavía no hay mensajes\n¡Iniciá la conversación!';

  @override
  String get chatInputHint => 'Escribí un mensaje...';

  @override
  String get chatTimeNow => 'Ahora';

  @override
  String chatTimeMinutesShort(int count) {
    return '${count}m';
  }

  @override
  String get chatNewTitle => 'Nuevo chat';

  @override
  String get chatNewSearchHint => 'Buscar persona…';

  @override
  String get chatNewEmptyTitle => 'Sin personas vinculadas';

  @override
  String get chatNewEmptySubtitle => 'Todavía no tenés personas con las que chatear';

  @override
  String chatNewNoResults(String query) {
    return 'Sin resultados para «$query»';
  }

  @override
  String get chatNewStart => 'Iniciar conversación';

  @override
  String get relationRoleStudent => 'Alumno';

  @override
  String get relationRoleProfessor => 'Profesor';

  @override
  String get relationRoleParent => 'Padre/Madre';

  @override
  String get relationRoleAdmin => 'Admin';

  @override
  String get chatTyping => 'escribiendo…';

  @override
  String get chatOnline => 'en línea';

  @override
  String get chatConnectionLost => 'Sin conexión — tocá para reintentar';

  @override
  String get chatSendFailed => 'No se pudo enviar';

  @override
  String get chatRetry => 'Reintentar';

  @override
  String chatUnreadLabel(int count) {
    return '$count mensajes sin leer';
  }

  @override
  String get newsTitle => 'Noticias';

  @override
  String get newsErrorTitle => 'No se pudieron cargar las noticias';

  @override
  String get newsEmptyTitle => 'No hay noticias';

  @override
  String get newsEmptySubtitle => 'Volvé más tarde para ver novedades';

  @override
  String get eventsTitle => 'Eventos';

  @override
  String get eventsErrorTitle => 'No se pudieron cargar los eventos';

  @override
  String get eventsEmptyTitle => 'No hay eventos';

  @override
  String get eventsEmptySubtitle => 'No hay próximos eventos programados';

  @override
  String get searchTitle => 'Buscar';

  @override
  String get searchHint => 'Buscar estudiantes, clases, noticias...';

  @override
  String get searchErrorTitle => 'Error en la búsqueda';

  @override
  String get searchEmptySubtitle => 'Buscá estudiantes, clases o noticias';

  @override
  String get searchNoResultsTitle => 'Sin resultados';

  @override
  String searchNoResultsSubtitle(String query) {
    return 'No se encontraron resultados para \"$query\"';
  }

  @override
  String get professorGreetingMorning => 'Buen día';

  @override
  String get professorGreetingAfternoon => 'Buenas tardes';

  @override
  String get professorGreetingEvening => 'Buenas noches';

  @override
  String professorHomeTitle(String name) {
    return 'Prof. $name';
  }

  @override
  String get professorStatClassrooms => 'Aulas';

  @override
  String get professorStatStudents => 'Alumnos';

  @override
  String get professorStatAbsences => 'Ausentes';

  @override
  String get professorMyClassrooms => 'Mis aulas';

  @override
  String get professorMyClassroomsEmpty => 'Todavía no tenés aulas asignadas';

  @override
  String professorClassroomsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aulas',
      one: '1 aula',
      zero: 'Sin aulas asignadas',
    );
    return '$_temp0';
  }

  @override
  String professorStudentsCount(int count) {
    return '$count alumnos';
  }

  @override
  String get professorTakeAttendance => 'Tomar asistencia';

  @override
  String get professorLoadGrade => 'Cargar nota';

  @override
  String get professorLoadError => 'No se pudo cargar el inicio';

  @override
  String get homeCalendar => 'Calendario';

  @override
  String get homeSeeAll => 'Ver todo';

  @override
  String get homeCalendarEmpty => 'No hay próximos eventos';

  @override
  String get homeBirthdays => 'Cumpleaños';

  @override
  String get homeBirthdaysEmpty => 'No hay cumpleaños hoy';

  @override
  String get homeBirthdaysSoon => 'Disponible próximamente';

  @override
  String attendanceTitle(String classroom) {
    return 'Asistencia · $classroom';
  }

  @override
  String attendanceSubtitle(String date, int count) {
    return '$date · $count alumnos';
  }

  @override
  String get attendancePresent => 'P';

  @override
  String get attendanceAbsent => 'A';

  @override
  String get attendanceToday => 'Hoy';

  @override
  String get attendanceSave => 'Guardar asistencia';

  @override
  String get attendanceSaved => 'Asistencia guardada';

  @override
  String get attendanceLoadError => 'No se pudo cargar la asistencia';

  @override
  String get attendanceSaveError => 'No se pudo guardar la asistencia';

  @override
  String get attendanceEmpty => 'Este aula no tiene alumnos';

  @override
  String get attendanceUnsavedTitle => 'Cambios sin guardar';

  @override
  String get attendanceUnsavedMessage => 'Si salís ahora, se perderán los cambios de asistencia.';

  @override
  String get attendanceUnsavedStay => 'Seguir acá';

  @override
  String get attendanceUnsavedLeave => 'Salir sin guardar';

  @override
  String get gradesTitle => 'Calificaciones';

  @override
  String get gradesClassroomAverage => 'Promedio del aula';

  @override
  String get gradesLoadGrade => '+ Cargar calificación';

  @override
  String get gradesLoadError => 'No se pudieron cargar las calificaciones';

  @override
  String get gradeFormTitle => 'Cargar calificación';

  @override
  String get gradeFormStudent => 'Alumno';

  @override
  String get gradeFormType => 'Tipo';

  @override
  String get gradeFormPeriod => 'Período';

  @override
  String get gradeFormScore => 'Nota';

  @override
  String get gradeFormScoreHint => 'Ej: 8.5';

  @override
  String get gradeFormDescription => 'Descripción (opcional)';

  @override
  String get gradeFormSave => 'Guardar';

  @override
  String get gradeFormScoreInvalid => 'Ingresá una nota entre 0 y 10';

  @override
  String get gradeFormSaved => 'Calificación guardada';

  @override
  String get gradeFormError => 'No se pudo guardar la calificación';

  @override
  String get studentGradeFromDetail => 'Cargar nota';

  @override
  String get studentGradeClassroom => 'Aula';

  @override
  String get studentGradeNoClassrooms => 'Sin aulas asignadas';

  @override
  String get absenceMarkTitle => 'Marcar inasistencia';

  @override
  String get absenceMarkClassroom => 'Aula';

  @override
  String get absenceMarkDate => 'Fecha';

  @override
  String get absenceMarkInfo => 'Se agrega al parte del día sin quitar a los demás ausentes.';

  @override
  String get absenceMarked => 'Inasistencia registrada';

  @override
  String get absenceAlreadyMarked => 'Ya estaba ausente ese día';

  @override
  String get absenceMarkError => 'No se pudo registrar la inasistencia';

  @override
  String get materialFormTitleNew => 'Nuevo material';

  @override
  String get materialFormTitleEdit => 'Editar material';

  @override
  String get materialFormName => 'Nombre';

  @override
  String get materialFormCategory => 'Categoría';

  @override
  String get materialFormCategoryNone => 'Sin categoría';

  @override
  String get materialFormDescription => 'Descripción (opcional)';

  @override
  String get materialFormFiles => 'Archivos';

  @override
  String get materialFormPickFiles => 'Elegir archivos';

  @override
  String get materialFormVisibility => 'Visibilidad';

  @override
  String get materialFormVisibilityAll => 'Todos';

  @override
  String get materialFormVisibilitySpecific => 'Alumnos específicos';

  @override
  String get materialFormAvailableUntil => 'Disponible hasta (opcional)';

  @override
  String get materialFormClearDate => 'Quitar fecha';

  @override
  String get materialFormSave => 'Guardar';

  @override
  String get materialFormNameRequired => 'Ingresá un nombre';

  @override
  String get materialFormFilesRequired => 'Elegí al menos un archivo';

  @override
  String get materialFormFilesTooMany => 'Máximo 10 archivos';

  @override
  String get materialFormFileTooLarge => 'Cada archivo puede pesar hasta 50 MB';

  @override
  String get materialFormStudentsRequired => 'Elegí al menos un alumno';

  @override
  String get materialFormError => 'No se pudo guardar el material';

  @override
  String get materialFormDetailError => 'No se pudo cargar el material';

  @override
  String get materialsAdd => 'Cargar material';

  @override
  String get materialsCreated => 'Material publicado';

  @override
  String get materialsUpdated => 'Material actualizado';

  @override
  String get materialsDeleted => 'Material eliminado';

  @override
  String get materialsDeleteError => 'No se pudo eliminar el material';

  @override
  String get materialsEdit => 'Editar';

  @override
  String get materialsDelete => 'Eliminar';

  @override
  String get materialsDeleteTitle => '¿Eliminar material?';

  @override
  String get materialsDeleteMessage => 'También se borran sus archivos.';

  @override
  String get materialsDeleteCancel => 'Cancelar';

  @override
  String get materialsDeleteConfirm => 'Eliminar';

  @override
  String materialsStudentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alumnos',
      one: '1 alumno',
    );
    return '$_temp0';
  }

  @override
  String get documentsTitle => 'Documentos';

  @override
  String get documentsEmpty => 'No hay documentos';

  @override
  String get documentsOpen => 'Abrir / Descargar';

  @override
  String get documentsOpenError => 'No se pudo abrir el documento';

  @override
  String get homeDocuments => 'Documentos';

  @override
  String get homeNews => 'Novedades';

  @override
  String get homeNewsEmpty => 'No hay novedades';

  @override
  String homeSummaryDocumentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documentos',
      one: '1 documento',
    );
    return '$_temp0';
  }

  @override
  String homeSummaryBirthdaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hoy',
      one: '1 hoy',
    );
    return '$_temp0';
  }

  @override
  String get calendarViewList => 'Ver lista';

  @override
  String get parentGreeting => 'Hola';

  @override
  String parentFamilyTitle(String surname) {
    return 'Familia $surname';
  }

  @override
  String parentOverdueFeesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cuotas vencidas',
      one: '1 cuota vencida',
    );
    return '$_temp0';
  }

  @override
  String get parentMoraTotal => 'Mora total';

  @override
  String get parentPayAction => 'Pagar';

  @override
  String get navPayments => 'Pagos';

  @override
  String get parentActionBoletin => 'Boletín';

  @override
  String get boletinTitle => 'Boletín';

  @override
  String get boletinDownloadAction => 'Descargar boletín (PDF)';

  @override
  String boletinPeriod(int n) {
    return '$n° Período';
  }

  @override
  String get boletinObservations => 'Observaciones';

  @override
  String get boletinNoGrades => 'No hay calificaciones registradas para este período';

  @override
  String get boletinNoAccess => 'No tenés acceso al boletín de este alumno';

  @override
  String get boletinDownloadError => 'No se pudo descargar el boletín';

  @override
  String get boletinViewAction => 'Ver boletín';

  @override
  String get parentChooseChild => 'Elegí un hijo';

  @override
  String get feesUploadProofAction => 'Subir comprobante';

  @override
  String get feesReplaceProofAction => 'Reemplazar comprobante';

  @override
  String get feesInvoiceAction => 'Ver factura';

  @override
  String get feesInvoiceUnavailable => 'Factura no disponible';

  @override
  String get feesInvoiceViewerTitle => 'Factura';

  @override
  String get feesInvoiceLoadError => 'No se pudo cargar la factura';

  @override
  String get feesInvoiceDownloadAction => 'Descargar';

  @override
  String get feesInvoiceDownloadSuccess => 'Factura descargada';

  @override
  String get feesInvoiceDownloadError => 'No se pudo descargar la factura';

  @override
  String get feesChooseFeeTitle => 'Elegí la cuota';

  @override
  String get feesProofStatusReview => 'Comprobante en revisión';

  @override
  String get feesProofPickFile => 'Elegir archivo';

  @override
  String get feesProofHint => 'JPG, PNG o PDF · hasta 10 MB';

  @override
  String get feesProofInvalidFile => 'Archivo no válido. JPG, PNG o PDF · hasta 10 MB';

  @override
  String get feesProofSuccess => 'Comprobante subido. Un administrador lo revisará.';

  @override
  String get feesProofError => 'No se pudo subir el comprobante';

  @override
  String get feesProofSubmit => 'Subir';

  @override
  String get feesStatusUnderReview => 'En revisión';

  @override
  String feesPartialOwed(String amount) {
    return 'debe $amount';
  }
}
