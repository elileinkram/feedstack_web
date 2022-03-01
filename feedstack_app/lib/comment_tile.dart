// import 'dart:io';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:jasper/constants.dart';
// import 'package:jasper/human.dart';
// import 'package:jasper/profile.dart';
// import 'package:jasper/user_face.dart';
// import 'package:visibility_detector/visibility_detector.dart';
//
// class CommentTile extends StatefulWidget {
//   final String authorUID;
//   final VoidCallback refreshParent;
//   final String username;
//   final String profilePhoto;
//   final String coverPhoto;
//   final int bookmark;
//   final String comment;
//
//   // final int numberOfLikes;
//   // final bool hasLiked;
//
//   CommentTile({
//     @required this.authorUID,
//     @required this.refreshParent,
//     @required this.username,
//     @required this.profilePhoto,
//     @required this.coverPhoto,
//     @required this.bookmark,
//     @required this.comment,
//     // @required this.numberOfLikes,
//     // @required this.hasLiked
//   });
//
//   @override
//   _CommentTileState createState() => _CommentTileState();
// }
//
// class _CommentTileState extends State<CommentTile> {
//   bool get _clientIsAuthor {
//     return widget.authorUID == Human.uid;
//   }
//
//   //
//   // bool _hasLiked;
//   // int _numberOfLikes;
//   List<String> _commentWords;
//
//   String _whenWasThisPosted;
//
//   final UniqueKey _visibilityKey = UniqueKey();
//
//   String _getPostageTime() {
//     final DateTime currentTime = DateTime.now();
//     final DateTime postTime =
//         DateTime.fromMillisecondsSinceEpoch(this.widget.bookmark);
//     final Duration diffDuration = currentTime.difference(postTime);
//     int count;
//     String word;
//     if (_shouldCountInNow(diffDuration)) {
//       count = null;
//     } else if (_shouldCountInSeconds(diffDuration)) {
//       count = diffDuration.inSeconds;
//       word = 'second';
//     } else if (_shouldCountInMinutes(diffDuration)) {
//       count = diffDuration.inMinutes;
//       word = 'minute';
//     } else if (_shouldCountInHours(diffDuration)) {
//       count = diffDuration.inHours;
//       word = 'hour';
//     } else if (_shouldCountInDays(diffDuration)) {
//       count = diffDuration.inDays;
//       word = 'day';
//     } else if (_shouldCountInMonths(diffDuration)) {
//       count = diffDuration.inDays ~/ 30;
//       word = 'month';
//     } else {
//       count = diffDuration.inDays ~/ 365;
//       word = 'year';
//     }
//     if (count == null) {
//       return 'Just now';
//     }
//     return "$count $word${_isPlural(count) ? 's' : ''} ago";
//   }
//
//   bool _isPlural(int count) {
//     return count > 1;
//   }
//
//   bool _shouldCountInNow(Duration duration) {
//     final int durationInSeconds = duration.inSeconds;
//     if (_durationIsZero(durationInSeconds)) {
//       return true;
//     }
//     return false;
//   }
//
//   bool _shouldCountInSeconds(Duration duration) {
//     final int durationInMinutes = duration.inMinutes;
//     if (_durationIsZero(durationInMinutes)) {
//       return true;
//     }
//     return false;
//   }
//
//   bool _shouldCountInMinutes(Duration duration) {
//     final int durationInHours = duration.inHours;
//     if (_durationIsZero(durationInHours)) {
//       return true;
//     }
//     return false;
//   }
//
//   bool _shouldCountInHours(Duration duration) {
//     final int durationInDays = duration.inDays;
//     if (_durationIsZero(durationInDays)) {
//       return true;
//     }
//     return false;
//   }
//
//   bool _shouldCountInDays(Duration duration) {
//     final int durationInMonths = duration.inDays ~/ 60;
//     if (_durationIsZero(durationInMonths)) {
//       return true;
//     }
//     return false;
//   }
//
//   bool _shouldCountInMonths(Duration duration) {
//     final int durationInYears = duration.inDays ~/ 365;
//     if (_durationIsZero(durationInYears)) {
//       return true;
//     }
//     return false;
//   }
//
//   bool _durationIsZero(int duration) {
//     return duration == 0;
//   }
//
//   String get _profilePhoto {
//     if (_clientIsAuthor) {
//       return Human.profilePhoto;
//     }
//     return widget.profilePhoto;
//   }
//
//   String get _username {
//     if (_clientIsAuthor) {
//       return Human.username;
//     }
//     return widget.username;
//   }
//
//   String get _coverPhoto {
//     if (_clientIsAuthor) {
//       return Human.coverPhoto;
//     }
//     return widget.coverPhoto;
//   }
//
//   File get _fProfilePhoto {
//     if (_clientIsAuthor) {
//       return Human.fProfilePhoto;
//     }
//     return null;
//   }
//
//   void _showErrorMsg([String msg]) {
//     showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.all(Radius.circular(10 * 2 / 3))),
//             content: Text(msg ?? kDefaultErrorMsg),
//             actions: [
//               FlatButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//                 child: Text(
//                   'Okay',
//                   style: TextStyle(color: Colors.blueAccent),
//                 ),
//               )
//             ],
//           );
//         }).catchError((error) => print(error));
//   }
//
//   void _navigateToProfilePage() {
//     final bool comesWithUserSnap = _clientIsAuthor;
//     Navigator.of(context)
//         .push(CupertinoPageRoute(builder: (BuildContext context) {
//       return Profile(
//         comesWithUserSnap: comesWithUserSnap,
//         uid: widget.authorUID,
//         initialIndex: 0,
//         reactionSelected: 0,
//         username: _username,
//         profilePhoto: _profilePhoto,
//         coverPhoto: _coverPhoto,
//       );
//     })).then((_) {
//       widget.refreshParent();
//     }).catchError((error) => print(error));
//   }
//
//   // String _getNumberOfLikesTxt() {
//   //   if (_numberOfLikes > 999) {
//   //     return "${(_numberOfLikes / 1000).round()}K";
//   //   }
//   //   if (_numberOfLikes == 0) {
//   //     return "Like";
//   //   }
//   //   return "$_numberOfLikes";
//   // }
//
//   @override
//   void initState() {
//     super.initState();
//     // _numberOfLikes = 0;
//     // _hasLiked = widget.hasLiked;
//     _whenWasThisPosted = _getPostageTime();
//     _commentWords = widget.comment.split(' ');
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return VisibilityDetector(
//       key: _visibilityKey,
//       onVisibilityChanged: (_) => null,
//       child: Padding(
//         padding: EdgeInsets.only(
//             top: kPanelPadding * (1 + 1 / 3),
//             left: kPanelPadding * (1 + 1 / 3),
//             right: kPanelPadding * (1 + 1 / 3),
//             bottom: kPanelPadding * (1 + 1 / 3)),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 GestureDetector(
//                   onTap: _navigateToProfilePage,
//                   child: UserFace(
//                     elevation: 10 / 9,
//                     fProfilePhoto: _fProfilePhoto,
//                     iconSize: kPostFaceRadius * 2 / 3,
//                     profilePhoto: _profilePhoto,
//                     radius: kPostFaceRadius,
//                   ),
//                 ),
//                 SizedBox(width: kPanelPadding * 0.875),
//                 Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       _username,
//                       style: TextStyle(
//                           color: Colors.black87,
//                           fontSize: 14.0,
//                           fontWeight: FontWeight.w400),
//                     ),
//                     Text(
//                       _whenWasThisPosted,
//                       style: TextStyle(
//                           color: Colors.blueGrey[200],
//                           fontSize: 14 * 9 / 10 * 9 / 10,
//                           fontWeight: FontWeight.w400),
//                     )
//                   ],
//                 ),
//               ],
//             ),
//             Padding(
//                 padding: EdgeInsets.only(
//                   left: kPanelPadding / (10 / 3) * (1 + 1 / 3),
//                   right: kPanelPadding / (10 / 3) * (1 + 1 / 3),
//                   top: kPanelPadding * (1 + 1 / 3),
//                 ),
//                 child: Row(
//                   children: [
//                     RichText(
//                       text: TextSpan(
//                           children: List<TextSpan>.generate(
//                               (_commentWords.length), (int index) {
//                         final bool isLast = index == _commentWords.length - 1;
//                         final String word = _commentWords[index].trim();
//                         final String text = !isLast ? word + ' ' : word;
//                         final bool isHashtag = word.isNotEmpty &&
//                             word[0] == '#' &&
//                             word.length > 1;
//                         final bool isUser = word.isNotEmpty &&
//                             word[0] == '@' &&
//                             word.length > 1;
//                         final Color color = isHashtag || isUser
//                             ? Colors.blueAccent
//                             : Colors.black87;
//                         final double fontSize = 20.0 * (0.875);
//                         return TextSpan(
//                           recognizer: TapGestureRecognizer()
//                             ..onTap = () {
//                               if (isHashtag || isUser) {
//                                 _showErrorMsg('Coming soon...');
//                               }
//                             },
//                           text: text,
//                           style: TextStyle(color: color, fontSize: fontSize),
//                         );
//                       })),
//                     ),
//                     // Expanded(child: Container()),
//                     // Row(
//                     //   crossAxisAlignment: CrossAxisAlignment.center,
//                     //   children: [
//                     //     IconButton(
//                     //       icon: Icon(
//                     //         Icons.favorite,
//                     //         color: _hasLiked
//                     //             ? Colors.pinkAccent
//                     //             : Colors.blueGrey[100],
//                     //       ),
//                     //       onPressed: () {
//                     //         _hasLiked = !_hasLiked;
//                     //         if (_hasLiked) {
//                     //           _numberOfLikes++;
//                     //         } else {
//                     //           _numberOfLikes--;
//                     //         }
//                     //         setState(() {});
//                     //       },
//                     //     ),
//                     //     Text(
//                     //       _getNumberOfLikesTxt(),
//                     //       style: TextStyle(
//                     //         color: _hasLiked
//                     //             ? Colors.greenAccent
//                     //             : Colors.blueGrey[100],
//                     //         fontSize: 12.5,
//                     //         fontWeight: FontWeight.w400,
//                     //       ),
//                     //     )
//                     //   ],
//                     // ),
//                   ],
//                 )),
//             SizedBox(height: kPanelPadding * (1 + 1 / 3) / (10 * 2 / 3))
//           ],
//         ),
//       ),
//     );
//   }
// }
