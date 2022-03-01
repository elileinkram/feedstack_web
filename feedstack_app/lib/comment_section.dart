// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:jasper/comment_tile.dart';
// import 'package:jasper/comment_tile_shimmer.dart';
// import 'package:jasper/typewriter.dart';
// import 'constants.dart';
// import 'digest.dart';
// import 'human.dart';
//
// class CommentSection extends StatefulWidget {
//   final String postID;
//   final bool shouldIncludeHero;
//   final VoidCallback refreshParent;
//   final List<Map<String, dynamic>> snapshots;
//   final int index;
//   final VoidCallback hideKeypad;
//
//   CommentSection(
//       {@required this.postID,
//       @required this.shouldIncludeHero,
//       @required this.refreshParent,
//       @required this.snapshots,
//       @required this.index,
//       @required this.hideKeypad});
//
//   @override
//   _CommentSectionState createState() => _CommentSectionState();
// }
//
// class _CommentSectionState extends State<CommentSection> {
//   bool _isRefreshing;
//   bool _thereAreNoMoreCommentsLeft;
//   final ScrollController _scrollController = ScrollController();
//   final Set<String> _commentIDs = Set<String>();
//   final List<Map<String, dynamic>> _commentSnaps = List<Map<String, dynamic>>();
//
//   // final Set<String> _upvoteIDs = Set<String>();
//   bool _isLoading;
//
//   void _bootUp() async {
//     final QuerySnapshot qs =
//         await _getQuery(widget.postID, kDefaultCommentLimit);
//     // final Set<String> upvotes = await _getUpvotes(qs);
//     _populateComments(
//         qs,
//         // upvotes,
//         kDefaultCommentLimit);
//     if (mounted) {
//       setState(() {});
//     }
//   }
//
//   // Future<Set<String>> _getUpvotes(QuerySnapshot qs) async {
//   //   final Set<String> upvotes = Set<String>();
//   //   if (qs == null) {
//   //     return upvotes;
//   //   }
//   //   for (int i = 0; i < qs.docs.length; i++) {
//   //     final String docID = qs.docs[i].id;
//   //     if (_upvoteIDs.contains(docID)) {
//   //       continue;
//   //     }
//   //     _upvoteIDs.add(docID);
//   //     final DocumentSnapshot snapshot = await FirebaseFirestore.instance
//   //         .collection('posts')
//   //         .doc(widget.postID)
//   //         .collection('comments')
//   //         .doc(docID)
//   //         .collection('upvotes')
//   //         .doc(Human.uid)
//   //         .get()
//   //         .catchError((error) => print(error));
//   //     if (snapshot != null && snapshot.exists) {
//   //       upvotes.add(snapshot.id);
//   //     }
//   //   }
//   //   return upvotes;
//   // }
//
//   void _populateComments(
//       QuerySnapshot qs,
//       // Set<String> upvotes,
//       int limit) {
//     if (qs == null) {
//       return;
//     }
//     if (qs.docs.length < limit) {
//       _thereAreNoMoreCommentsLeft = true;
//     } else {
//       _thereAreNoMoreCommentsLeft = false;
//     }
//     for (int i = 0; i < qs.docs.length; i++) {
//       final DocumentSnapshot snapshot = qs.docs[i];
//       if (_commentIDs.contains(snapshot.id)) {
//         continue;
//       }
//       _commentIDs.add(snapshot.id);
//       _commentSnaps.add(_getCommentFromSnap(snapshot
//           // ,
//           // upvotes
//           ));
//     }
//   }
//
//   Map<String, dynamic> _getCommentFromSnap(DocumentSnapshot ds
//       // , Set<String> upvotes
//       ) {
//     final Map<String, dynamic> comment = Map<String, dynamic>();
//     final Map<String, dynamic> data = ds.data();
//     comment['authorUID'] = data['authorUID'];
//     comment['bookmark'] = data['bookmark'];
//     comment['comment'] = data['comment'];
//     comment['username'] = data['username'];
//     comment['profilePhoto'] = data['profilePhoto'];
//     comment['coverPhoto'] = data['coverPhoto'];
//     comment['commentID'] = ds.id;
//     comment['userCommentID'] = data['userCommentID'];
//     // comment['ranking'] = data['ranking'];
//     comment['key'] = UniqueKey();
//     // if (upvotes.contains(ds.id)) {
//     //   comment['hasLiked'] = true;
//     // } else {
//     //   comment['hasLiked'] = false;
//     // }
//     return comment;
//   }
//
//   Map<String, dynamic> _getPostFromSnap(DocumentSnapshot ds) {
//     final Map<String, dynamic> post = Map<String, dynamic>();
//     final Map<String, dynamic> data = ds.data();
//     post['seen'] = data['seen'];
//     post['reactionSelected'] = data['reactionSelected'] ?? kNullActionValue;
//     post['authorUID'] = data['authorUID'];
//     post['coverPhoto'] = data['coverPhoto'];
//     post['bookmark'] = data['bookmark'];
//     post['caption'] = data['caption'];
//     post['username'] = data['username'];
//     post['image'] = data['image'];
//     post['profilePhoto'] = data['profilePhoto'];
//     post['postID'] = ds.id;
//     post['numberOfComments'] = data['numberOfComments'];
//     post['key'] = UniqueKey();
//     return post;
//   }
//
//   Future<void> _onRefresh() async {
//     _isRefreshing = true;
//     setState(() {});
//     final DocumentSnapshot ds = await _getSnap(widget.postID);
//     final QuerySnapshot qs =
//         await _getQuery(widget.postID, kDefaultCommentLimit);
//     if (ds != null) {
//       widget.snapshots[widget.index] = _getPostFromSnap(ds);
//     }
//     if (qs != null) {
//       _reset();
//     }
//     // final Set<String> upvotes = await _getUpvotes(qs);
//     _populateComments(
//         qs,
//         // upvotes,
//         kDefaultCommentLimit);
//     _isRefreshing = false;
//     if (mounted) {
//       setState(() {});
//     }
//   }
//
//   void _reset() {
//     _commentSnaps.clear();
//     _commentIDs.clear();
//     // _upvoteIDs.clear();
//   }
//
//   Future<DocumentSnapshot> _getSnap(String postID) {
//     return FirebaseFirestore.instance
//         .collection('users')
//         .doc(Human.uid)
//         .collection('home')
//         .doc(postID)
//         .get()
//         .catchError((error) => print(error));
//   }
//
//   Future<QuerySnapshot> _getQuery(String postID, int limit) {
//     return FirebaseFirestore.instance
//         .collection('posts')
//         .doc(postID)
//         .collection('comments')
//         .orderBy('bookmark', descending: true)
//         .where('bookmark',
//             isLessThan: _commentSnaps.isEmpty || _isRefreshing
//                 ? DateTime.now().millisecondsSinceEpoch
//                 : _commentSnaps.last['bookmark'])
//         .limit(limit)
//         .get()
//         .catchError((error) => print(error));
//   }
//
//   bool _hasChangedSinceUpdate(int preLength, int postLength) {
//     return preLength != postLength;
//   }
//
//   void _toggleLoading() {
//     _isLoading = !_isLoading;
//     if (mounted) {
//       setState(() {});
//     }
//   }
//
//   void _scrollListener() async {
//     if (_scrollController.offset >=
//         _scrollController.position.maxScrollExtent -
//             MediaQuery.of(context).size.height) {
//       if (!_isRefreshing && !_isLoading && !_thereAreNoMoreCommentsLeft) {
//         _toggleLoading();
//         final int preLength = _commentSnaps.length;
//         // final int limit = kDefaultCommentLimit + _commentSnaps.length;
//         final QuerySnapshot qs =
//             await _getQuery(widget.postID, kDefaultCommentLimit);
//         // final Set<String> upvotes = await _getUpvotes(qs);
//         final int postLength = _commentSnaps.length;
//         if (_hasChangedSinceUpdate(preLength, postLength)) {
//           _toggleLoading();
//         } else {
//           _populateComments(
//               qs
//               // , upvotes
//               ,
//               kDefaultCommentLimit);
//           _toggleLoading();
//         }
//       }
//     }
//   }
//
//   int _getNumberOfComments() {
//     return widget.snapshots[widget.index]['numberOfComments'];
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _isLoading = false;
//     _scrollController.addListener(_scrollListener);
//     _isRefreshing = false;
//     _thereAreNoMoreCommentsLeft = true;
//     _bootUp();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return RefreshIndicator(
//         backgroundColor: Colors.white,
//         color: Colors.blueAccent,
//         notificationPredicate: (ScrollNotification n) {
//           if (_isRefreshing) {
//             return false;
//           }
//           return true;
//         },
//         onRefresh: _onRefresh,
//         child: ListView(
//           controller: _scrollController,
//           children: [
//             ConstrainedBox(
//               constraints: BoxConstraints(
//                 minHeight: MediaQuery.of(context).size.height,
//               ),
//               child: Column(
//                 children: [
//                   Padding(
//                     padding: EdgeInsets.symmetric(horizontal: kPanelPadding),
//                     child: Digest(
//                       shouldLoadMorePosts: () => false,
//                       loadMorePosts: () async => null,
//                       shouldIncludeHero: widget.shouldIncludeHero,
//                       isInsideComments: true,
//                       postSnapshots: [widget.snapshots[widget.index]],
//                       refreshParent: widget.refreshParent,
//                     ),
//                   ),
//                   SizedBox(height: kPanelPadding * (1.875)),
//                   Padding(
//                       padding:
//                           EdgeInsets.symmetric(horizontal: kPanelPadding * 2),
//                       child: Typewriter(
//                         snapshots: widget.snapshots,
//                         index: widget.index,
//                         commentSnaps: _commentSnaps,
//                         postID: widget.postID,
//                         refreshParent: widget.refreshParent,
//                       )),
//                   Padding(
//                     padding: EdgeInsets.symmetric(horizontal: kPanelPadding),
//                     child: Padding(
//                       padding: EdgeInsets.only(bottom: kPanelPadding),
//                       child: Column(
//                         children: List<Widget>.generate(_getNumberOfComments(),
//                             (int index) {
//                           final int maxCommentIndex = _commentSnaps.length - 1;
//                           if (index > maxCommentIndex) {
//                             return Column(
//                               children: [
//                                 SizedBox(height: kPanelPadding),
//                                 ClipRRect(
//                                   borderRadius: BorderRadius.all(
//                                       Radius.circular(kPanelPadding)),
//                                   child: Material(
//                                       color: Colors.white,
//                                       child: CommentTileShimmer()),
//                                 ),
//                               ],
//                             );
//                           }
//                           final Map<String, dynamic> commentData =
//                               _commentSnaps[index];
//                           final String comment = commentData['comment'];
//                           final String username = commentData['username'];
//                           final String authorUID = commentData['authorUID'];
//                           final UniqueKey key = commentData['key'];
//                           final int bookmark = commentData['bookmark'];
//                           final String coverPhoto = commentData['coverPhoto'];
//                           final String profilePhoto =
//                               commentData['profilePhoto'];
//                           // final int numberOfLikes = commentData['ranking'];
//                           // final bool hasLiked = commentData['hasLiked'];
//                           return Column(
//                             key: key,
//                             children: [
//                               SizedBox(height: kPanelPadding),
//                               ClipRRect(
//                                 borderRadius: BorderRadius.all(
//                                     Radius.circular(kPanelPadding)),
//                                 child: Material(
//                                   color: Colors.white,
//                                   child: CommentTile(
//                                     // hasLiked: hasLiked,
//                                     // numberOfLikes: numberOfLikes,
//                                     comment: comment,
//                                     username: username,
//                                     refreshParent: widget.refreshParent,
//                                     authorUID: authorUID,
//                                     bookmark: bookmark,
//                                     coverPhoto: coverPhoto,
//                                     profilePhoto: profilePhoto,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           );
//                         }),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ));
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     _scrollController.dispose();
//   }
// }
