// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:jasper/comment_section.dart';
// import 'constants.dart';
//
// class PostPages extends StatefulWidget {
//   final List<Map<String, dynamic>> uploads;
//   final List<Map<String, dynamic>> snapshots;
//   final int initialPage;
//   final Future<void> Function() loadMorePosts;
//   final bool Function() shouldLoadMorePosts;
//   final bool isUpload;
//
//   PostPages(
//       {@required this.uploads,
//       @required this.snapshots,
//       @required this.initialPage,
//       @required this.loadMorePosts,
//       @required this.shouldLoadMorePosts,
//       @required this.isUpload});
//
//   @override
//   _PostPagesState createState() => _PostPagesState();
// }
//
// class _PostPagesState extends State<PostPages> {
//   PageController _pageController;
//   bool _isPopping;
//   bool _isLoading;
//   int _initialPage;
//
//   Future<bool> _onBack() async {
//     if (_isPopping) {
//       return false;
//     }
//     _pageController.jumpToPage(_initialPage);
//     _isPopping = true;
//     setState(() {});
//     Navigator.of(context).pop();
//     _isPopping = false;
//     return _isPopping;
//   }
//
//   void _refreshParent() {
//     if (mounted) {
//       setState(() {});
//     }
//   }
//
//   void _toggleIsLoading() {
//     _isLoading = !_isLoading;
//     if (mounted) {
//       setState(() {});
//     }
//   }
//
//   int get _itemCount {
//     if (_isPopping) {
//       return 1;
//     }
//     return widget.uploads.length + widget.snapshots.length;
//   }
//
//   void _pageListener() async {
//     if (_isPopping) {
//       return;
//     }
//     _hideKeypad();
//     if (_pageController.page >= _itemCount - kDefaultPostLimit) {
//       if (_isLoading) {
//         return;
//       }
//       if (widget.shouldLoadMorePosts()) {
//         _toggleIsLoading();
//         await widget.loadMorePosts();
//         _toggleIsLoading();
//       }
//     }
//   }
//
//   void _hideKeypad() {
//     WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _isPopping = false;
//     _isLoading = false;
//     _initialPage = widget.isUpload
//         ? widget.initialPage
//         : widget.uploads.length + widget.initialPage;
//     _pageController = PageController(initialPage: _initialPage);
//     _pageController.addListener(_pageListener);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: _onBack,
//       child: GestureDetector(
//         onTap: _hideKeypad,
//         child: Scaffold(
//           appBar: AppBar(
//             automaticallyImplyLeading: false,
//             backgroundColor: Colors.blueAccent,
//             elevation: 0.0,
//             title: Row(
//               children: [
//                 IconButton(
//                   icon: Icon(
//                     Icons.arrow_back,
//                     color: Colors.white,
//                   ),
//                   onPressed: _onBack,
//                 ),
//                 Text(
//                   'Comments',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: kTitleFontSize,
//                   ),
//                 )
//               ],
//             ),
//           ),
//           backgroundColor: Color(kDefaultBackgroundColor),
//           body: PageView.builder(
//               controller: _pageController,
//               itemCount: _itemCount,
//               itemBuilder: (BuildContext context, int index) {
//                 if (_isPopping) {
//                   index = _initialPage;
//                 }
//                 final bool shouldIncludeHero = index == _initialPage;
//                 String postID;
//                 List<Map<String, dynamic>> snapshots;
//                 if (index < widget.uploads.length) {
//                   postID = widget.uploads[index]['postID'];
//                   snapshots = widget.uploads;
//                 } else {
//                   index = index - widget.uploads.length;
//                   postID = widget.snapshots[index]['postID'];
//                   snapshots = widget.snapshots;
//                 }
//                 return CommentSection(
//                   hideKeypad: _hideKeypad,
//                   snapshots: snapshots,
//                   index: index,
//                   refreshParent: _refreshParent,
//                   shouldIncludeHero: shouldIncludeHero,
//                   postID: postID,
//                 );
//               }),
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     _pageController?.dispose();
//   }
// }
