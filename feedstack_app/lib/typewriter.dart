// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:jasper/constants.dart';
// import 'package:jasper/human.dart';
//
// class Typewriter extends StatefulWidget {
//   final String postID;
//   final List<Map<String, dynamic>> commentSnaps;
//   final VoidCallback refreshParent;
//   final List<Map<String, dynamic>> snapshots;
//   final int index;
//
//   Typewriter(
//       {@required this.postID,
//       @required this.commentSnaps,
//       @required this.refreshParent,
//       @required this.snapshots,
//       @required this.index});
//
//   @override
//   _TypewriterState createState() => _TypewriterState();
// }
//
// class _TypewriterState extends State<Typewriter>
//     with AutomaticKeepAliveClientMixin {
//   final TextEditingController _textEditingController = TextEditingController();
//   final FocusNode _focusNode = FocusNode();
//   bool _isEmpty;
//
//   void _reset() {
//     _isEmpty = true;
//     _textEditingController.clear();
//     setState(() {});
//   }
//
//   Map<String, dynamic> _getUserCommentData(
//       String comment, String postCommentID, String postID, int bookmark) {
//     return {
//       'postCommentID': postCommentID,
//       'postID': postID,
//        'authorUID' : // the author of the post
//       'ranking': 0,
//       'comment': comment,
//       'bookmark': bookmark
//     };
//   }
//
//   Map<String, dynamic> _getPostCommentData(
//       String comment, String userCommentID, int bookmark) {
//     return {
//       'profilePhoto': Human.profilePhoto,
//       'coverPhoto': Human.coverPhoto,
//       'username': Human.username,
//       'authorUID': Human.uid,
//       'comment': comment,
//       'userCommentID': userCommentID,
//       'bookmark': bookmark,
//       'ranking': 0,
//     };
//   }
//
//   void _pushToBase(String comment, int bookmark,
//       DocumentReference userCommentRef, DocumentReference postCommentRef) {
//     final WriteBatch batch = FirebaseFirestore.instance.batch();
//     batch.set(
//         userCommentRef,
//         _getUserCommentData(
//             comment, postCommentRef.id, widget.postID, bookmark));
//     batch.set(postCommentRef,
//         _getPostCommentData(comment, userCommentRef.id, bookmark));
//     batch.commit().catchError((error) => print(error));
//   }
//
//   void _uploadComment() {
//     final String comment = _textEditingController.text.trim();
//     final int bookmark = DateTime.now().millisecondsSinceEpoch;
//     _reset();
//     final DocumentReference userCommentRef = FirebaseFirestore.instance
//         .collection('users')
//         .doc(Human.uid)
//         .collection('comments')
//         .doc();
//     final DocumentReference postCommentRef = FirebaseFirestore.instance
//         .collection('posts')
//         .doc(widget.postID)
//         .collection('comments')
//         .doc();
//     _pushToBase(comment, bookmark, userCommentRef, postCommentRef);
//     widget.commentSnaps.insert(
//         0,
//         (_getSnapshotFromComment(
//             comment, bookmark, userCommentRef, postCommentRef)));
//     widget.snapshots[widget.index]['numberOfComments'] =
//         widget.snapshots[widget.index]['numberOfComments'] + 1;
//     _focusNode.unfocus();
//     widget.refreshParent();
//   }
//
//   Map<String, dynamic> _getSnapshotFromComment(String comment, int bookmark,
//       DocumentReference userCommentRef, DocumentReference postCommentRef) {
//     final Map<String, dynamic> commentData = Map<String, dynamic>();
//     commentData['authorUID'] = Human.uid;
//     commentData['bookmark'] = bookmark;
//     commentData['comment'] = comment;
//     commentData['ranking'] = 0;
//     commentData['username'] = Human.username;
//     commentData['profilePhoto'] = Human.profilePhoto;
//     commentData['coverPhoto'] = Human.coverPhoto;
//     commentData['commentID'] = postCommentRef.id;
//     commentData['userCommentID'] = userCommentRef.id;
//     commentData['key'] = UniqueKey();
//     return commentData;
//   }
//
//   void _onChanged(String txt) {
//     final bool isEmpty = txt.trim().isEmpty;
//     if (isEmpty != _isEmpty) {
//       _isEmpty = isEmpty;
//       setState(() {});
//     }
//   }
//
//   String _getHintText() {
//     if (widget.snapshots[widget.index]['numberOfComments'] == 0) {
//       return 'Start the conversation';
//     }
//     return 'Add a comment';
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _isEmpty = true;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//     return TextField(
//       maxLines: 1,
//       focusNode: _focusNode,
//       onChanged: _onChanged,
//       controller: _textEditingController,
//       textCapitalization: TextCapitalization.sentences,
//       buildCounter: (BuildContext context,
//               {int currentLength, int maxLength, bool isFocused}) =>
//           null,
//       maxLength: kCommentMaxLength,
//       decoration: InputDecoration(
//           hintText: _getHintText(),
//           suffixIcon: IconButton(
//             onPressed: _isEmpty ? null : _uploadComment,
//             icon: Icon(
//               Icons.send,
//               color: _isEmpty ? Colors.transparent : Colors.blue,
//             ),
//           )),
//     );
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     _textEditingController.dispose();
//     _focusNode.dispose();
//   }
//
//   @override
//   bool get wantKeepAlive => true;
// }
