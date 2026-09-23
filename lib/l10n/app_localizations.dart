import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get commonRetry;

  /// No description provided for @commonSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar...'**
  String get commonSearchHint;

  /// No description provided for @commonUser.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get commonUser;

  /// No description provided for @navHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHome;

  /// No description provided for @navClasses.
  ///
  /// In es, this message translates to:
  /// **'Clases'**
  String get navClasses;

  /// No description provided for @navChat.
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @authWelcomeBack.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido de nuevo'**
  String get authWelcomeBack;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Iniciá sesión en tu cuenta'**
  String get authSignInSubtitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get authEmailLabel;

  /// No description provided for @authEmailRequired.
  ///
  /// In es, this message translates to:
  /// **'El correo electrónico es obligatorio'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresá un correo electrónico válido'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'La contraseña es obligatoria'**
  String get authPasswordRequired;

  /// No description provided for @authForgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get authForgotPassword;

  /// No description provided for @authSignIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get authSignIn;

  /// No description provided for @authForgotPasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Recuperar contraseña'**
  String get authForgotPasswordTitle;

  /// No description provided for @authResetSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Restablecé tu contraseña'**
  String get authResetSubtitle;

  /// No description provided for @authCheckEmail.
  ///
  /// In es, this message translates to:
  /// **'Revisá tu correo'**
  String get authCheckEmail;

  /// No description provided for @authResetInstructions.
  ///
  /// In es, this message translates to:
  /// **'Ingresá tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.'**
  String get authResetInstructions;

  /// No description provided for @authResetLinkSent.
  ///
  /// In es, this message translates to:
  /// **'Te enviamos un enlace para restablecer tu contraseña a\n{email}'**
  String authResetLinkSent(String email);

  /// No description provided for @authSendResetLink.
  ///
  /// In es, this message translates to:
  /// **'Enviar enlace de restablecimiento'**
  String get authSendResetLink;

  /// No description provided for @authBackToSignIn.
  ///
  /// In es, this message translates to:
  /// **'Volver a iniciar sesión'**
  String get authBackToSignIn;

  /// No description provided for @validationRequired.
  ///
  /// In es, this message translates to:
  /// **'Obligatorio'**
  String get validationRequired;

  /// No description provided for @validationInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico inválido'**
  String get validationInvalidEmail;

  /// No description provided for @validationPasswordLength.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 8 caracteres'**
  String get validationPasswordLength;

  /// No description provided for @validationPasswordsDoNotMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get validationPasswordsDoNotMatch;

  /// No description provided for @validationFieldRequired.
  ///
  /// In es, this message translates to:
  /// **'{field} es obligatorio'**
  String validationFieldRequired(String field);

  /// No description provided for @timeJustNow.
  ///
  /// In es, this message translates to:
  /// **'Justo ahora'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{Hace 1 minuto} other{Hace {count} minutos}}'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{Hace 1 hora} other{Hace {count} horas}}'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{Hace 1 día} other{Hace {count} días}}'**
  String timeDaysAgo(int count);

  /// No description provided for @profileAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get profileAccount;

  /// No description provided for @profileEditProfile.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get profileEditProfile;

  /// No description provided for @profileNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get profileNotifications;

  /// No description provided for @profilePreferences.
  ///
  /// In es, this message translates to:
  /// **'Preferencias'**
  String get profilePreferences;

  /// No description provided for @profileTheme.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get profileTheme;

  /// No description provided for @profileSelectTheme.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar tema'**
  String get profileSelectTheme;

  /// No description provided for @profileThemeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get profileThemeLight;

  /// No description provided for @profileThemeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get profileThemeDark;

  /// No description provided for @profileThemeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get profileThemeSystem;

  /// No description provided for @profileLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get profileLanguage;

  /// No description provided for @profileSelectLanguage.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar idioma'**
  String get profileSelectLanguage;

  /// No description provided for @profileAbout.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get profileAbout;

  /// No description provided for @profileHelpSupport.
  ///
  /// In es, this message translates to:
  /// **'Ayuda y soporte'**
  String get profileHelpSupport;

  /// No description provided for @profileLogout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get profileLogout;

  /// No description provided for @profileLogoutConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que querés cerrar sesión?'**
  String get profileLogoutConfirm;

  /// No description provided for @languageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageEnglish.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @roleAdmin.
  ///
  /// In es, this message translates to:
  /// **'Administrador'**
  String get roleAdmin;

  /// No description provided for @roleBranch.
  ///
  /// In es, this message translates to:
  /// **'Director de sede'**
  String get roleBranch;

  /// No description provided for @roleProfessor.
  ///
  /// In es, this message translates to:
  /// **'Profesor'**
  String get roleProfessor;

  /// No description provided for @roleParent.
  ///
  /// In es, this message translates to:
  /// **'Tutor'**
  String get roleParent;

  /// No description provided for @roleStudent.
  ///
  /// In es, this message translates to:
  /// **'Estudiante'**
  String get roleStudent;

  /// No description provided for @dashboardLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el panel principal'**
  String get dashboardLoadError;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In es, this message translates to:
  /// **'Acciones rápidas'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardStudents.
  ///
  /// In es, this message translates to:
  /// **'Estudiantes'**
  String get dashboardStudents;

  /// No description provided for @dashboardNews.
  ///
  /// In es, this message translates to:
  /// **'Novedades'**
  String get dashboardNews;

  /// No description provided for @dashboardEvents.
  ///
  /// In es, this message translates to:
  /// **'Eventos'**
  String get dashboardEvents;

  /// No description provided for @dashboardFees.
  ///
  /// In es, this message translates to:
  /// **'Cuotas'**
  String get dashboardFees;

  /// No description provided for @dashboardSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get dashboardSearch;

  /// No description provided for @dashboardWelcome.
  ///
  /// In es, this message translates to:
  /// **'¡Hola, {name}!'**
  String dashboardWelcome(String name);

  /// No description provided for @dashboardClassrooms.
  ///
  /// In es, this message translates to:
  /// **'Clases'**
  String get dashboardClassrooms;

  /// No description provided for @dashboardAttendance.
  ///
  /// In es, this message translates to:
  /// **'Asistencia'**
  String get dashboardAttendance;

  /// No description provided for @dashboardPendingFees.
  ///
  /// In es, this message translates to:
  /// **'Cuotas pendientes'**
  String get dashboardPendingFees;

  /// No description provided for @classroomsTitle.
  ///
  /// In es, this message translates to:
  /// **'Clases'**
  String get classroomsTitle;

  /// No description provided for @classroomsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar clases...'**
  String get classroomsSearchHint;

  /// No description provided for @classroomsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las clases'**
  String get classroomsLoadError;

  /// No description provided for @classroomsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron clases'**
  String get classroomsEmptyTitle;

  /// No description provided for @classroomsEmptyFiltered.
  ///
  /// In es, this message translates to:
  /// **'Intentá ajustar o limpiar los filtros'**
  String get classroomsEmptyFiltered;

  /// No description provided for @classroomsEmptySearch.
  ///
  /// In es, this message translates to:
  /// **'Intentá con otro término de búsqueda'**
  String get classroomsEmptySearch;

  /// No description provided for @classroomsEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'No hay clases disponibles'**
  String get classroomsEmptySubtitle;

  /// No description provided for @classroomsClearFilters.
  ///
  /// In es, this message translates to:
  /// **'Limpiá los filtros'**
  String get classroomsClearFilters;

  /// No description provided for @classroomsDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Clase'**
  String get classroomsDetailTitle;

  /// No description provided for @classroomsDetailLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la clase'**
  String get classroomsDetailLoadError;

  /// No description provided for @classroomsName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get classroomsName;

  /// No description provided for @classroomsDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get classroomsDescription;

  /// No description provided for @classroomsStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get classroomsStatus;

  /// No description provided for @classroomsShift.
  ///
  /// In es, this message translates to:
  /// **'Turno'**
  String get classroomsShift;

  /// No description provided for @classroomsDay.
  ///
  /// In es, this message translates to:
  /// **'Día'**
  String get classroomsDay;

  /// No description provided for @classroomsHour.
  ///
  /// In es, this message translates to:
  /// **'Horario'**
  String get classroomsHour;

  /// No description provided for @classroomsRoom.
  ///
  /// In es, this message translates to:
  /// **'Aula'**
  String get classroomsRoom;

  /// No description provided for @classroomsYear.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get classroomsYear;

  /// No description provided for @classroomsBranch.
  ///
  /// In es, this message translates to:
  /// **'Sucursal'**
  String get classroomsBranch;

  /// No description provided for @classroomsLevel.
  ///
  /// In es, this message translates to:
  /// **'Nivel'**
  String get classroomsLevel;

  /// No description provided for @classroomsStudents.
  ///
  /// In es, this message translates to:
  /// **'Estudiantes'**
  String get classroomsStudents;

  /// No description provided for @classroomsFiltersTitle.
  ///
  /// In es, this message translates to:
  /// **'Filtros'**
  String get classroomsFiltersTitle;

  /// No description provided for @classroomsFilterClearAll.
  ///
  /// In es, this message translates to:
  /// **'Limpiá todo'**
  String get classroomsFilterClearAll;

  /// No description provided for @classroomsFilterApply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar filtros'**
  String get classroomsFilterApply;

  /// No description provided for @classroomsFilterClear.
  ///
  /// In es, this message translates to:
  /// **'Limpiá'**
  String get classroomsFilterClear;

  /// No description provided for @classroomsStatusActive.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get classroomsStatusActive;

  /// No description provided for @classroomsStatusArchived.
  ///
  /// In es, this message translates to:
  /// **'Archivado'**
  String get classroomsStatusArchived;

  /// No description provided for @classroomsFiltersLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los filtros'**
  String get classroomsFiltersLoadError;

  /// No description provided for @classroomsFiltersLoadErrorDetail.
  ///
  /// In es, this message translates to:
  /// **'Revisá tu conexión e intentá de nuevo.'**
  String get classroomsFiltersLoadErrorDetail;

  /// No description provided for @classroomsFilterChipBranch.
  ///
  /// In es, this message translates to:
  /// **'Sucursal: {value}'**
  String classroomsFilterChipBranch(String value);

  /// No description provided for @classroomsFilterChipLevel.
  ///
  /// In es, this message translates to:
  /// **'Nivel: {value}'**
  String classroomsFilterChipLevel(String value);

  /// No description provided for @classroomsFilterChipYear.
  ///
  /// In es, this message translates to:
  /// **'Año: {value}'**
  String classroomsFilterChipYear(String value);

  /// No description provided for @classroomsFilterChipStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado: {value}'**
  String classroomsFilterChipStatus(String value);

  /// No description provided for @classroomsPaginationShowing.
  ///
  /// In es, this message translates to:
  /// **'Mostrando {from}–{to} de {total}'**
  String classroomsPaginationShowing(int from, int to, int total);

  /// No description provided for @classroomsPaginationPrevious.
  ///
  /// In es, this message translates to:
  /// **'Página anterior'**
  String get classroomsPaginationPrevious;

  /// No description provided for @classroomsPaginationNext.
  ///
  /// In es, this message translates to:
  /// **'Página siguiente'**
  String get classroomsPaginationNext;

  /// No description provided for @classroomsPaginationPage.
  ///
  /// In es, this message translates to:
  /// **'Página {page}'**
  String classroomsPaginationPage(int page);

  /// No description provided for @classroomsTabSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get classroomsTabSummary;

  /// No description provided for @classroomsTabStudents.
  ///
  /// In es, this message translates to:
  /// **'Estudiantes'**
  String get classroomsTabStudents;

  /// No description provided for @classroomsTabProfessors.
  ///
  /// In es, this message translates to:
  /// **'Profesores'**
  String get classroomsTabProfessors;

  /// No description provided for @classroomsTabMaterials.
  ///
  /// In es, this message translates to:
  /// **'Materiales'**
  String get classroomsTabMaterials;

  /// No description provided for @classroomsSectionSchedule.
  ///
  /// In es, this message translates to:
  /// **'Horario'**
  String get classroomsSectionSchedule;

  /// No description provided for @classroomsSectionAcademic.
  ///
  /// In es, this message translates to:
  /// **'Académico'**
  String get classroomsSectionAcademic;

  /// No description provided for @classroomsSectionLocation.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get classroomsSectionLocation;

  /// No description provided for @classroomsGrade.
  ///
  /// In es, this message translates to:
  /// **'Grado'**
  String get classroomsGrade;

  /// No description provided for @classroomsBook.
  ///
  /// In es, this message translates to:
  /// **'Libro'**
  String get classroomsBook;

  /// No description provided for @classroomsCommission.
  ///
  /// In es, this message translates to:
  /// **'Comisión'**
  String get classroomsCommission;

  /// No description provided for @classroomsCourseDays.
  ///
  /// In es, this message translates to:
  /// **'Días de cursada'**
  String get classroomsCourseDays;

  /// No description provided for @classroomsNoDescription.
  ///
  /// In es, this message translates to:
  /// **'Sin descripción'**
  String get classroomsNoDescription;

  /// No description provided for @classroomsNoStudents.
  ///
  /// In es, this message translates to:
  /// **'Sin estudiantes'**
  String get classroomsNoStudents;

  /// No description provided for @classroomsNoProfessors.
  ///
  /// In es, this message translates to:
  /// **'Sin profesores'**
  String get classroomsNoProfessors;

  /// No description provided for @classroomsNoMaterials.
  ///
  /// In es, this message translates to:
  /// **'Sin materiales'**
  String get classroomsNoMaterials;

  /// No description provided for @classroomsRelatedLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los datos'**
  String get classroomsRelatedLoadError;

  /// No description provided for @classroomsMaterialDownloads.
  ///
  /// In es, this message translates to:
  /// **'{count} descargas'**
  String classroomsMaterialDownloads(int count);

  /// No description provided for @studentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Estudiantes'**
  String get studentsTitle;

  /// No description provided for @studentsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar estudiantes...'**
  String get studentsSearchHint;

  /// No description provided for @studentsFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get studentsFilterAll;

  /// No description provided for @studentsFilterActive.
  ///
  /// In es, this message translates to:
  /// **'Activos'**
  String get studentsFilterActive;

  /// No description provided for @studentsFilterInactive.
  ///
  /// In es, this message translates to:
  /// **'Inactivos'**
  String get studentsFilterInactive;

  /// No description provided for @studentsFilterYear.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get studentsFilterYear;

  /// No description provided for @studentsFilterBranch.
  ///
  /// In es, this message translates to:
  /// **'Sede'**
  String get studentsFilterBranch;

  /// No description provided for @studentsFilterOptionAll.
  ///
  /// In es, this message translates to:
  /// **'{label}: Todos'**
  String studentsFilterOptionAll(String label);

  /// No description provided for @studentsFilterOption.
  ///
  /// In es, this message translates to:
  /// **'{label}: {value}'**
  String studentsFilterOption(String label, String value);

  /// No description provided for @studentsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los estudiantes'**
  String get studentsLoadError;

  /// No description provided for @studentsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron estudiantes'**
  String get studentsEmptyTitle;

  /// No description provided for @studentsEmptySearch.
  ///
  /// In es, this message translates to:
  /// **'Probá con otro término de búsqueda'**
  String get studentsEmptySearch;

  /// No description provided for @studentsEmptyFilters.
  ///
  /// In es, this message translates to:
  /// **'Ningún estudiante coincide con los filtros seleccionados'**
  String get studentsEmptyFilters;

  /// No description provided for @studentsDetailFallbackTitle.
  ///
  /// In es, this message translates to:
  /// **'Estudiante'**
  String get studentsDetailFallbackTitle;

  /// No description provided for @studentsDetailLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el estudiante'**
  String get studentsDetailLoadError;

  /// No description provided for @studentsTabGrades.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get studentsTabGrades;

  /// No description provided for @studentsTabAbsences.
  ///
  /// In es, this message translates to:
  /// **'Inasistencias'**
  String get studentsTabAbsences;

  /// No description provided for @studentsTabFees.
  ///
  /// In es, this message translates to:
  /// **'Cuotas'**
  String get studentsTabFees;

  /// No description provided for @studentsTabInfo.
  ///
  /// In es, this message translates to:
  /// **'Información'**
  String get studentsTabInfo;

  /// No description provided for @studentsNoGrades.
  ///
  /// In es, this message translates to:
  /// **'No hay notas disponibles'**
  String get studentsNoGrades;

  /// No description provided for @studentsNoAbsences.
  ///
  /// In es, this message translates to:
  /// **'No hay inasistencias registradas'**
  String get studentsNoAbsences;

  /// No description provided for @studentsNoFees.
  ///
  /// In es, this message translates to:
  /// **'No hay cuotas disponibles'**
  String get studentsNoFees;

  /// No description provided for @studentsNoClassroom.
  ///
  /// In es, this message translates to:
  /// **'Sin clases'**
  String get studentsNoClassroom;

  /// No description provided for @studentsInfoFullName.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get studentsInfoFullName;

  /// No description provided for @studentsInfoEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get studentsInfoEmail;

  /// No description provided for @studentsInfoYear.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get studentsInfoYear;

  /// No description provided for @studentsInfoIdentityNumber.
  ///
  /// In es, this message translates to:
  /// **'Número de documento'**
  String get studentsInfoIdentityNumber;

  /// No description provided for @studentsInfoBranch.
  ///
  /// In es, this message translates to:
  /// **'Sede'**
  String get studentsInfoBranch;

  /// No description provided for @studentsInfoClassrooms.
  ///
  /// In es, this message translates to:
  /// **'Clases'**
  String get studentsInfoClassrooms;

  /// No description provided for @feesTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuotas'**
  String get feesTitle;

  /// No description provided for @feesSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar cuotas...'**
  String get feesSearchHint;

  /// No description provided for @feesLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las cuotas'**
  String get feesLoadError;

  /// No description provided for @feesEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron cuotas'**
  String get feesEmptyTitle;

  /// No description provided for @feesEmptySearchSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Probá con otro término de búsqueda'**
  String get feesEmptySearchSubtitle;

  /// No description provided for @feesEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'No hay cuotas disponibles'**
  String get feesEmptySubtitle;

  /// No description provided for @feesDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuota #{number}'**
  String feesDetailTitle(int number);

  /// No description provided for @feesDetailFallbackTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuota'**
  String get feesDetailFallbackTitle;

  /// No description provided for @feesDetailLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la cuota'**
  String get feesDetailLoadError;

  /// No description provided for @feesDetailFeeNumber.
  ///
  /// In es, this message translates to:
  /// **'Número de cuota'**
  String get feesDetailFeeNumber;

  /// No description provided for @feesDetailMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get feesDetailMonth;

  /// No description provided for @feesDetailYear.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get feesDetailYear;

  /// No description provided for @feesDetailToPay.
  ///
  /// In es, this message translates to:
  /// **'A pagar'**
  String get feesDetailToPay;

  /// No description provided for @feesDetailPaid.
  ///
  /// In es, this message translates to:
  /// **'Pagado'**
  String get feesDetailPaid;

  /// No description provided for @feesDetailTotal.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get feesDetailTotal;

  /// No description provided for @feesDetailStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get feesDetailStatus;

  /// No description provided for @feesDetailPaymentMethod.
  ///
  /// In es, this message translates to:
  /// **'Método de pago'**
  String get feesDetailPaymentMethod;

  /// No description provided for @feesDetailPaymentDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de pago'**
  String get feesDetailPaymentDate;

  /// No description provided for @feesUnknownStudent.
  ///
  /// In es, this message translates to:
  /// **'Desconocido'**
  String get feesUnknownStudent;

  /// No description provided for @feesCardSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cuota #{number} · {month} {year}'**
  String feesCardSubtitle(int number, String month, String year);

  /// No description provided for @qualificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Calificaciones'**
  String get qualificationsTitle;

  /// No description provided for @qualificationsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar calificaciones...'**
  String get qualificationsSearchHint;

  /// No description provided for @qualificationsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las calificaciones'**
  String get qualificationsLoadError;

  /// No description provided for @qualificationsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron calificaciones'**
  String get qualificationsEmptyTitle;

  /// No description provided for @qualificationsEmptySearchSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Probá con otro término de búsqueda'**
  String get qualificationsEmptySearchSubtitle;

  /// No description provided for @qualificationsEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'No hay calificaciones disponibles'**
  String get qualificationsEmptySubtitle;

  /// No description provided for @qualificationsUnknownStudent.
  ///
  /// In es, this message translates to:
  /// **'Estudiante desconocido'**
  String get qualificationsUnknownStudent;

  /// No description provided for @qualificationsUnknownClassroom.
  ///
  /// In es, this message translates to:
  /// **'Clase desconocida'**
  String get qualificationsUnknownClassroom;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In es, this message translates to:
  /// **'Marcar todas como leídas'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las notificaciones'**
  String get notificationsLoadError;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'No hay notificaciones'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'¡Estás al día!'**
  String get notificationsEmptySubtitle;

  /// No description provided for @notificationsToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get notificationsToday;

  /// No description provided for @notificationsYesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get notificationsYesterday;

  /// No description provided for @notificationsEarlier.
  ///
  /// In es, this message translates to:
  /// **'Anteriores'**
  String get notificationsEarlier;

  /// No description provided for @chatLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los chats'**
  String get chatLoadError;

  /// No description provided for @chatEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'No hay conversaciones'**
  String get chatEmptyTitle;

  /// No description provided for @chatEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Iniciá una conversación con tus compañeros'**
  String get chatEmptySubtitle;

  /// No description provided for @chatMessagesLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los mensajes'**
  String get chatMessagesLoadError;

  /// No description provided for @chatMessagesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay mensajes\n¡Iniciá la conversación!'**
  String get chatMessagesEmpty;

  /// No description provided for @chatInputHint.
  ///
  /// In es, this message translates to:
  /// **'Escribí un mensaje...'**
  String get chatInputHint;

  /// No description provided for @chatTimeNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora'**
  String get chatTimeNow;

  /// No description provided for @chatTimeMinutesShort.
  ///
  /// In es, this message translates to:
  /// **'{count}m'**
  String chatTimeMinutesShort(int count);

  /// No description provided for @newsTitle.
  ///
  /// In es, this message translates to:
  /// **'Noticias'**
  String get newsTitle;

  /// No description provided for @newsErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las noticias'**
  String get newsErrorTitle;

  /// No description provided for @newsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'No hay noticias'**
  String get newsEmptyTitle;

  /// No description provided for @newsEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Volvé más tarde para ver novedades'**
  String get newsEmptySubtitle;

  /// No description provided for @eventsTitle.
  ///
  /// In es, this message translates to:
  /// **'Eventos'**
  String get eventsTitle;

  /// No description provided for @eventsErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los eventos'**
  String get eventsErrorTitle;

  /// No description provided for @eventsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'No hay eventos'**
  String get eventsEmptyTitle;

  /// No description provided for @eventsEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'No hay próximos eventos programados'**
  String get eventsEmptySubtitle;

  /// No description provided for @searchTitle.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar estudiantes, clases, noticias...'**
  String get searchHint;

  /// No description provided for @searchErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'Error en la búsqueda'**
  String get searchErrorTitle;

  /// No description provided for @searchEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Buscá estudiantes, clases o noticias'**
  String get searchEmptySubtitle;

  /// No description provided for @searchNoResultsTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get searchNoResultsTitle;

  /// No description provided for @searchNoResultsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron resultados para \"{query}\"'**
  String searchNoResultsSubtitle(String query);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
