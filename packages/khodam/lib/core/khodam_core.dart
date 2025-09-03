import 'dart:async';

import 'package:flutter/material.dart';
import 'package:khodam/core/debug_pop_up.dart';
import 'package:khodam/core/route_banner.dart';
import 'package:khodam/helper/khodam_route_helper.dart';
import 'package:khodam/model/khodam_environtment.dart';
import 'package:khodam/model/khodam_http_call.dart';
import 'package:khodam/model/khodam_http_error.dart';
import 'package:khodam/model/khodam_http_response.dart';
import 'package:khodam/ui/page/khodam_calls_list_screen.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:rxdart/rxdart.dart';

class KhodamCore {
  /// Should user be notified with notification if there's new request catched
  /// by Khodam
  final bool showNotification;

  /// Should inspector be opened on device shake (works only with physical
  /// with sensors)
  final bool showInspectorOnShake;

  /// Should inspector use dark theme
  final bool darkTheme;

  /// Rx subject which contains all intercepted http calls
  final BehaviorSubject<List<KhodamHttpCall>> callsSubject = BehaviorSubject.seeded([]);

  /// Icon url for notification
  final String notificationIcon;

  GlobalKey<NavigatorState>? _navigatorKey;
  Brightness _brightness = Brightness.light;
  bool _isInspectorOpened = false;
  StreamSubscription? _callsSubscription;
  String? _notificationMessage;
  String? _notificationMessageShown;
  bool _notificationProcessing = false;
  final KhodamNavigatorObserver _khodamNavigatorObserver;

  static KhodamCore? _singleton;
  
  /// Constructor for the environment settings
  final KhodamEnvironment? environment;

  factory KhodamCore(
      _navigatorKey, showNotification, showInspectorOnShake, darkTheme, notificationIcon, _loggerNavigatorObserver,
      {KhodamEnvironment? environment} // Nullable environment parameter
      ) {
    _singleton ??= KhodamCore._(
      _navigatorKey,
      showNotification,
      showInspectorOnShake,
      darkTheme,
      notificationIcon,
      _loggerNavigatorObserver,
      environment, // Directly pass the nullable environment
    );
    return _singleton!;
  }

  /// Creates khodam core instance
  KhodamCore._(
    this._navigatorKey,
    this.showNotification,
    this.showInspectorOnShake,
    this.darkTheme,
    this.notificationIcon,
    this._khodamNavigatorObserver,
    this.environment, // Nullable environment
  ) {
    if (showNotification) {
      _callsSubscription = callsSubject.listen((_) => _onCallsChanged());
    }
    _brightness = darkTheme ? Brightness.dark : Brightness.light;
  }

  /// Dispose subjects and subscriptions
  void dispose() {
    callsSubject.close();
    //_shakeDetector?.stopListening();
    _callsSubscription?.cancel();
  }

  /// Get currently used brightness
  Brightness get brightness => _brightness;

  void _onCallsChanged() async {
    if (callsSubject.value.length > 0) {
      _notificationMessage = _getNotificationMessage();
      if (_notificationMessage != _notificationMessageShown && !_notificationProcessing) {
        await _showLocalNotification();
        _onCallsChanged();
      }
    }
  }

  /// Set custom navigation key. This will help if there's route library.
  void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    this._navigatorKey = navigatorKey;
  }

  /// Opens Http calls inspector. This will navigate user to the new fullscreen
  /// page where all listened http calls can be viewed.
  void navigateToCallListScreen() {
    var context = getContext();
    if (context == null) {
      print("Cant start Khodam HTTP Inspector. Please add NavigatorKey to your application");
      return;
    }
    if (!_isInspectorOpened) {
      _isInspectorOpened = true;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => KhodamCallsListScreen(this),
        ),
      ).then((onValue) => _isInspectorOpened = false);
    }
  }

  /// Get context from navigator key. Used to open inspector route.
  BuildContext? getContext() => _navigatorKey?.currentState?.overlay?.context;

  // Provide access to the LoggerNavigatorObserver
  KhodamNavigatorObserver getKhodamNavigatorObserver() {
    return _khodamNavigatorObserver;
  }

  String _getNotificationMessage() {
    List<KhodamHttpCall>? calls = callsSubject.value;
    int successCalls = calls
        .where((call) =>
            call.response != null && (call.response?.status ?? 0) >= 200 && (call.response?.status ?? 0) < 300)
        .toList()
        .length;

    int redirectCalls = calls
        .where((call) =>
            call.response != null && (call.response?.status ?? 0) >= 300 && (call.response?.status ?? 0) < 400)
        .toList()
        .length;

    int errorCalls = calls
        .where((call) =>
            call.response != null && (call.response?.status ?? 0) >= 400 && (call.response?.status ?? 0) < 600)
        .toList()
        .length;

    int loadingCalls = calls.where((call) => call.loading).toList().length;

    StringBuffer notificationsMessage = StringBuffer();
    if (loadingCalls > 0) {
      notificationsMessage.write("Loading: $loadingCalls");
      notificationsMessage.write(" | ");
    }
    if (successCalls > 0) {
      notificationsMessage.write("Success: $successCalls");
      notificationsMessage.write(" | ");
    }
    if (redirectCalls > 0) {
      notificationsMessage.write("Redirect: $redirectCalls");
      notificationsMessage.write(" | ");
    }
    if (errorCalls > 0) {
      notificationsMessage.write("Error: $errorCalls");
    }
    return notificationsMessage.toString();
  }

  Future _showLocalNotification() async {
    _notificationProcessing = true;
    String? message = _notificationMessage;
    showDebugAnimNotification();
    _notificationMessageShown = message;
    _notificationProcessing = false;
    return;
  }

  /// Add khodam http call to calls subject
  void addCall(KhodamHttpCall call) {
    callsSubject.add([call, ...callsSubject.value]);
  }

  /// Add error to exisng khodam http call
  void addError(KhodamHttpError error, int requestId) {
    KhodamHttpCall? selectedCall = _selectCall(requestId);

    if (selectedCall == null) {
      print("Selected call is null");
      return;
    }

    selectedCall.error = error;
    callsSubject.add([...callsSubject.value]);
  }

  /// Add response to existing khodam http call
  void addResponse(KhodamHttpResponse response, int requestId) {
    KhodamHttpCall? selectedCall = _selectCall(requestId);

    if (selectedCall == null) {
      print("Selected call is null");
      return;
    }
    selectedCall.loading = false;
    selectedCall.response = response;
    selectedCall.duration = response.time.millisecondsSinceEpoch - selectedCall.request!.time.millisecondsSinceEpoch;

    callsSubject.add([...callsSubject.value]);
  }

  /// Add khodam http call to calls subject
  void addHttpCall(KhodamHttpCall khodamHttpCall) {
    assert(khodamHttpCall.request != null, "Http call request can't be null");
    assert(khodamHttpCall.response != null, "Http call response can't be null");
    callsSubject.add([...callsSubject.value, khodamHttpCall]);
  }

  /// Remove all calls from calls subject
  void removeCalls() {
    callsSubject.add([]);
  }

  KhodamHttpCall? _selectCall(int requestId) => callsSubject.value.firstWhereOrNull((call) => call.id == requestId);

  bool isShowedBubble = false;

  // ValueNotifier to control whether the observer is enabled or not
  ValueNotifier<bool> showRouteObserver = ValueNotifier(true);

  void showDebugAnimNotification() {
    if (isShowedBubble) {
      return;
    }
    var context = getContext();
    if (context == null) {
      return;
    }
    isShowedBubble = true;
    showOverlay((context, t) {
      

      return Opacity(
        opacity: t,
        child: Stack(
          children: [
            ValueListenableBuilder(
                valueListenable: showRouteObserver,
                builder: (context, shouldShow, _) {
                  if (shouldShow) {
                    return RouteBanner(onClicked: () {}, khodamCore: this);
                  }
                  return const SizedBox();
                }),
            ValueListenableBuilder(
                valueListenable: showRouteObserver,
                builder: (context, shouldShow, _) {
                  return DebugPopUp(
                    callsSubscription: callsSubject.stream,
                    onClicked: () {
                      navigateToCallListScreen();
                    },
                    onRouteIconClicked: () {
                      showRouteObserver.value = !shouldShow;
                    },
                    shouldShowRoute: shouldShow,
                    khodamCore: this,
                  );
                }),
          ],
        ),
      );
    }, duration: Duration.zero);
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
