import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:khodam/core/khodam_core.dart';
import 'package:khodam/helper/khodam_save_helper.dart';
import 'package:khodam/model/khodam_http_call.dart';
import 'package:khodam/ui/utils/khodam_constants.dart';
import 'package:khodam/ui/widget/khodam_call_error_widget.dart';
import 'package:khodam/ui/widget/khodam_call_overview_widget.dart';
import 'package:khodam/ui/widget/khodam_call_request_widget.dart';
import 'package:khodam/ui/widget/khodam_call_response_widget.dart';
// import 'package:share_plus/share_plus.dart';

class KhodamCallDetailsScreen extends StatefulWidget {
  final KhodamHttpCall call;
  final KhodamCore core;

  KhodamCallDetailsScreen(this.call, this.core);

  @override
  _KhodamCallDetailsScreenState createState() => _KhodamCallDetailsScreenState();
}

class _KhodamCallDetailsScreenState extends State<KhodamCallDetailsScreen> with SingleTickerProviderStateMixin {
  KhodamHttpCall get call => widget.call;
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<bool> _isSearching = ValueNotifier(false);
  final ValueNotifier<int> _totalMatches = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _isSearching.dispose();
    _totalMatches.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // No need to call setState, the widgets will rebuild automatically
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: widget.core.brightness,
        primarySwatch: Colors.green,
      ),
      child: StreamBuilder<List<KhodamHttpCall>>(
        stream: widget.core.callsSubject,
        initialData: [widget.call],
        builder: (context, callsSnapshot) {
          if (callsSnapshot.hasData) {
            KhodamHttpCall? call =
                callsSnapshot.data?.firstWhere((snapshotCall) => snapshotCall.id == widget.call.id, orElse: null);
            if (call != null) {
              return _buildMainWidget();
            } else {
              return _buildErrorWidget();
            }
          } else {
            return _buildErrorWidget();
          }
        },
      ),
    );
  }

  Widget _buildMainWidget() {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: KhodamConstants.lightRed,
          key: Key('share_key'),
          onPressed: () async {
            // Share.share(await _getSharableResponseString(),
            //     subject: 'Request Details');
            await Clipboard.setData(ClipboardData(text: await _getSharableResponseString()));
          },
          child: Icon(Icons.share),
        ),
        appBar: AppBar(
          bottom: TabBar(
            indicatorColor: KhodamConstants.lightRed,
            tabs: _getTabBars(),
          ),
          title: ValueListenableBuilder<bool>(
              valueListenable: _isSearching,
              builder: (context, onSearch, child) {
                return onSearch ? _buildSearchField() : Text('Khodam - HTTP Call Details');
              }),
          actions: [
            ValueListenableBuilder<bool>(
              valueListenable: _isSearching,
              builder: (context, isSearching, child) {
                return IconButton(
                  icon: Icon(isSearching ? Icons.close : Icons.search),
                  onPressed: () {
                    _isSearching.value = !isSearching;
                    if (!isSearching) {
                      _searchController.clear();
                    }
                  },
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          children: _getTabBarViewList(),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(child: Text("Failed to load data"));
  }

  Future<String> _getSharableResponseString() async {
    return KhodamSaveHelper.buildCallLog(widget.call);
  }

  List<Widget> _getTabBars() {
    List<Widget> widgets = [];
    widgets.add(Tab(icon: Icon(Icons.info_outline), text: "Overview"));
    widgets.add(Tab(icon: Icon(Icons.arrow_upward), text: "Request"));
    widgets.add(Tab(icon: Icon(Icons.arrow_downward), text: "Response"));
    widgets.add(
      Tab(
        icon: Icon(Icons.warning),
        text: "Error",
      ),
    );
    return widgets;
  }

  List<Widget> _getTabBarViewList() {
    return [
      KhodamCallOverviewWidget(widget.call),
      KhodamCallRequestWidget(widget.call, searchQuery: _searchController.text, matchesNotifier: _totalMatches),
      KhodamCallResponseWidget(widget.call, searchQuery: _searchController.text, matchesNotifier: _totalMatches),
      KhodamCallErrorWidget(widget.call),
    ];
  }

  Widget _buildSearchField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: "Search http request...",
              hintStyle: TextStyle(
                fontSize: 16.0,
                color: Colors.grey,
              ),
              // border: InputBorder,
            ),
            style: TextStyle(fontSize: 16.0, color: Colors.black),
            cursorColor: Colors.blue,
          ),
        ),
        ValueListenableBuilder<int>(
          valueListenable: _totalMatches,
          builder: (context, totalMatches, child) {
            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                'Matches: $totalMatches',
                style: TextStyle(color: Colors.black),
              ),
            );
          },
        ),
      ],
    );
  }

  int _getTotalMatches() {
    // This would need to be implemented to get matches from all tabs
    // You might need to use a ValueNotifier or similar to track matches across widgets
    return 0; // Placeholder
  }
}
