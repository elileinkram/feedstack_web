// import 'package:flutter/material.dart';
// import 'package:shimmer/shimmer.dart';
// import 'constants.dart';
//
// class CommentTileShimmer extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.all(
//         kPanelPadding * (1 + 1 / 3),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           IntrinsicHeight(
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Material(
//                   shape: CircleBorder(),
//                   elevation: 10 / 9,
//                   child: Shimmer.fromColors(
//                       baseColor: Colors.grey[300],
//                       highlightColor: Colors.grey[100],
//                       child: CircleAvatar(
//                         backgroundColor: Colors.white,
//                         radius: kPostFaceRadius,
//                       )),
//                 ),
//                 SizedBox(width: kPanelPadding * 0.875),
//                 Column(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     SizedBox(height: 9),
//                     Shimmer.fromColors(
//                       baseColor: Colors.grey[200],
//                       highlightColor: Colors.grey[50],
//                       child: SizedBox(
//                         height: 14.0 * 9 / 10 * 9 / 10,
//                         width: 100 * 2 / (3 * 2 / 3),
//                         child: Material(
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                     Expanded(child: Container()),
//                     Shimmer.fromColors(
//                       baseColor: Colors.grey[200],
//                       highlightColor: Colors.grey[50],
//                       child: SizedBox(
//                         height: 14.0 * 9 / 10 * 9 / 10,
//                         width: 100 * 2 / 3,
//                         child: Material(
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 9),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: kPanelPadding * (1 + 1 / 9)),
//           Padding(
//               padding: EdgeInsets.symmetric(
//                 horizontal: kPanelPadding / (10 / 3),
//               ),
//               child: Shimmer.fromColors(
//                 baseColor: Colors.grey[200],
//                 highlightColor: Colors.grey[50],
//                 child: SizedBox(
//                   height: 20 * 0.875,
//                   width: double.infinity,
//                   child: Material(color: Colors.white),
//                 ),
//               )),
//           // SizedBox(height: kPanelPadding * (1 + 1 / 9) * 1 / 3),
//           // Padding(
//           //     padding:
//           //         EdgeInsets.symmetric(horizontal: kPanelPadding / (10 / 3)),
//           //     child: Shimmer.fromColors(
//           //       baseColor: Colors.grey[100],
//           //       highlightColor: Colors.grey[50],
//           //       child: SizedBox(
//           //           width: kPanelPadding * 3,
//           //           height: 12.0,
//           //           child: Material(color: Colors.white)),
//           //     )),
//         ],
//       ),
//     );
//   }
// }
