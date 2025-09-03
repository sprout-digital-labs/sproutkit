import 'package:flutter/material.dart';
import 'khodam_core.dart';

class RouteBanner extends StatefulWidget {
  final VoidCallback onClicked;
  final KhodamCore khodamCore;

  const RouteBanner({
    Key? key,
    required this.onClicked,
    required this.khodamCore,
  }) : super(key: key);

  @override
  _RouteBannerState createState() => _RouteBannerState();
}

class _RouteBannerState extends State<RouteBanner> {
  @override
  Widget build(BuildContext context) {
    final routeHistory = widget.khodamCore.getKhodamNavigatorObserver().getRouteHistory();

    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: GestureDetector(
                onPanUpdate: (details) {},
                child: Opacity(
                  opacity: 0.5,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    color: Colors.blue,
                    child: Text(
                      routeHistory.isEmpty ? "" : "${routeHistory.last.routeName}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12, // Adjust based on the size of the button
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )),
          ),
        ],
      ),
    );
  }
}
