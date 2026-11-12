import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/providers/chat_provider.dart';
import '../../classrooms/providers/classroom_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../documents/providers/document_provider.dart';
import '../../events/providers/event_provider.dart';
import '../../fees/providers/fee_provider.dart';
import '../../news/providers/news_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../qualifications/providers/qualification_provider.dart';
import '../../relations/providers/relations_provider.dart';
import '../../relations/providers/selected_child_provider.dart';
import '../../students/providers/student_provider.dart';
import '../data/role_mode_api.dart';
import '../data/role_mode_repository.dart';

enum RoleSwitchStatus { idle, switching, error }

class RoleSwitchState {
  final RoleSwitchStatus status;
  final String? error;

  const RoleSwitchState({this.status = RoleSwitchStatus.idle, this.error});

  bool get isSwitching => status == RoleSwitchStatus.switching;
}

final roleModeApiProvider = Provider<RoleModeApi>((ref) {
  return RoleModeApi(ref.watch(apiClientProvider));
});

final roleModeRepositoryProvider = Provider<RoleModeRepository>((ref) {
  return RoleModeRepository(ref.watch(roleModeApiProvider));
});

class RoleSwitchController extends StateNotifier<RoleSwitchState> {
  final Ref _ref;
  final RoleModeRepository _repository;

  RoleSwitchController(this._ref, this._repository)
      : super(const RoleSwitchState());

  Future<bool> switchTo(String role) async {
    state = const RoleSwitchState(status: RoleSwitchStatus.switching);

    try {
      final result = await _repository.switchRole(role);

      _ref
          .read(authProvider.notifier)
          .applyActiveRole(role: result.role, roles: result.roles);
      _ref.read(parentSelectedStudentProvider.notifier).state =
          result.role == 'parent' ? result.selectedStudentId : null;

      _invalidateRoleScopedProviders();
      state = const RoleSwitchState();
      return true;
    } catch (error) {
      state = RoleSwitchState(
        status: RoleSwitchStatus.error,
        error: error.toString(),
      );
      return false;
    }
  }

  void _invalidateRoleScopedProviders() {
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(relationsProvider);

    _ref.invalidate(classroomListProvider);
    _ref.invalidate(classroomFiltersProvider);
    _ref.invalidate(classroomDetailProvider);
    _ref.invalidate(classroomStudentsProvider);
    _ref.invalidate(classroomProfessorsProvider);
    _ref.invalidate(classroomMaterialsProvider);
    _ref.invalidate(classroomHistoryProvider);
    _ref.invalidate(parentCoursesProvider);

    _ref.invalidate(studentListProvider);
    _ref.invalidate(studentDetailProvider);
    _ref.invalidate(studentClassroomsProvider);
    _ref.invalidate(studentAbsencesProvider);
    _ref.invalidate(studentFeesProvider);

    _ref.invalidate(feeListProvider);
    _ref.invalidate(parentFeesProvider);
    _ref.invalidate(feeDetailProvider);

    _ref.invalidate(qualificationListProvider);
    _ref.invalidate(boletinProvider);

    _ref.invalidate(chatListProvider);
    _ref.invalidate(chatUnreadCountProvider);
    _ref.invalidate(messagesProvider);

    _ref.invalidate(notificationListProvider);
    _ref.invalidate(unreadCountProvider);

    _ref.invalidate(documentListProvider);
    _ref.invalidate(eventListProvider);
    _ref.invalidate(newsListProvider);
  }
}

final roleSwitchControllerProvider =
    StateNotifierProvider<RoleSwitchController, RoleSwitchState>((ref) {
  return RoleSwitchController(ref, ref.watch(roleModeRepositoryProvider));
});
