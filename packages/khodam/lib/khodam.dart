import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:khodam/core/khodam_chopper_response_interceptor.dart';
import 'package:khodam/core/khodam_core.dart';
import 'package:khodam/core/khodam_dio_interceptor.dart';
import 'package:khodam/core/khodam_http_adapter.dart';
import 'package:khodam/core/khodam_http_client_adapter.dart';
import 'package:khodam/helper/khodam_route_helper.dart';
import 'package:khodam/model/khodam_environtment.dart';
import 'package:khodam/model/khodam_http_call.dart';
import 'package:http/http.dart' as http;

class Khodam {
  /// Should user be notified with notification if there's new request catched
  /// by Khodam
  final bool showNotification;

  /// Should inspector be opened on device shake (works only with physical
  /// with sensors)
  final bool showInspectorOnShake;

  /// Should inspector use dark theme
  final bool darkTheme;

  /// Icon url for notification
  final String notificationIcon;

  /// Environment that used by app
  final KhodamEnvironment? environtment;

  GlobalKey<NavigatorState>? _navigatorKey;
  late KhodamCore _khodamCore;
  late KhodamHttpClientAdapter _httpClientAdapter;
  late KhodamHttpAdapter _httpAdapter;
  late KhodamNavigatorObserver _loggerNavigatorObserver;

  /// Creates khodam instance.
  Khodam({
    GlobalKey<NavigatorState>? navigatorKey,
    this.showNotification = true,
    this.showInspectorOnShake = false,
    this.darkTheme = false,
    this.notificationIcon = "@mipmap/ic_launcher",
    this.environtment,
  }) {
    _navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>();
    _loggerNavigatorObserver = KhodamNavigatorObserver();
    _khodamCore = KhodamCore(
      _navigatorKey,
      showNotification,
      showInspectorOnShake,
      darkTheme,
      notificationIcon,
      _loggerNavigatorObserver,
      environment: environtment,

    );
    _httpClientAdapter = KhodamHttpClientAdapter(_khodamCore);
    _httpAdapter = KhodamHttpAdapter(_khodamCore);
  }

  KhodamNavigatorObserver get loggerNavigatorObserver => _loggerNavigatorObserver;

  /// Set custom navigation key. This will help if there's route library.
  void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _khodamCore.setNavigatorKey(navigatorKey);
  }

  /// Get currently used navigation key
  GlobalKey<NavigatorState>? getNavigatorKey() {
    return _navigatorKey;
  }

  List<NavigatorObserver> getNavigatorObservers() {
    return [_loggerNavigatorObserver]; // Return a list containing the logger observer
  }

  /// Get Dio interceptor which should be applied to Dio instance.
  KhodamDioInterceptor getDioInterceptor() {
    return KhodamDioInterceptor(_khodamCore);
  }

  /// Handle request from HttpClient
  void onHttpClientRequest(HttpClientRequest request, {dynamic body}) {
    _httpClientAdapter.onRequest(request, body: body);
  }

  /// Handle response from HttpClient
  void onHttpClientResponse(HttpClientResponse response, HttpClientRequest request, {dynamic body}) {
    _httpClientAdapter.onResponse(response, request, body: body);
  }

  /// Handle both request and response from http package
  void onHttpResponse(http.Response response, {dynamic body}) {
    _httpAdapter.onResponse(response, body: body);
  }

  /// Opens Http calls inspector. This will navigate user to the new fullscreen
  /// page where all listened http calls can be viewed.
  void showInspector() {
    _khodamCore.navigateToCallListScreen();
  }

  /// Get chopper interceptor. This should be added to Chopper instance.
  List<ResponseInterceptor> getChopperInterceptor() {
    return [KhodamChopperInterceptor(_khodamCore)];
  }

  /// Handle generic http call. Can be used to any http client.R
  void addHttpCall(KhodamHttpCall khodamHttpCall) {
    assert(khodamHttpCall.request != null, "Http call request can't be null");
    assert(khodamHttpCall.response != null, "Http call response can't be null");
    _khodamCore.addCall(khodamHttpCall);
  }
}
