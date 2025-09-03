import 'package:flutter/material.dart';
import 'package:khodam/core/expandable_fab.dart';
import 'package:khodam/core/khodam_core.dart';
import 'package:khodam/ui/page/khodam_routes_list_screen.dart';

class TrackingRoutePopUp extends StatefulWidget {
  const TrackingRoutePopUp({
    super.key,
    required this.onDeletePressed,
    required this.onStatsPressed,
    this.deleteIcon, required this.khodamCore,
  });
  final VoidCallback onDeletePressed;
  final VoidCallback onStatsPressed;
  final Widget? deleteIcon;
  final KhodamCore khodamCore;

  @override
  State<TrackingRoutePopUp> createState() => _TrackingRoutePopUpState();
}

class _TrackingRoutePopUpState extends State<TrackingRoutePopUp> {
  Offset _offset = Offset.zero;
  final _expandedDistance = 140.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final _size = MediaQuery.of(context).size;
    final _rightSide = _expandedDistance + kToolbarHeight + 40;
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
              child: ExpandableFab(
                distance: 75,
                bigButton: Opacity(
                  opacity: 0.6,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        widget.khodamCore.getContext()!,
                        MaterialPageRoute(
                          builder: (context) => KhodamRoutesScreen(widget.khodamCore),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.navigation_outlined),
                        ],
                      ),
                    ),
                  ),
                ),
                children: [
                  ActionButton(
                    onPressed: widget.onDeletePressed,
                    icon: widget.deleteIcon ?? Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  ActionButton(
                    onPressed: widget.onStatsPressed,
                    icon: Icon(Icons.insert_chart, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
