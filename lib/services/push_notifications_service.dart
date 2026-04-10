import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../pages/executions/execution_detail_page.dart';
import '../utils/app_toast.dart' show AppToast;
import 'preferences_service.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint(
      'FCM background message: ${message.messageId} '
      '${message.notification?.title ?? '(no title)'}',
    );
  } catch (error) {
    debugPrint('FCM background init failed: $error');
  }
}

class PushNotificationsEnableResult {
  const PushNotificationsEnableResult({
    required this.enabled,
    this.token,
    this.message,
  });

  final bool enabled;
  final String? token;
  final String? message;
}

class PushNotificationsService {
  PushNotificationsService._();

  static final PushNotificationsService instance = PushNotificationsService._();

  FirebaseMessaging? _messaging;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _notificationTapSubscription;
  bool _isAvailable = false;
  String? _initializationError;
  RemoteMessage? _pendingNotificationMessage;
  bool _didConfigureNavigation = false;

  bool get isAvailable => _isAvailable;
  String? get initializationError => _initializationError;
  String? get currentToken => PreferencesService.instance.pushNotificationToken;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;
      await _messaging!.setAutoInitEnabled(
        PreferencesService.instance.pushNotificationsEnabled,
      );

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      _foregroundSubscription ??= FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );
      _tokenRefreshSubscription ??= _messaging!.onTokenRefresh.listen(
        _handleTokenRefresh,
      );

      _isAvailable = true;
      _initializationError = null;

      if (PreferencesService.instance.pushNotificationsEnabled) {
        await refreshToken();
      }
    } catch (error) {
      _isAvailable = false;
      _initializationError = error.toString();
      debugPrint('FCM initialization failed: $error');
    }
  }

  Future<void> configureNotificationNavigation() async {
    if (!_isAvailable || _messaging == null || _didConfigureNavigation) return;

    _didConfigureNavigation = true;
    _notificationTapSubscription ??= FirebaseMessaging.onMessageOpenedApp
        .listen(_handleNotificationOpen);

    final initialMessage = await _messaging!.getInitialMessage();
    if (initialMessage != null) {
      _pendingNotificationMessage = initialMessage;
    }
  }

  Future<void> consumePendingNotificationNavigation() async {
    final message = _pendingNotificationMessage;
    if (message == null) return;

    _pendingNotificationMessage = null;
    await _handleNotificationOpen(message);
  }

  Future<PushNotificationsEnableResult> enableNotifications() async {
    if (!_isAvailable || _messaging == null) {
      return PushNotificationsEnableResult(
        enabled: false,
        message:
            _initializationError ??
            'Firebase is not configured yet. Add google-services.json first.',
      );
    }

    await _messaging!.setAutoInitEnabled(true);
    final settings = await _messaging!.requestPermission();
    if (!_isPermissionGranted(settings)) {
      await PreferencesService.instance.setPushNotificationsEnabled(false);
      return const PushNotificationsEnableResult(
        enabled: false,
        message: 'Notification permission was not granted.',
      );
    }

    final token = await _messaging!.getToken();
    if (token == null || token.isEmpty) {
      await PreferencesService.instance.setPushNotificationsEnabled(false);
      await PreferencesService.instance.setPushNotificationToken(null);
      return const PushNotificationsEnableResult(
        enabled: false,
        message: 'No FCM device token was returned.',
      );
    }

    debugPrint('FCM token: $token');
    await PreferencesService.instance.setPushNotificationsEnabled(true);
    await PreferencesService.instance.setPushNotificationToken(token);

    return PushNotificationsEnableResult(enabled: true, token: token);
  }

  Future<void> disableNotifications() async {
    if (_messaging != null) {
      await _messaging!.deleteToken();
      await _messaging!.setAutoInitEnabled(false);
    }

    await PreferencesService.instance.setPushNotificationsEnabled(false);
    await PreferencesService.instance.setPushNotificationToken(null);
  }

  Future<String?> refreshToken() async {
    if (!_isAvailable || _messaging == null) return currentToken;

    final token = await _messaging!.getToken();
    debugPrint('FCM token: $token');
    await PreferencesService.instance.setPushNotificationToken(token);
    return token;
  }

  bool _isPermissionGranted(NotificationSettings settings) {
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> _handleTokenRefresh(String token) async {
    debugPrint('FCM token refreshed: $token');
    await PreferencesService.instance.setPushNotificationToken(token);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final context = appNavigatorKey.currentContext;
    if (context == null) return;

    final title = message.notification?.title ?? 'Notification received';
    final body = message.notification?.body;
    AppToast.info(context, body ?? title, title: body != null ? title : null);
  }

  Future<void> _handleNotificationOpen(RemoteMessage message) async {
    final executionId = _extractExecutionId(message);
    if (executionId == null || executionId.isEmpty) return;
    await _openExecutionDetail(
      executionId,
      initialExecution: _notificationExecutionPayload(message),
    );
  }

  String? _extractExecutionId(RemoteMessage message) {
    final executionId =
        message.data['executionId'] ?? message.data['execution_id'];
    if (executionId == null) return null;
    final text = executionId.toString().trim();
    return text.isEmpty ? null : text;
  }

  Map<String, dynamic> _notificationExecutionPayload(RemoteMessage message) {
    final data = message.data;

    Map<String, dynamic>? error;
    final errorMessage = data['errorMessage']?.trim();
    final errorStack = data['errorStack']?.trim();
    if ((errorMessage ?? '').isNotEmpty || (errorStack ?? '').isNotEmpty) {
      error = <String, dynamic>{
        if ((errorMessage ?? '').isNotEmpty) 'message': errorMessage,
        if ((errorStack ?? '').isNotEmpty) 'stack': errorStack,
      };
    }

    return <String, dynamic>{
      'id': _extractExecutionId(message),
      'workflowId': data['workflowId'] ?? data['workflow_id'],
      'workflowName': data['workflowName'] ?? data['workflow_name'],
      'url': data['executionUrl'] ?? data['execution_url'],
      'retryOf': data['retryOf'] ?? data['retry_of'],
      'mode': data['mode'],
      'finished': true,
      'status': 'error',
      'lastNodeExecuted':
          data['lastNodeExecuted'] ?? data['last_node_executed'],
      'error': error,
      'data': <String, dynamic>{'error': error},
      'customData': <String, dynamic>{
        'notificationTitle': message.notification?.title,
        'notificationBody': message.notification?.body,
      },
    };
  }

  Future<void> _openExecutionDetail(
    String executionId, {
    Map<String, dynamic>? initialExecution,
  }) async {
    if (appNavigatorKey.currentState == null) {
      _pendingNotificationMessage = null;
      return;
    }

    try {
      final navigator = appNavigatorKey.currentState;
      if (navigator == null || !navigator.mounted) {
        _pendingNotificationMessage = null;
        return;
      }

      await navigator.push(
        MaterialPageRoute(
          builder: (_) => ExecutionDetailPage(
            executionId: executionId,
            initialExecution:
                initialExecution ?? <String, dynamic>{'id': executionId},
          ),
        ),
      );
    } catch (error) {
      final navigator = appNavigatorKey.currentState;
      if (navigator == null || !navigator.mounted) {
        _pendingNotificationMessage = null;
        return;
      }

      AppToast.error(
        navigator.context,
        error.toString(),
        title: 'Could not open execution',
      );
    }
  }
}
