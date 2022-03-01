import 'package:flutter/material.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart'
    as ext;
import 'package:jasper/search_field.dart';
import 'package:jasper/spotlight.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  final List<String> _tabs = ['Users', 'Feeds'];
  TabController _tabController;
  final TextEditingController _textEditingController = TextEditingController();

  Future<bool> _onWillPop() async {
    if (_tabController.index == 1 || _tabController.indexIsChanging) {
      _tabController.animateTo(0, duration: Duration(milliseconds: 1000 ~/ 3));
      return false;
    }
    return true;
  }

  final List<UniqueKey> _keys = [UniqueKey(), UniqueKey()];
  bool _isEmpty;

  void _onBack() {
    Navigator.of(context).pop();
  }


  @override
  void initState() {
    super.initState();
    _isEmpty = true;
    _tabController = TabController(vsync: this, length: _tabs.length);
    _textEditingController.addListener(() {
      if (_textEditingController.text.trim().isEmpty) {
        if (!_isEmpty) {
          _isEmpty = true;
          if (mounted) {
            setState(() {});
          }
        }
      } else {
        if (_isEmpty) {
          _isEmpty = false;
          if (mounted) {
            setState(() {});
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: ext.NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverAppBar(
                elevation: 0.0,
                automaticallyImplyLeading: false,
                backgroundColor: Colors.blueAccent,
                forceElevated: innerBoxIsScrolled,
                pinned: true,
                floating: true,
                title: SearchField(
                    autofocus: true,
                    hintText: 'Search...',
                    onBack: _onBack,
                    textEditingController: _textEditingController,
                    isEmpty: _isEmpty),
                bottom: TabBar(
                  controller: _tabController,
                  tabs: List<Widget>.generate(_tabs.length, (int index) {
                    return Tab(
                      text: _tabs[index],
                    );
                  }),
                  indicatorColor: Colors.blueGrey[50],
                ),
              )
            ];
          },
          body: Material(
            color: Colors.white,
            child: TabBarView(
              controller: _tabController,
              children: [
                Spotlight(
                    key: _keys.first,
                    isUserSearch: true,
                    textEditingController: _textEditingController),
                Spotlight(
                    key: _keys.last,
                    isUserSearch: false,
                    textEditingController: _textEditingController),
              ],
            ),
          )),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _textEditingController.dispose();
    _tabController?.dispose();
  }
}
