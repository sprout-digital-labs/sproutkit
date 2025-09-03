import 'package:flutter/material.dart';
import 'dart:developer';

class KhodamRouteInfo {
  final String routeName;
  final DateTime createdAt;

  KhodamRouteInfo({required this.routeName, required this.createdAt});
}

class KhodamNavigatorObserver extends NavigatorObserver {
  final List<KhodamRouteInfo> routeHistory = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    String routeName = route.settings.name ?? 'UnnamedRoute';
    if (routeName != 'UnnamedRoute') routeHistory.add(KhodamRouteInfo(routeName: routeName, createdAt: DateTime.now()));
    _logNavigation(routeName, 'push', route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name != null && routeHistory.isNotEmpty) {
      routeHistory.removeLast();
      _logNavigation(route.settings.name, 'pop', route);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null && oldRoute != null && oldRoute.settings.name != null) {
      // Find the index of the map where the "route" matches the old route name
      int index = routeHistory.indexWhere((entry) => entry.routeName == oldRoute.settings.name);

      if (index != -1) {
        // Replace the old route with the new route in the routeHistory list
        routeHistory[index] = KhodamRouteInfo(
          routeName: newRoute.settings.name!,
          createdAt: DateTime.now(),
        );
      }

      _logNavigation(newRoute.settings.name, 'replace', newRoute);
    }
  }

  void _logNavigation(String? routeName, String action, Route<dynamic> route) {
    inspect(route);
    String timestamp = DateTime.now().toString(); // Get the current timestamp
    if (routeName != null) {
      log('[$timestamp] Screen $action: $routeName', name: 'Navigation'); // Log with the timestamp
    }
  }

  List<KhodamRouteInfo> getRouteHistory() {
    return List.unmodifiable(routeHistory);
  }
}
