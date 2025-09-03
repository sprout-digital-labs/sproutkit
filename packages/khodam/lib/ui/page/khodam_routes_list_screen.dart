import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:khodam/core/khodam_core.dart';
import 'package:khodam/helper/khodam_route_helper.dart';

class KhodamRoutesScreen extends StatelessWidget {
  final KhodamCore khodamCore;

  const KhodamRoutesScreen(
    this.khodamCore,
  );

  @override
  Widget build(BuildContext context) {
    final routeHistory = khodamCore.getKhodamNavigatorObserver().getRouteHistory();
    log('route length ${routeHistory.length}');
    return Theme(
      data: ThemeData(
        brightness: khodamCore.brightness,
        primarySwatch: Colors.green,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text("Khodam - Routes List"),
        ),
        body: Container(
          padding: const EdgeInsets.all(8),
          child: _buildListWidget(routeHistory),
        ),
      ),
    );
  }

  Widget _buildListWidget(List route) {
    return ListView.builder(
      itemCount: route.length,
      itemBuilder: (context, index) {
        return RouteListItemWidget(
          routeInfo: route[index],
          itemClickAction: null,
        );
      },
    );
  }
}

class RouteListItemWidget extends StatelessWidget {
  final KhodamRouteInfo routeInfo;
  final Function(KhodamRouteInfo)? itemClickAction;

  const RouteListItemWidget({required this.routeInfo, required this.itemClickAction});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (itemClickAction != null) {
          itemClickAction!(routeInfo);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            width: double.maxFinite,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${routeInfo.routeName}",
                  textAlign: TextAlign.start,
                  style: TextStyle(fontSize: 16, color: Colors.blue.withOpacity(.5)),
                ),
                const SizedBox(height: 8),
                Text(
                  "${_formatTime(routeInfo.createdAt)}",
                  textAlign: TextAlign.start,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${formatTimeUnit(time.hour)}:"
        "${formatTimeUnit(time.minute)}:"
        "${formatTimeUnit(time.second)}:"
        "${formatTimeUnit(time.millisecond)}";
  }

  String formatTimeUnit(int timeUnit) {
    return (timeUnit < 10) ? "0$timeUnit" : "$timeUnit";
  }
}
