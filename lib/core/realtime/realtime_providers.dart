import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laravel_reverb/laravel_reverb.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/chat/providers/chat_provider.dart';
import '../api/api_provider.dart';
import 'realtime_service.dart';

/// Ventana de agrupación de los refrescos disparados por realtime.
///
/// Los tests la sobreescriben a [Duration.zero] para no depender del reloj.
final realtimeResyncDebounceProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 500),
);

/// Hook global de resync, disparado en cada reconexión y en cada notificación.
///
/// Refresca la primera página de la lista de chats y el contador de no leídos.
/// Una ráfaga de notificaciones se agrupa con un debounce para no disparar una
/// petición por evento. El coordinador lo resuelve por provider para que los
/// tests puedan inyectar un espía.
final realtimeResyncProvider = Provider<void Function()>((ref) {
  final debounce = ref.watch(realtimeResyncDebounceProvider);
  Timer? timer;
  ref.onDispose(() => timer?.cancel());

  return () {
    timer?.cancel();
    timer = Timer(debounce, () {
      ref.read(chatListProvider.notifier).refreshFirstPage();
      ref.invalidate(chatUnreadCountProvider);
    });
  };
});

/// Endpoint de autorización de canales a partir de la base de la API.
///
/// El backend expone la ruta Sanctum `/api/v1/broadcasting/auth`; la ruta web
/// `/broadcasting/auth` autentica solo con sesión de cookie y responde 403 a
/// un Bearer. Normaliza la barra final para no duplicarla.
String broadcastingAuthEndpoint(String apiBaseUrl) {
  final base = apiBaseUrl.endsWith('/')
      ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
      : apiBaseUrl;
  return '$base/broadcasting/auth';
}

/// En el emulador Android `localhost` es el propio dispositivo, no la máquina
/// de desarrollo: se traduce al alias del host, `10.0.2.2`. Un host explícito
/// (IP de LAN, dominio) se respeta tal cual.
String resolveRealtimeHost(String host, {required bool isAndroid}) {
  if (!isAndroid) return host;
  if (host == 'localhost' || host == '127.0.0.1') return '10.0.2.2';
  return host;
}

/// Servicio de producción, construido desde `.env` + [secureStorageProvider].
///
/// Los tests lo reemplazan por un fake; por eso el coordinador nunca toca el
/// `Reverb` directamente.
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final apiBaseUrl =
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api/v1';
  final scheme = dotenv.env['REVERB_SCHEME'] ?? 'http';
  final useTls = scheme == 'https' || scheme == 'wss';
  final host = resolveRealtimeHost(
    dotenv.env['REVERB_HOST'] ?? 'localhost',
    isAndroid: defaultTargetPlatform == TargetPlatform.android,
  );

  return RealtimeService(
    reverb: Reverb(
      host: host,
      port: int.tryParse(dotenv.env['REVERB_PORT'] ?? '') ?? 8181,
      appKey: dotenv.env['REVERB_APP_KEY'] ?? '',
      useTls: useTls,
      authEndpoint: broadcastingAuthEndpoint(apiBaseUrl),
      onError: (error, stackTrace) {
        debugPrint('[Realtime] $error');
      },
      // Leído en cada intento para que un token refrescado se use sin
      // recrear el cliente.
      authHeaders: () async {
        final token = await storage.getToken();
        if (token == null || token.isEmpty) return <String, String>{};
        return <String, String>{'Authorization': 'Bearer $token'};
      },
    ),
  );
});

/// Ciclo de vida del socket, tal como lo reporta [RealtimeService.states].
final realtimeConnectionProvider = StreamProvider<ReverbState>((ref) {
  return ref.watch(realtimeServiceProvider).states;
});

/// `true` solo con sesión iniciada y el handshake completo.
final realtimeReadyProvider = Provider<bool>((ref) {
  final auth = ref.watch(authProvider);
  final connection = ref.watch(realtimeConnectionProvider);
  return auth.status == AuthStatus.authenticated &&
      auth.user != null &&
      connection.valueOrNull == ReverbState.connected;
});

/// Coordinador único del ciclo de vida realtime ligado a `authProvider`.
///
/// - sesión `authenticated` → conecta y suscribe `notifications.{userId}`.
/// - sesión no autenticada con sesión activa → cancela la suscripción y
///   `disconnect(forget: true)`.
/// - montaje con sesión ya restaurada (arranque en frío) → conecta.
///
/// Registra como máximo un listener de reconexión a la vez. Se vuelve a
/// registrar en cada login porque `disconnect(forget: true)` descarta los
/// listeners guardados por [RealtimeService].
final realtimeCoordinatorProvider = Provider<void>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  final resync = ref.watch(realtimeResyncProvider);

  Subscription? notifications;
  VoidCallback? removeResyncListener;
  String? activeUserId;

  Future<void> startSession(String userId) async {
    removeResyncListener ??= service.addReconnectListener(resync);
    notifications ??= service.watchNotifications(
      userId: userId,
      onNotification: resync,
    );
    activeUserId = userId;
    try {
      await service.connect();
    } catch (_) {
      // El primer intento puede fallar (Reverb caído): el paquete reintenta
      // con backoff y reporta por `onError`. No debe escapar como excepción
      // no controlada, porque el chat sigue funcionando por REST.
    }
  }

  Future<void> stopSession() async {
    notifications?.cancel();
    notifications = null;
    removeResyncListener?.call();
    removeResyncListener = null;
    activeUserId = null;
    await service.disconnect(forget: true);
  }

  Future<void> activate(String userId) async {
    if (activeUserId != null && activeUserId != userId) {
      await stopSession();
    }
    await startSession(userId);
  }

  ref.listen<AuthState>(authProvider, (previous, next) {
    final user = next.user;
    if (next.status == AuthStatus.authenticated && user != null) {
      if (activeUserId == user.id) return;
      unawaited(activate(user.id));
    } else if (activeUserId != null) {
      unawaited(stopSession());
    }
  });

  // `ref.listen` solo ve cambios posteriores al montaje: el arranque en frío
  // (sesión restaurada por `AuthNotifier._init`) se atiende una vez aquí.
  final initial = ref.read(authProvider);
  final initialUser = initial.user;
  if (initial.status == AuthStatus.authenticated && initialUser != null) {
    unawaited(startSession(initialUser.id));
  }

  ref.onDispose(() {
    notifications?.cancel();
    notifications = null;
    removeResyncListener?.call();
    removeResyncListener = null;
  });
});
