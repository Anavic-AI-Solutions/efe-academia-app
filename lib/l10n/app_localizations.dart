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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
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
  /// **'Aulas'**
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

  /// No description provided for @navMenu.
  ///
  /// In es, this message translates to:
  /// **'Menú'**
  String get navMenu;

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

  /// No description provided for @profileEditProfileTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get profileEditProfileTitle;

  /// No description provided for @profileEditPhotoSection.
  ///
  /// In es, this message translates to:
  /// **'Foto de perfil'**
  String get profileEditPhotoSection;

  /// No description provided for @profileEditChangePhoto.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto'**
  String get profileEditChangePhoto;

  /// No description provided for @profileEditPhotoHint.
  ///
  /// In es, this message translates to:
  /// **'JPG, PNG o GIF · máx. 2 MB'**
  String get profileEditPhotoHint;

  /// No description provided for @profileEditPhotoInvalid.
  ///
  /// In es, this message translates to:
  /// **'Elegí una imagen JPG, PNG o GIF de hasta 2 MB.'**
  String get profileEditPhotoInvalid;

  /// No description provided for @profileEditPhotoUploaded.
  ///
  /// In es, this message translates to:
  /// **'Foto actualizada.'**
  String get profileEditPhotoUploaded;

  /// No description provided for @profileEditPhotoError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo subir la foto.'**
  String get profileEditPhotoError;

  /// No description provided for @profileEditDataSection.
  ///
  /// In es, this message translates to:
  /// **'Datos personales'**
  String get profileEditDataSection;

  /// No description provided for @profileEditNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get profileEditNameLabel;

  /// No description provided for @profileEditEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get profileEditEmailLabel;

  /// No description provided for @profileEditSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get profileEditSave;

  /// No description provided for @profileEditSaved.
  ///
  /// In es, this message translates to:
  /// **'Perfil actualizado.'**
  String get profileEditSaved;

  /// No description provided for @profileEditSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo actualizar el perfil.'**
  String get profileEditSaveError;

  /// No description provided for @profileEditEmailInUse.
  ///
  /// In es, this message translates to:
  /// **'Ese email ya está en uso.'**
  String get profileEditEmailInUse;

  /// No description provided for @profileEditPasswordSection.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get profileEditPasswordSection;

  /// No description provided for @profileEditCurrentPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actual'**
  String get profileEditCurrentPassword;

  /// No description provided for @profileEditNewPassword.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get profileEditNewPassword;

  /// No description provided for @profileEditConfirmPassword.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get profileEditConfirmPassword;

  /// No description provided for @profileEditPasswordSave.
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get profileEditPasswordSave;

  /// No description provided for @profileEditPasswordSaved.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada.'**
  String get profileEditPasswordSaved;

  /// No description provided for @profileEditPasswordError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cambiar la contraseña.'**
  String get profileEditPasswordError;

  /// No description provided for @profileEditCurrentPasswordIncorrect.
  ///
  /// In es, this message translates to:
  /// **'La contraseña actual no es correcta.'**
  String get profileEditCurrentPasswordIncorrect;

  /// No description provided for @profileEditPasswordInvalid.
  ///
  /// In es, this message translates to:
  /// **'La contraseña no es válida.'**
  String get profileEditPasswordInvalid;

  /// No description provided for @profileEditShowPassword.
  ///
  /// In es, this message translates to:
  /// **'Mostrar contraseña'**
  String get profileEditShowPassword;

  /// No description provided for @profileEditHidePassword.
  ///
  /// In es, this message translates to:
  /// **'Ocultar contraseña'**
  String get profileEditHidePassword;

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

  /// No description provided for @paginationShowing.
  ///
  /// In es, this message translates to:
  /// **'Mostrando {from}–{to} de {total}'**
  String paginationShowing(int from, int to, int total);

  /// No description provided for @paginationPrevious.
  ///
  /// In es, this message translates to:
  /// **'Página anterior'**
  String get paginationPrevious;

  /// No description provided for @paginationNext.
  ///
  /// In es, this message translates to:
  /// **'Página siguiente'**
  String get paginationNext;

  /// No description provided for @paginationPage.
  ///
  /// In es, this message translates to:
  /// **'Página {page}'**
  String paginationPage(int page);

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

  /// No description provided for @studentsTabRequest.
  ///
  /// In es, this message translates to:
  /// **'Solicitud'**
  String get studentsTabRequest;

  /// No description provided for @studentsTabParents.
  ///
  /// In es, this message translates to:
  /// **'Padres'**
  String get studentsTabParents;

  /// No description provided for @studentsRequestLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la solicitud'**
  String get studentsRequestLoadError;

  /// No description provided for @studentsParentsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los padres/tutores'**
  String get studentsParentsLoadError;

  /// No description provided for @studentsParentsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin padres/tutores vinculados'**
  String get studentsParentsEmpty;

  /// No description provided for @studentsRequestCreatedAt.
  ///
  /// In es, this message translates to:
  /// **'Fecha de solicitud'**
  String get studentsRequestCreatedAt;

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

  /// No description provided for @studentsSectionPersonal.
  ///
  /// In es, this message translates to:
  /// **'Datos personales'**
  String get studentsSectionPersonal;

  /// No description provided for @studentsSectionInstitutional.
  ///
  /// In es, this message translates to:
  /// **'Institucional'**
  String get studentsSectionInstitutional;

  /// No description provided for @studentsRelatedLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los datos'**
  String get studentsRelatedLoadError;

  /// No description provided for @studentsGradeTitle.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get studentsGradeTitle;

  /// No description provided for @studentsGradePeriod.
  ///
  /// In es, this message translates to:
  /// **'Período {period}'**
  String studentsGradePeriod(String period);

  /// No description provided for @gradesGridTitle.
  ///
  /// In es, this message translates to:
  /// **'Calificaciones por período'**
  String get gradesGridTitle;

  /// No description provided for @gradesGridPeriod.
  ///
  /// In es, this message translates to:
  /// **'Período'**
  String get gradesGridPeriod;

  /// No description provided for @gradesGridPerformance.
  ///
  /// In es, this message translates to:
  /// **'Desempeño'**
  String get gradesGridPerformance;

  /// No description provided for @gradesGridAttitude.
  ///
  /// In es, this message translates to:
  /// **'Actitud'**
  String get gradesGridAttitude;

  /// No description provided for @gradesGridWritten.
  ///
  /// In es, this message translates to:
  /// **'Escrito'**
  String get gradesGridWritten;

  /// No description provided for @gradesGridOral.
  ///
  /// In es, this message translates to:
  /// **'Oral'**
  String get gradesGridOral;

  /// No description provided for @gradesGridHomework.
  ///
  /// In es, this message translates to:
  /// **'Tareas'**
  String get gradesGridHomework;

  /// No description provided for @gradesGridDiscipline.
  ///
  /// In es, this message translates to:
  /// **'Disciplina'**
  String get gradesGridDiscipline;

  /// No description provided for @gradesGridParticipation.
  ///
  /// In es, this message translates to:
  /// **'Participación'**
  String get gradesGridParticipation;

  /// No description provided for @gradesGridAttendance.
  ///
  /// In es, this message translates to:
  /// **'Asistencia'**
  String get gradesGridAttendance;

  /// No description provided for @gradesGridExam.
  ///
  /// In es, this message translates to:
  /// **'Parcial'**
  String get gradesGridExam;

  /// No description provided for @gradesGridAverage.
  ///
  /// In es, this message translates to:
  /// **'Promedio'**
  String get gradesGridAverage;

  /// No description provided for @gradesGridTerm.
  ///
  /// In es, this message translates to:
  /// **'{term}° Trimestre'**
  String gradesGridTerm(int term);

  /// No description provided for @gradesGridClassroomFallback.
  ///
  /// In es, this message translates to:
  /// **'Aula'**
  String get gradesGridClassroomFallback;

  /// No description provided for @studentsAbsenceTitle.
  ///
  /// In es, this message translates to:
  /// **'Inasistencia'**
  String get studentsAbsenceTitle;

  /// No description provided for @studentsStatusApproved.
  ///
  /// In es, this message translates to:
  /// **'Aprobado'**
  String get studentsStatusApproved;

  /// No description provided for @studentsStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get studentsStatusPending;

  /// No description provided for @studentsStatusRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazado'**
  String get studentsStatusRejected;

  /// No description provided for @feesStatusPaid.
  ///
  /// In es, this message translates to:
  /// **'Pagado'**
  String get feesStatusPaid;

  /// No description provided for @feesStatusPartial.
  ///
  /// In es, this message translates to:
  /// **'Parcial'**
  String get feesStatusPartial;

  /// No description provided for @feesStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get feesStatusPending;

  /// No description provided for @feesStatusOverdue.
  ///
  /// In es, this message translates to:
  /// **'Vencido'**
  String get feesStatusOverdue;

  /// No description provided for @studentsAbsenceJustified.
  ///
  /// In es, this message translates to:
  /// **'Justificada'**
  String get studentsAbsenceJustified;

  /// No description provided for @studentsAbsenceUnjustified.
  ///
  /// In es, this message translates to:
  /// **'Sin justificar'**
  String get studentsAbsenceUnjustified;

  /// No description provided for @studentsAbsencePending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get studentsAbsencePending;

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

  /// No description provided for @chatNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo chat'**
  String get chatNewTitle;

  /// No description provided for @chatNewSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar persona…'**
  String get chatNewSearchHint;

  /// No description provided for @chatNewEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin personas vinculadas'**
  String get chatNewEmptyTitle;

  /// No description provided for @chatNewEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tenés personas con las que chatear'**
  String get chatNewEmptySubtitle;

  /// No description provided for @chatNewNoResults.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados para «{query}»'**
  String chatNewNoResults(String query);

  /// No description provided for @chatNewStart.
  ///
  /// In es, this message translates to:
  /// **'Iniciar conversación'**
  String get chatNewStart;

  /// No description provided for @relationRoleStudent.
  ///
  /// In es, this message translates to:
  /// **'Alumno'**
  String get relationRoleStudent;

  /// No description provided for @relationRoleProfessor.
  ///
  /// In es, this message translates to:
  /// **'Profesor'**
  String get relationRoleProfessor;

  /// No description provided for @relationRoleParent.
  ///
  /// In es, this message translates to:
  /// **'Padre/Madre'**
  String get relationRoleParent;

  /// No description provided for @relationRoleAdmin.
  ///
  /// In es, this message translates to:
  /// **'Admin'**
  String get relationRoleAdmin;

  /// No description provided for @chatTyping.
  ///
  /// In es, this message translates to:
  /// **'escribiendo…'**
  String get chatTyping;

  /// No description provided for @chatOnline.
  ///
  /// In es, this message translates to:
  /// **'en línea'**
  String get chatOnline;

  /// No description provided for @chatConnectionLost.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión — tocá para reintentar'**
  String get chatConnectionLost;

  /// No description provided for @chatSendFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar'**
  String get chatSendFailed;

  /// No description provided for @chatRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get chatRetry;

  /// No description provided for @chatUnreadLabel.
  ///
  /// In es, this message translates to:
  /// **'{count} mensajes sin leer'**
  String chatUnreadLabel(int count);

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

  /// No description provided for @professorGreetingMorning.
  ///
  /// In es, this message translates to:
  /// **'Buen día'**
  String get professorGreetingMorning;

  /// No description provided for @professorGreetingAfternoon.
  ///
  /// In es, this message translates to:
  /// **'Buenas tardes'**
  String get professorGreetingAfternoon;

  /// No description provided for @professorGreetingEvening.
  ///
  /// In es, this message translates to:
  /// **'Buenas noches'**
  String get professorGreetingEvening;

  /// No description provided for @professorHomeTitle.
  ///
  /// In es, this message translates to:
  /// **'Prof. {name}'**
  String professorHomeTitle(String name);

  /// No description provided for @professorStatClassrooms.
  ///
  /// In es, this message translates to:
  /// **'Aulas'**
  String get professorStatClassrooms;

  /// No description provided for @professorStatStudents.
  ///
  /// In es, this message translates to:
  /// **'Alumnos'**
  String get professorStatStudents;

  /// No description provided for @professorStatAbsences.
  ///
  /// In es, this message translates to:
  /// **'Ausentes'**
  String get professorStatAbsences;

  /// No description provided for @professorMyClassrooms.
  ///
  /// In es, this message translates to:
  /// **'Mis aulas'**
  String get professorMyClassrooms;

  /// No description provided for @professorMyClassroomsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tenés aulas asignadas'**
  String get professorMyClassroomsEmpty;

  /// No description provided for @professorClassroomsCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin aulas asignadas} =1{1 aula} other{{count} aulas}}'**
  String professorClassroomsCount(int count);

  /// No description provided for @professorStudentsCount.
  ///
  /// In es, this message translates to:
  /// **'{count} alumnos'**
  String professorStudentsCount(int count);

  /// No description provided for @professorTakeAttendance.
  ///
  /// In es, this message translates to:
  /// **'Tomar asistencia'**
  String get professorTakeAttendance;

  /// No description provided for @professorLoadGrade.
  ///
  /// In es, this message translates to:
  /// **'Cargar nota'**
  String get professorLoadGrade;

  /// No description provided for @professorLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el inicio'**
  String get professorLoadError;

  /// No description provided for @homeCalendar.
  ///
  /// In es, this message translates to:
  /// **'Calendario'**
  String get homeCalendar;

  /// No description provided for @homeSeeAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todo'**
  String get homeSeeAll;

  /// No description provided for @homeCalendarEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay próximos eventos'**
  String get homeCalendarEmpty;

  /// No description provided for @homeBirthdays.
  ///
  /// In es, this message translates to:
  /// **'Cumpleaños'**
  String get homeBirthdays;

  /// No description provided for @homeBirthdaysEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay cumpleaños hoy'**
  String get homeBirthdaysEmpty;

  /// No description provided for @homeBirthdaysSoon.
  ///
  /// In es, this message translates to:
  /// **'Disponible próximamente'**
  String get homeBirthdaysSoon;

  /// No description provided for @attendanceTitle.
  ///
  /// In es, this message translates to:
  /// **'Asistencia · {classroom}'**
  String attendanceTitle(String classroom);

  /// No description provided for @attendanceSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{date} · {count} alumnos'**
  String attendanceSubtitle(String date, int count);

  /// No description provided for @attendancePresent.
  ///
  /// In es, this message translates to:
  /// **'P'**
  String get attendancePresent;

  /// No description provided for @attendanceAbsent.
  ///
  /// In es, this message translates to:
  /// **'A'**
  String get attendanceAbsent;

  /// No description provided for @attendanceToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get attendanceToday;

  /// No description provided for @attendanceSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar asistencia'**
  String get attendanceSave;

  /// No description provided for @attendanceSaved.
  ///
  /// In es, this message translates to:
  /// **'Asistencia guardada'**
  String get attendanceSaved;

  /// No description provided for @attendanceLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la asistencia'**
  String get attendanceLoadError;

  /// No description provided for @attendanceSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar la asistencia'**
  String get attendanceSaveError;

  /// No description provided for @attendanceEmpty.
  ///
  /// In es, this message translates to:
  /// **'Este aula no tiene alumnos'**
  String get attendanceEmpty;

  /// No description provided for @attendanceUnsavedTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambios sin guardar'**
  String get attendanceUnsavedTitle;

  /// No description provided for @attendanceUnsavedMessage.
  ///
  /// In es, this message translates to:
  /// **'Si salís ahora, se perderán los cambios de asistencia.'**
  String get attendanceUnsavedMessage;

  /// No description provided for @attendanceUnsavedStay.
  ///
  /// In es, this message translates to:
  /// **'Seguir acá'**
  String get attendanceUnsavedStay;

  /// No description provided for @attendanceUnsavedLeave.
  ///
  /// In es, this message translates to:
  /// **'Salir sin guardar'**
  String get attendanceUnsavedLeave;

  /// No description provided for @gradesTitle.
  ///
  /// In es, this message translates to:
  /// **'Calificaciones'**
  String get gradesTitle;

  /// No description provided for @gradesClassroomAverage.
  ///
  /// In es, this message translates to:
  /// **'Promedio del aula'**
  String get gradesClassroomAverage;

  /// No description provided for @gradesLoadGrade.
  ///
  /// In es, this message translates to:
  /// **'+ Cargar calificación'**
  String get gradesLoadGrade;

  /// No description provided for @gradesLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las calificaciones'**
  String get gradesLoadError;

  /// No description provided for @gradeFormTitle.
  ///
  /// In es, this message translates to:
  /// **'Cargar calificación'**
  String get gradeFormTitle;

  /// No description provided for @gradeFormStudent.
  ///
  /// In es, this message translates to:
  /// **'Alumno'**
  String get gradeFormStudent;

  /// No description provided for @gradeFormType.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get gradeFormType;

  /// No description provided for @gradeFormPeriod.
  ///
  /// In es, this message translates to:
  /// **'Período'**
  String get gradeFormPeriod;

  /// No description provided for @gradeFormScore.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get gradeFormScore;

  /// No description provided for @gradeFormScoreHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: 8.5'**
  String get gradeFormScoreHint;

  /// No description provided for @gradeFormDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get gradeFormDescription;

  /// No description provided for @gradeFormSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get gradeFormSave;

  /// No description provided for @gradeFormScoreInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresá una nota entre 0 y 10'**
  String get gradeFormScoreInvalid;

  /// No description provided for @gradeFormSaved.
  ///
  /// In es, this message translates to:
  /// **'Calificación guardada'**
  String get gradeFormSaved;

  /// No description provided for @gradeFormError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar la calificación'**
  String get gradeFormError;

  /// No description provided for @studentGradeFromDetail.
  ///
  /// In es, this message translates to:
  /// **'Cargar nota'**
  String get studentGradeFromDetail;

  /// No description provided for @studentGradeClassroom.
  ///
  /// In es, this message translates to:
  /// **'Aula'**
  String get studentGradeClassroom;

  /// No description provided for @studentGradeNoClassrooms.
  ///
  /// In es, this message translates to:
  /// **'Sin aulas asignadas'**
  String get studentGradeNoClassrooms;

  /// No description provided for @absenceMarkTitle.
  ///
  /// In es, this message translates to:
  /// **'Marcar inasistencia'**
  String get absenceMarkTitle;

  /// No description provided for @absenceMarkClassroom.
  ///
  /// In es, this message translates to:
  /// **'Aula'**
  String get absenceMarkClassroom;

  /// No description provided for @absenceMarkDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get absenceMarkDate;

  /// No description provided for @absenceMarkInfo.
  ///
  /// In es, this message translates to:
  /// **'Se agrega al parte del día sin quitar a los demás ausentes.'**
  String get absenceMarkInfo;

  /// No description provided for @absenceMarked.
  ///
  /// In es, this message translates to:
  /// **'Inasistencia registrada'**
  String get absenceMarked;

  /// No description provided for @absenceAlreadyMarked.
  ///
  /// In es, this message translates to:
  /// **'Ya estaba ausente ese día'**
  String get absenceAlreadyMarked;

  /// No description provided for @absenceMarkError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo registrar la inasistencia'**
  String get absenceMarkError;

  /// No description provided for @materialFormTitleNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo material'**
  String get materialFormTitleNew;

  /// No description provided for @materialFormTitleEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar material'**
  String get materialFormTitleEdit;

  /// No description provided for @materialFormName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get materialFormName;

  /// No description provided for @materialFormCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get materialFormCategory;

  /// No description provided for @materialFormCategoryNone.
  ///
  /// In es, this message translates to:
  /// **'Sin categoría'**
  String get materialFormCategoryNone;

  /// No description provided for @materialFormDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get materialFormDescription;

  /// No description provided for @materialFormFiles.
  ///
  /// In es, this message translates to:
  /// **'Archivos'**
  String get materialFormFiles;

  /// No description provided for @materialFormPickFiles.
  ///
  /// In es, this message translates to:
  /// **'Elegir archivos'**
  String get materialFormPickFiles;

  /// No description provided for @materialFormVisibility.
  ///
  /// In es, this message translates to:
  /// **'Visibilidad'**
  String get materialFormVisibility;

  /// No description provided for @materialFormVisibilityAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get materialFormVisibilityAll;

  /// No description provided for @materialFormVisibilitySpecific.
  ///
  /// In es, this message translates to:
  /// **'Alumnos específicos'**
  String get materialFormVisibilitySpecific;

  /// No description provided for @materialFormAvailableUntil.
  ///
  /// In es, this message translates to:
  /// **'Disponible hasta (opcional)'**
  String get materialFormAvailableUntil;

  /// No description provided for @materialFormClearDate.
  ///
  /// In es, this message translates to:
  /// **'Quitar fecha'**
  String get materialFormClearDate;

  /// No description provided for @materialFormSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get materialFormSave;

  /// No description provided for @materialFormNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresá un nombre'**
  String get materialFormNameRequired;

  /// No description provided for @materialFormFilesRequired.
  ///
  /// In es, this message translates to:
  /// **'Elegí al menos un archivo'**
  String get materialFormFilesRequired;

  /// No description provided for @materialFormFilesTooMany.
  ///
  /// In es, this message translates to:
  /// **'Máximo 10 archivos'**
  String get materialFormFilesTooMany;

  /// No description provided for @materialFormFileTooLarge.
  ///
  /// In es, this message translates to:
  /// **'Cada archivo puede pesar hasta 50 MB'**
  String get materialFormFileTooLarge;

  /// No description provided for @materialFormStudentsRequired.
  ///
  /// In es, this message translates to:
  /// **'Elegí al menos un alumno'**
  String get materialFormStudentsRequired;

  /// No description provided for @materialFormError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el material'**
  String get materialFormError;

  /// No description provided for @materialFormDetailError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el material'**
  String get materialFormDetailError;

  /// No description provided for @materialsAdd.
  ///
  /// In es, this message translates to:
  /// **'Cargar material'**
  String get materialsAdd;

  /// No description provided for @materialsCreated.
  ///
  /// In es, this message translates to:
  /// **'Material publicado'**
  String get materialsCreated;

  /// No description provided for @materialsUpdated.
  ///
  /// In es, this message translates to:
  /// **'Material actualizado'**
  String get materialsUpdated;

  /// No description provided for @materialsDeleted.
  ///
  /// In es, this message translates to:
  /// **'Material eliminado'**
  String get materialsDeleted;

  /// No description provided for @materialsDeleteError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo eliminar el material'**
  String get materialsDeleteError;

  /// No description provided for @materialsEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get materialsEdit;

  /// No description provided for @materialsDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get materialsDelete;

  /// No description provided for @materialsDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar material?'**
  String get materialsDeleteTitle;

  /// No description provided for @materialsDeleteMessage.
  ///
  /// In es, this message translates to:
  /// **'También se borran sus archivos.'**
  String get materialsDeleteMessage;

  /// No description provided for @materialsDeleteCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get materialsDeleteCancel;

  /// No description provided for @materialsDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get materialsDeleteConfirm;

  /// No description provided for @materialsStudentCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 alumno} other{{count} alumnos}}'**
  String materialsStudentCount(int count);

  /// No description provided for @documentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Documentos'**
  String get documentsTitle;

  /// No description provided for @documentsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay documentos'**
  String get documentsEmpty;

  /// No description provided for @documentsOpen.
  ///
  /// In es, this message translates to:
  /// **'Abrir / Descargar'**
  String get documentsOpen;

  /// No description provided for @documentsOpenError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el documento'**
  String get documentsOpenError;

  /// No description provided for @homeDocuments.
  ///
  /// In es, this message translates to:
  /// **'Documentos'**
  String get homeDocuments;

  /// No description provided for @homeNews.
  ///
  /// In es, this message translates to:
  /// **'Novedades'**
  String get homeNews;

  /// No description provided for @homeNewsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay novedades'**
  String get homeNewsEmpty;

  /// No description provided for @homeSummaryDocumentsCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 documento} other{{count} documentos}}'**
  String homeSummaryDocumentsCount(int count);

  /// No description provided for @homeSummaryBirthdaysCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 hoy} other{{count} hoy}}'**
  String homeSummaryBirthdaysCount(int count);

  /// No description provided for @calendarViewList.
  ///
  /// In es, this message translates to:
  /// **'Ver lista'**
  String get calendarViewList;

  /// No description provided for @parentGreeting.
  ///
  /// In es, this message translates to:
  /// **'Hola'**
  String get parentGreeting;

  /// No description provided for @parentFamilyTitle.
  ///
  /// In es, this message translates to:
  /// **'Familia {surname}'**
  String parentFamilyTitle(String surname);

  /// No description provided for @parentOverdueFeesCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 cuota vencida} other{{count} cuotas vencidas}}'**
  String parentOverdueFeesCount(int count);

  /// No description provided for @parentMoraTotal.
  ///
  /// In es, this message translates to:
  /// **'Mora total'**
  String get parentMoraTotal;

  /// No description provided for @parentPayAction.
  ///
  /// In es, this message translates to:
  /// **'Pagar'**
  String get parentPayAction;

  /// No description provided for @navPayments.
  ///
  /// In es, this message translates to:
  /// **'Pagos'**
  String get navPayments;

  /// No description provided for @parentActionBoletin.
  ///
  /// In es, this message translates to:
  /// **'Boletín'**
  String get parentActionBoletin;

  /// No description provided for @boletinTitle.
  ///
  /// In es, this message translates to:
  /// **'Boletín'**
  String get boletinTitle;

  /// No description provided for @boletinDownloadAction.
  ///
  /// In es, this message translates to:
  /// **'Descargar boletín (PDF)'**
  String get boletinDownloadAction;

  /// No description provided for @boletinPeriod.
  ///
  /// In es, this message translates to:
  /// **'{n}° Período'**
  String boletinPeriod(int n);

  /// No description provided for @boletinObservations.
  ///
  /// In es, this message translates to:
  /// **'Observaciones'**
  String get boletinObservations;

  /// No description provided for @boletinNoGrades.
  ///
  /// In es, this message translates to:
  /// **'No hay calificaciones registradas para este período'**
  String get boletinNoGrades;

  /// No description provided for @boletinNoAccess.
  ///
  /// In es, this message translates to:
  /// **'No tenés acceso al boletín de este alumno'**
  String get boletinNoAccess;

  /// No description provided for @boletinDownloadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo descargar el boletín'**
  String get boletinDownloadError;

  /// No description provided for @boletinViewAction.
  ///
  /// In es, this message translates to:
  /// **'Ver boletín'**
  String get boletinViewAction;

  /// No description provided for @parentChooseChild.
  ///
  /// In es, this message translates to:
  /// **'Elegí un hijo'**
  String get parentChooseChild;

  /// No description provided for @feesUploadProofAction.
  ///
  /// In es, this message translates to:
  /// **'Subir comprobante'**
  String get feesUploadProofAction;

  /// No description provided for @feesReplaceProofAction.
  ///
  /// In es, this message translates to:
  /// **'Reemplazar comprobante'**
  String get feesReplaceProofAction;

  /// No description provided for @feesInvoiceAction.
  ///
  /// In es, this message translates to:
  /// **'Ver factura'**
  String get feesInvoiceAction;

  /// No description provided for @feesInvoiceUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Factura no disponible'**
  String get feesInvoiceUnavailable;

  /// No description provided for @feesInvoiceViewerTitle.
  ///
  /// In es, this message translates to:
  /// **'Factura'**
  String get feesInvoiceViewerTitle;

  /// No description provided for @feesInvoiceLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la factura'**
  String get feesInvoiceLoadError;

  /// No description provided for @feesInvoiceDownloadAction.
  ///
  /// In es, this message translates to:
  /// **'Descargar'**
  String get feesInvoiceDownloadAction;

  /// No description provided for @feesInvoiceDownloadSuccess.
  ///
  /// In es, this message translates to:
  /// **'Factura descargada'**
  String get feesInvoiceDownloadSuccess;

  /// No description provided for @feesInvoiceDownloadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo descargar la factura'**
  String get feesInvoiceDownloadError;

  /// No description provided for @feesChooseFeeTitle.
  ///
  /// In es, this message translates to:
  /// **'Elegí la cuota'**
  String get feesChooseFeeTitle;

  /// No description provided for @feesProofStatusReview.
  ///
  /// In es, this message translates to:
  /// **'Comprobante en revisión'**
  String get feesProofStatusReview;

  /// No description provided for @feesProofPickFile.
  ///
  /// In es, this message translates to:
  /// **'Elegir archivo'**
  String get feesProofPickFile;

  /// No description provided for @feesProofHint.
  ///
  /// In es, this message translates to:
  /// **'JPG, PNG o PDF · hasta 10 MB'**
  String get feesProofHint;

  /// No description provided for @feesProofInvalidFile.
  ///
  /// In es, this message translates to:
  /// **'Archivo no válido. JPG, PNG o PDF · hasta 10 MB'**
  String get feesProofInvalidFile;

  /// No description provided for @feesProofSuccess.
  ///
  /// In es, this message translates to:
  /// **'Comprobante subido. Un administrador lo revisará.'**
  String get feesProofSuccess;

  /// No description provided for @feesProofError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo subir el comprobante'**
  String get feesProofError;

  /// No description provided for @feesProofSubmit.
  ///
  /// In es, this message translates to:
  /// **'Subir'**
  String get feesProofSubmit;

  /// No description provided for @feesStatusUnderReview.
  ///
  /// In es, this message translates to:
  /// **'En revisión'**
  String get feesStatusUnderReview;

  /// No description provided for @feesPartialOwed.
  ///
  /// In es, this message translates to:
  /// **'debe {amount}'**
  String feesPartialOwed(String amount);

  /// No description provided for @pushPrimerTitle.
  ///
  /// In es, this message translates to:
  /// **'Activá las notificaciones'**
  String get pushPrimerTitle;

  /// No description provided for @pushPrimerBody.
  ///
  /// In es, this message translates to:
  /// **'Los mensajes de chat y los avisos de la escuela te llegan aunque la app esté cerrada'**
  String get pushPrimerBody;

  /// No description provided for @pushPrimerActivate.
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get pushPrimerActivate;

  /// No description provided for @pushPrimerLater.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get pushPrimerLater;

  /// No description provided for @trayOpen.
  ///
  /// In es, this message translates to:
  /// **'Abrir EFE'**
  String get trayOpen;

  /// No description provided for @trayAutostart.
  ///
  /// In es, this message translates to:
  /// **'Iniciar con el sistema'**
  String get trayAutostart;

  /// No description provided for @trayQuit.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get trayQuit;

  /// No description provided for @libraryTitle.
  ///
  /// In es, this message translates to:
  /// **'Biblioteca'**
  String get libraryTitle;

  /// No description provided for @librarySearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar materiales...'**
  String get librarySearchHint;

  /// No description provided for @faqsTitle.
  ///
  /// In es, this message translates to:
  /// **'Preguntas frecuentes'**
  String get faqsTitle;

  /// No description provided for @faqsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar preguntas...'**
  String get faqsSearchHint;

  /// No description provided for @statisticsTitle.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get statisticsTitle;

  /// No description provided for @kpiSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen de KPIs'**
  String get kpiSummary;

  /// No description provided for @statisticsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las estadísticas'**
  String get statisticsLoadError;

  /// No description provided for @noData.
  ///
  /// In es, this message translates to:
  /// **'No hay datos'**
  String get noData;

  /// No description provided for @noDataSubtitle.
  ///
  /// In es, this message translates to:
  /// **'No hay información disponible'**
  String get noDataSubtitle;

  /// No description provided for @menuGroupAcademic.
  ///
  /// In es, this message translates to:
  /// **'Académico'**
  String get menuGroupAcademic;

  /// No description provided for @menuGroupCommunication.
  ///
  /// In es, this message translates to:
  /// **'Comunicación'**
  String get menuGroupCommunication;

  /// No description provided for @menuGroupAccountSupport.
  ///
  /// In es, this message translates to:
  /// **'Cuenta y soporte'**
  String get menuGroupAccountSupport;

  /// No description provided for @menuCalendar.
  ///
  /// In es, this message translates to:
  /// **'Calendario'**
  String get menuCalendar;

  /// No description provided for @menuCourses.
  ///
  /// In es, this message translates to:
  /// **'Cursos'**
  String get menuCourses;

  /// No description provided for @menuCommunication.
  ///
  /// In es, this message translates to:
  /// **'Comunicación'**
  String get menuCommunication;

  /// No description provided for @menuNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get menuNotifications;

  /// No description provided for @menuProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get menuProfile;

  /// No description provided for @menuFees.
  ///
  /// In es, this message translates to:
  /// **'Cuotas'**
  String get menuFees;

  /// No description provided for @menuHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get menuHistory;

  /// No description provided for @menuLibrary.
  ///
  /// In es, this message translates to:
  /// **'Biblioteca'**
  String get menuLibrary;

  /// No description provided for @menuDocuments.
  ///
  /// In es, this message translates to:
  /// **'Documentos'**
  String get menuDocuments;

  /// No description provided for @menuFaq.
  ///
  /// In es, this message translates to:
  /// **'FAQ'**
  String get menuFaq;

  /// No description provided for @menuBirthdays.
  ///
  /// In es, this message translates to:
  /// **'Cumpleaños'**
  String get menuBirthdays;

  /// No description provided for @menuStatistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get menuStatistics;

  /// No description provided for @menuRequests.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get menuRequests;

  /// No description provided for @menuManagement.
  ///
  /// In es, this message translates to:
  /// **'Administración'**
  String get menuManagement;

  /// No description provided for @menuGroupManagement.
  ///
  /// In es, this message translates to:
  /// **'Administración'**
  String get menuGroupManagement;

  /// No description provided for @managementTitle.
  ///
  /// In es, this message translates to:
  /// **'Administración'**
  String get managementTitle;

  /// No description provided for @managementPeople.
  ///
  /// In es, this message translates to:
  /// **'Personas'**
  String get managementPeople;

  /// No description provided for @managementAcademic.
  ///
  /// In es, this message translates to:
  /// **'Académico'**
  String get managementAcademic;

  /// No description provided for @managementContent.
  ///
  /// In es, this message translates to:
  /// **'Contenido'**
  String get managementContent;

  /// No description provided for @managementStudents.
  ///
  /// In es, this message translates to:
  /// **'Alumnos'**
  String get managementStudents;

  /// No description provided for @managementClassrooms.
  ///
  /// In es, this message translates to:
  /// **'Aulas'**
  String get managementClassrooms;

  /// No description provided for @managementNews.
  ///
  /// In es, this message translates to:
  /// **'Noticias'**
  String get managementNews;

  /// No description provided for @managementEvents.
  ///
  /// In es, this message translates to:
  /// **'Eventos'**
  String get managementEvents;

  /// No description provided for @managementDocuments.
  ///
  /// In es, this message translates to:
  /// **'Documentos'**
  String get managementDocuments;

  /// No description provided for @managementFaqs.
  ///
  /// In es, this message translates to:
  /// **'Preguntas frecuentes'**
  String get managementFaqs;

  /// No description provided for @requestsTitle.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get requestsTitle;

  /// No description provided for @requestsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar solicitudes...'**
  String get requestsSearchHint;

  /// No description provided for @requestsTypeAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get requestsTypeAll;

  /// No description provided for @requestsTypeStudents.
  ///
  /// In es, this message translates to:
  /// **'Alumnos'**
  String get requestsTypeStudents;

  /// No description provided for @requestsTypeParents.
  ///
  /// In es, this message translates to:
  /// **'Padres/Tutores'**
  String get requestsTypeParents;

  /// No description provided for @requestsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes'**
  String get requestsEmptyTitle;

  /// No description provided for @requestsEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes para estos filtros'**
  String get requestsEmptySubtitle;

  /// No description provided for @requestsEmptySearch.
  ///
  /// In es, this message translates to:
  /// **'Probá con otro nombre, email o DNI'**
  String get requestsEmptySearch;

  /// No description provided for @requestsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las solicitudes'**
  String get requestsLoadError;

  /// No description provided for @requestsKindStudent.
  ///
  /// In es, this message translates to:
  /// **'Alumno'**
  String get requestsKindStudent;

  /// No description provided for @requestsKindParent.
  ///
  /// In es, this message translates to:
  /// **'Padre/Tutor'**
  String get requestsKindParent;

  /// No description provided for @requestsChildrenCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{1 hijo} other{{count} hijos}}'**
  String requestsChildrenCount(int count);

  /// No description provided for @requestsDetailLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la solicitud'**
  String get requestsDetailLoadError;

  /// No description provided for @requestsSectionDocuments.
  ///
  /// In es, this message translates to:
  /// **'Documentación'**
  String get requestsSectionDocuments;

  /// No description provided for @requestsNoDocuments.
  ///
  /// In es, this message translates to:
  /// **'Sin documentación cargada'**
  String get requestsNoDocuments;

  /// No description provided for @requestsDocumentFrontDni.
  ///
  /// In es, this message translates to:
  /// **'DNI frente'**
  String get requestsDocumentFrontDni;

  /// No description provided for @requestsDocumentSelfie.
  ///
  /// In es, this message translates to:
  /// **'Selfie'**
  String get requestsDocumentSelfie;

  /// No description provided for @requestsDocumentOther.
  ///
  /// In es, this message translates to:
  /// **'Documento'**
  String get requestsDocumentOther;

  /// No description provided for @requestsSectionChildren.
  ///
  /// In es, this message translates to:
  /// **'Alumnos vinculados'**
  String get requestsSectionChildren;

  /// No description provided for @requestsPhone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get requestsPhone;

  /// No description provided for @requestsAddress.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get requestsAddress;

  /// No description provided for @requestsOpenDocumentError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el documento'**
  String get requestsOpenDocumentError;

  /// No description provided for @requestsActionApprove.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get requestsActionApprove;

  /// No description provided for @requestsActionReject.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get requestsActionReject;

  /// No description provided for @requestsApproveTitle.
  ///
  /// In es, this message translates to:
  /// **'Aprobar solicitud'**
  String get requestsApproveTitle;

  /// No description provided for @requestsApproveStudentBody.
  ///
  /// In es, this message translates to:
  /// **'Elegí el curso para el alumno.'**
  String get requestsApproveStudentBody;

  /// No description provided for @requestsApproveParentTitle.
  ///
  /// In es, this message translates to:
  /// **'Aprobar tutor'**
  String get requestsApproveParentTitle;

  /// No description provided for @requestsApproveParentBody.
  ///
  /// In es, this message translates to:
  /// **'Se aprobará el tutor. Los hijos pendientes se pueden aprobar desde su propia solicitud.'**
  String get requestsApproveParentBody;

  /// No description provided for @requestsRejectTitle.
  ///
  /// In es, this message translates to:
  /// **'Rechazar solicitud'**
  String get requestsRejectTitle;

  /// No description provided for @requestsRejectStudentBody.
  ///
  /// In es, this message translates to:
  /// **'El alumno quedará rechazado y se eliminará su acceso.'**
  String get requestsRejectStudentBody;

  /// No description provided for @requestsRejectParentBody.
  ///
  /// In es, this message translates to:
  /// **'El tutor y sus hijos pendientes quedarán rechazados y se eliminarán sus accesos.'**
  String get requestsRejectParentBody;

  /// No description provided for @requestsApproveConfirm.
  ///
  /// In es, this message translates to:
  /// **'Aprobar'**
  String get requestsApproveConfirm;

  /// No description provided for @requestsRejectConfirm.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get requestsRejectConfirm;

  /// No description provided for @requestsApprovedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Solicitud aprobada'**
  String get requestsApprovedSuccess;

  /// No description provided for @requestsRejectedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Solicitud rechazada'**
  String get requestsRejectedSuccess;

  /// No description provided for @requestsNoChange.
  ///
  /// In es, this message translates to:
  /// **'La solicitud ya estaba resuelta'**
  String get requestsNoChange;

  /// No description provided for @requestsActionError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la acción'**
  String get requestsActionError;

  /// No description provided for @requestsClassroomPickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Elegir curso'**
  String get requestsClassroomPickerTitle;

  /// No description provided for @requestsClassroomPickerSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar curso...'**
  String get requestsClassroomPickerSearch;

  /// No description provided for @requestsClassroomPickerEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay cursos disponibles'**
  String get requestsClassroomPickerEmpty;

  /// No description provided for @requestsClassroomPickerLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los cursos'**
  String get requestsClassroomPickerLoadError;

  /// No description provided for @requestsClassroomPickerConfirm.
  ///
  /// In es, this message translates to:
  /// **'Aprobar y asignar curso'**
  String get requestsClassroomPickerConfirm;

  /// No description provided for @historyTitle.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get historyTitle;

  /// No description provided for @historySearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar cursos archivados...'**
  String get historySearchHint;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin cursos archivados'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Los cursos archivados aparecerán acá'**
  String get historyEmptySubtitle;

  /// No description provided for @historyEmptySearch.
  ///
  /// In es, this message translates to:
  /// **'No encontramos cursos archivados con esa búsqueda'**
  String get historyEmptySearch;

  /// No description provided for @historyLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el historial'**
  String get historyLoadError;

  /// No description provided for @historyArchivedBadge.
  ///
  /// In es, this message translates to:
  /// **'Archivado'**
  String get historyArchivedBadge;

  /// No description provided for @historyChooseChild.
  ///
  /// In es, this message translates to:
  /// **'Elegí un hijo para ver su historial'**
  String get historyChooseChild;

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin materiales'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay materiales disponibles'**
  String get libraryEmptySubtitle;

  /// No description provided for @libraryEmptySearch.
  ///
  /// In es, this message translates to:
  /// **'No encontramos materiales con esa búsqueda'**
  String get libraryEmptySearch;

  /// No description provided for @libraryLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los materiales'**
  String get libraryLoadError;

  /// No description provided for @libraryOpenError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el enlace'**
  String get libraryOpenError;

  /// No description provided for @libraryNoLink.
  ///
  /// In es, this message translates to:
  /// **'Este material no tiene un enlace disponible'**
  String get libraryNoLink;

  /// No description provided for @libraryLoadingMore.
  ///
  /// In es, this message translates to:
  /// **'Cargando más materiales...'**
  String get libraryLoadingMore;

  /// No description provided for @faqsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin preguntas'**
  String get faqsEmptyTitle;

  /// No description provided for @faqsEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay preguntas frecuentes'**
  String get faqsEmptySubtitle;

  /// No description provided for @faqsEmptySearch.
  ///
  /// In es, this message translates to:
  /// **'No encontramos preguntas con esa búsqueda'**
  String get faqsEmptySearch;

  /// No description provided for @faqsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las preguntas frecuentes'**
  String get faqsLoadError;

  /// No description provided for @statisticsDetailsTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalles'**
  String get statisticsDetailsTitle;

  /// No description provided for @statisticsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin estadísticas'**
  String get statisticsEmptyTitle;

  /// No description provided for @statisticsEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay datos para mostrar'**
  String get statisticsEmptySubtitle;

  /// No description provided for @statisticsMoreItems.
  ///
  /// In es, this message translates to:
  /// **'+{count} más'**
  String statisticsMoreItems(int count);

  /// No description provided for @statisticsTotalStudents.
  ///
  /// In es, this message translates to:
  /// **'Alumnos'**
  String get statisticsTotalStudents;

  /// No description provided for @statisticsTotalClassrooms.
  ///
  /// In es, this message translates to:
  /// **'Aulas'**
  String get statisticsTotalClassrooms;

  /// No description provided for @statisticsFeesPaidThisYear.
  ///
  /// In es, this message translates to:
  /// **'Cuotas pagadas (año)'**
  String get statisticsFeesPaidThisYear;

  /// No description provided for @statisticsFeesOverdue.
  ///
  /// In es, this message translates to:
  /// **'Cuotas en mora'**
  String get statisticsFeesOverdue;

  /// No description provided for @statisticsTotalOwed.
  ///
  /// In es, this message translates to:
  /// **'Monto adeudado'**
  String get statisticsTotalOwed;

  /// No description provided for @statisticsFeesPendingReview.
  ///
  /// In es, this message translates to:
  /// **'Comprobantes en revisión'**
  String get statisticsFeesPendingReview;

  /// No description provided for @statisticsOpenTickets.
  ///
  /// In es, this message translates to:
  /// **'Tickets abiertos'**
  String get statisticsOpenTickets;

  /// No description provided for @statisticsAbsencesThisMonth.
  ///
  /// In es, this message translates to:
  /// **'Inasistencias del mes'**
  String get statisticsAbsencesThisMonth;

  /// No description provided for @statisticsClassroomsCount.
  ///
  /// In es, this message translates to:
  /// **'Aulas'**
  String get statisticsClassroomsCount;

  /// No description provided for @statisticsAbsencesToday.
  ///
  /// In es, this message translates to:
  /// **'Inasistencias hoy'**
  String get statisticsAbsencesToday;

  /// No description provided for @statisticsFeesPaid.
  ///
  /// In es, this message translates to:
  /// **'Cuotas pagadas'**
  String get statisticsFeesPaid;

  /// No description provided for @statisticsFeesPending.
  ///
  /// In es, this message translates to:
  /// **'Cuotas pendientes'**
  String get statisticsFeesPending;

  /// No description provided for @statisticsChildrenCount.
  ///
  /// In es, this message translates to:
  /// **'Hijos'**
  String get statisticsChildrenCount;

  /// No description provided for @statisticsTotalAbsences.
  ///
  /// In es, this message translates to:
  /// **'Total de inasistencias'**
  String get statisticsTotalAbsences;

  /// No description provided for @statisticsTotalClasses.
  ///
  /// In es, this message translates to:
  /// **'Total de clases'**
  String get statisticsTotalClasses;

  /// No description provided for @statisticsAbsenceRate.
  ///
  /// In es, this message translates to:
  /// **'Tasa de inasistencias'**
  String get statisticsAbsenceRate;

  /// No description provided for @birthdaysTodaySection.
  ///
  /// In es, this message translates to:
  /// **'Cumpleaños de hoy'**
  String get birthdaysTodaySection;

  /// No description provided for @birthdaysUpcomingSection.
  ///
  /// In es, this message translates to:
  /// **'Próximos 30 días'**
  String get birthdaysUpcomingSection;

  /// No description provided for @birthdaysNoUpcoming.
  ///
  /// In es, this message translates to:
  /// **'No hay más cumpleaños en los próximos 30 días'**
  String get birthdaysNoUpcoming;

  /// No description provided for @birthdaysToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get birthdaysToday;

  /// No description provided for @birthdaysTomorrow.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get birthdaysTomorrow;

  /// No description provided for @birthdaysInDays.
  ///
  /// In es, this message translates to:
  /// **'En {count} días'**
  String birthdaysInDays(int count);

  /// No description provided for @birthdaysTurning.
  ///
  /// In es, this message translates to:
  /// **'Cumple {age} años'**
  String birthdaysTurning(int age);

  /// No description provided for @roleModeTitle.
  ///
  /// In es, this message translates to:
  /// **'Modo de uso'**
  String get roleModeTitle;

  /// No description provided for @roleModeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elegí con qué rol querés usar la app'**
  String get roleModeSubtitle;

  /// No description provided for @roleModeCurrent.
  ///
  /// In es, this message translates to:
  /// **'Modo actual'**
  String get roleModeCurrent;

  /// No description provided for @roleModeChange.
  ///
  /// In es, this message translates to:
  /// **'Cambiar modo'**
  String get roleModeChange;

  /// No description provided for @roleModeSwitched.
  ///
  /// In es, this message translates to:
  /// **'Ahora estás en modo {role}'**
  String roleModeSwitched(String role);

  /// No description provided for @roleModeSwitchError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cambiar el modo. Intentá de nuevo.'**
  String get roleModeSwitchError;

  /// No description provided for @roleModeLoading.
  ///
  /// In es, this message translates to:
  /// **'Cambiando modo…'**
  String get roleModeLoading;

  /// No description provided for @roleModeDescriptionProfessor.
  ///
  /// In es, this message translates to:
  /// **'Tus aulas, alumnos y calificaciones'**
  String get roleModeDescriptionProfessor;

  /// No description provided for @roleModeDescriptionParent.
  ///
  /// In es, this message translates to:
  /// **'Las cuotas, el boletín y los cursos de tus hijos'**
  String get roleModeDescriptionParent;

  /// No description provided for @roleModeDescriptionStudent.
  ///
  /// In es, this message translates to:
  /// **'Tus materias, notas y asistencias'**
  String get roleModeDescriptionStudent;

  /// No description provided for @roleModeDescriptionAdmin.
  ///
  /// In es, this message translates to:
  /// **'La administración completa de la escuela'**
  String get roleModeDescriptionAdmin;

  /// No description provided for @roleModeDescriptionBranch.
  ///
  /// In es, this message translates to:
  /// **'La información de tu sede'**
  String get roleModeDescriptionBranch;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
