import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:khodam/model/khodam_http_call.dart';
import 'package:khodam/ui/page/khodam_stats_screen.dart';

import 'khodam_core.dart';
import 'expandable_fab.dart';

class DebugPopUp extends StatefulWidget {
  final VoidCallback onClicked;
  final Stream<List<KhodamHttpCall>> callsSubscription;
  final KhodamCore khodamCore;
  final bool shouldShowRoute;
  final VoidCallback onRouteIconClicked;

  const DebugPopUp({
    Key? key,
    required this.onClicked,
    required this.callsSubscription,
    required this.khodamCore,
    required this.shouldShowRoute,
    required this.onRouteIconClicked,
  }) : super(key: key);

  @override
  _DebugPopUpState createState() => _DebugPopUpState();
}

class _DebugPopUpState extends State<DebugPopUp> {
  Offset _offset = Offset.zero;
  final _expandedDistance = 100.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final _size = MediaQuery.of(context).size;
    final _rightSide = _expandedDistance + kToolbarHeight + 20;
    _offset = Offset(
      _size.width - _rightSide,
      _size.height / 2 - _expandedDistance,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            left: _offset.dx,
            top: _offset.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                _offset += details.delta;
                setState(() {});
              },
              child: _buildDraggyWidget(
                widget.onClicked,
                widget.callsSubscription,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggyWidget(
    VoidCallback onClicked,
    Stream<List<KhodamHttpCall>> stream,
  ) {
    return ExpandableFab(
      distance: _expandedDistance,
      bigButton: Opacity(
        opacity: 0.6,
        child: StreamBuilder<List<KhodamHttpCall>>(
          initialData: [],
          stream: stream,
          builder: (context, sns) {
            final counter = min(sns.data?.length ?? 0, 99);

            // Calculate background color based on the current stream data
            final backgroundColor = _getFloatingActionButtonColor(sns.data ?? [], context);

            return GhostFab(
              onPressed: onClicked,
              backgroundColor: backgroundColor.withOpacity(0.4),
              count: counter,
              envName: widget.khodamCore.environment?.environmentName,
            );
          },
        ),
      ),
      children: [
        ActionButton(
          onPressed: () => widget.khodamCore.removeCalls(),
          icon: Icon(Icons.delete, color: Colors.white),
        ),
        ActionButton(
          onPressed: _showStatsScreen,
          icon: Icon(Icons.insert_chart, color: Colors.white),
        ),
        ActionButton(
          onPressed: widget.onRouteIconClicked,
          icon: widget.shouldShowRoute
              ? Icon(
                  Icons.visibility_outlined,
                  color: Colors.white,
                )
              : Icon(
                  Icons.visibility_off_outlined,
                  color: Colors.white,
                ),
        ),
      ],
    );
  }

  void _showStatsScreen() {
    Navigator.push(
      widget.khodamCore.getContext()!,
      MaterialPageRoute(
        builder: (_) => KhodamStatsScreen(widget.khodamCore),
      ),
    );
  }

  Color _getFloatingActionButtonColor(List<KhodamHttpCall> calls, BuildContext context) {
    if (calls.isEmpty) {
      return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.grey;
    }

    // Check for the most severe status among the calls
    for (var call in calls) {
      int status = call.response?.status ?? 0;

      if (status == -1) {
        return Colors.red;
      } else if (status >= 400 && status < 600) {
        return Colors.red;
      } else if (status >= 300 && status < 400) {
        return Colors.orange;
      } else if (status >= 200 && status < 300) {
        continue;
      }
    }

    // If no errors or redirects, use green
    return Colors.green;
  }
}

class GhostFab extends StatelessWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;
  final int count;
  final String? envName;

  const GhostFab({
    Key? key,
    required this.onPressed,
    this.backgroundColor = Colors.blue,
    this.count = 0,
    this.envName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 25, // Set the width to 30 pixels
      height: 45, // Adjust the height proportionally
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        shape: GhostShape(),
        elevation: 0, // No shadow to maintain transparency
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              painter: GhostPainter(
                backgroundColor: backgroundColor.withOpacity(0.4), // More transparent
              ),
              size: Size(double.infinity, double.infinity),
            ),
            // Use Text widget for dynamic counting
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 4), // Add space above the text
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12, // Adjust based on the size of the button
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if(envName != null)
                Text(
                  '$envName',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8, // Adjust based on the size of the button
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GhostShape extends ShapeBorder {
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(0.0);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    double width = rect.width;
    double height = rect.height;

    Path path = Path();
    // Draw the rounded top
    path.moveTo(0, height * 0.5);
    path.arcToPoint(
      Offset(width, height * 0.5),
      radius: Radius.circular(width * 0.5),
      clockwise: true,
    );

    // Zigzag bottom
    path.lineTo(width * 0.85, height);
    path.lineTo(width * 0.65, height * 0.75);
    path.lineTo(width * 0.5, height);
    path.lineTo(width * 0.35, height * 0.75);
    path.lineTo(width * 0.15, height);
    path.lineTo(0, height * 0.5);

    path.close();
    return path;
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => GhostShape();
}

class GhostPainter extends CustomPainter {
  final Color backgroundColor;

  GhostPainter({
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    // Draw the ghost body
    Path path = Path();
    double width = size.width;
    double height = size.height;

    path.moveTo(0, height * 0.5);
    path.arcToPoint(
      Offset(width, height * 0.5),
      radius: Radius.circular(width * 0.5),
      clockwise: true,
    );
    path.lineTo(width * 0.85, height);
    path.lineTo(width * 0.65, height * 0.75);
    path.lineTo(width * 0.5, height);
    path.lineTo(width * 0.35, height * 0.75);
    path.lineTo(width * 0.15, height);
    path.lineTo(0, height * 0.5);
    path.close();

    canvas.drawPath(path, paint);

    // Drawing eyes
    final eyePaint = Paint()..color = Colors.white;
    final eyeRadius = size.width * 0.05;
    final leftEyeCenter = Offset(size.width * 0.35, size.height * 0.3);
    final rightEyeCenter = Offset(size.width * 0.65, size.height * 0.3);

    canvas.drawCircle(leftEyeCenter, eyeRadius, eyePaint);
    canvas.drawCircle(rightEyeCenter, eyeRadius, eyePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
