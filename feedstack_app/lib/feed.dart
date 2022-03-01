// import 'package:flutter/material.dart';
// import 'package:jasper/constants.dart';
// import 'package:jasper/digest.dart';
// import 'package:jasper/digest_notifier.dart';
// import 'package:jasper/my_uploads.dart';
// import 'package:jasper/playground.dart';
// import 'package:jasper/waiting_widget.dart';
// import 'banner_icon.dart';
//
// class Feed extends StatefulWidget {
//   final List<Map<String, dynamic>> posts;
//   final List<Map<String, dynamic>> postSnapshots;
//   final TabController tabController;
//   final Future<void> Function() redigest;
//   final bool thereIsNothingLeftInFeed;
//   final VoidCallback updateTownHall;
//   final bool isRefreshing;
//   final FocusNode focusNode;
//   final VoidCallback hideKeypad;
//
//   Feed(
//       {@required this.posts,
//       @required this.postSnapshots,
//       @required this.hideKeypad,
//       @required this.tabController,
//       @required this.redigest,
//       @required this.thereIsNothingLeftInFeed,
//       @required this.updateTownHall,
//       @required this.isRefreshing,
//       @required this.focusNode});
//
//   @override
//   _FeedState createState() => _FeedState();
// }
//
// class _FeedState extends State<Feed> with AutomaticKeepAliveClientMixin {
//   bool _showPosts() {
//     return widget.posts.length + widget.postSnapshots.length > 0;
//   }
//
//   bool _isLoading;
//
//   bool _isOnThisPage() {
//     return widget.tabController.index == 1;
//   }
//
//   void _toggleIsLoading() {
//     _isLoading = !_isLoading;
//     if (mounted) {
//       setState(() {});
//     }
//   }
//
//   bool _shouldUpdate() {
//     return !_isLoading &&
//         _isOnThisPage() &&
//         !widget.thereIsNothingLeftInFeed &&
//         !widget.isRefreshing;
//   }
//
//   Future<void> _onUpdate() async {
//     _toggleIsLoading();
//     await widget.redigest();
//     _toggleIsLoading();
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _isLoading = false;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//     return Stack(
//       children: [
//         DigestNotifier(
//           cutoff: MediaQuery.of(context).size.height,
//           onUpdate: _onUpdate,
//           shouldUpdate: _shouldUpdate,
//           child: SingleChildScrollView(
//             physics: NeverScrollableScrollPhysics(),
//             child: Padding(
//               padding: EdgeInsets.symmetric(horizontal: kPanelPadding),
//               child: Column(
//                 children: [
//                   SizedBox(height: kPanelPadding),
//                   Playground(
//                     fontSize: kTitleFontSize,
//                     hideKeypad: widget.hideKeypad,
//                     focusNode: widget.focusNode,
//                     updateTownHall: () {
//                       if (mounted) {
//                         setState(() {});
//                       }
//                     },
//                     posts: this.widget.posts,
//                   ),
//                   MyUploads(
//                     snapshots: widget.postSnapshots,
//                     shouldLoadMorePosts: _shouldUpdate,
//                     loadMorePosts: _onUpdate,
//                     refreshParent: widget.updateTownHall,
//                     posts: widget.posts,
//                   ),
//                   // Digest(
//                   //   uploads: widget.posts,
//                   //   shouldLoadMorePosts: _shouldUpdate,
//                   //   loadMorePosts: _onUpdate,
//                   //   isInsideComments: false,
//                   //   shouldIncludeHero: true,
//                   //   refreshParent: widget.updateTownHall,
//                   //   postSnapshots: widget.postSnapshots,
//                   // ),
//                   // SizedBox(
//                   //   height: kDefaultLoadingHeight,
//                   //   child: Align(
//                   //     alignment: Alignment.center,
//                   //     child: WaitingWidget(
//                   //       color: Colors.blueAccent,
//                   //       isLoading: _isLoading,
//                   //     ),
//                   //   ),
//                   // )
//                 ],
//               ),
//             ),
//           ),
//         ),
//         !_showPosts()
//             ? Center(
//                 child: BannerIcon(
//                 emoticon: 'ʕ•ᴥ•ʔ',
//                 msg: 'Post to start your feed ^',
//               ))
//             : Container()
//       ],
//     );
//   }
//
//   @override
//   bool get wantKeepAlive => true;
// }

