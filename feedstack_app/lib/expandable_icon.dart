// import 'package:flutter/material.dart';
// import 'dart:math' as math;
//
// import 'package:icon_shadow/icon_shadow.dart';
//
// class ExpandableIcon extends StatefulWidget {
//   final IconData collapseIcon;
//   final IconData expandIcon;
//   final double iconSize;
//   final Color iconColor;
//   final VoidCallback togglePanel;
//   final Animation animation;
//   final AnimationController animationController;
//   final Color shadowColor;
//
//   ExpandableIcon(
//       {@required this.collapseIcon,
//       @required this.expandIcon,
//       @required this.iconSize,
//       @required this.iconColor,
//       @required this.togglePanel,
//       @required this.animation,
//       @required this.animationController,
//       @required this.shadowColor});
//
//   @override
//   _ExpandableIconState createState() => _ExpandableIconState();
// }
//
// class _ExpandableIconState extends State<ExpandableIcon> {
//   @override
//   Widget build(BuildContext context) {
//     return FloatingActionButton(
//       heroTag: 'exp',
//       mini: true,
//       backgroundColor: Colors.transparent,
//       highlightElevation: 0.0,
//       elevation: 0.0,
//       onPressed: widget.togglePanel,
//       child: AnimatedBuilder(
//         animation: widget.animation,
//         builder: (context, child) {
//           final showSecondIcon = widget.animationController.value >= 0.5;
//           return Transform.rotate(
//               angle: -math.pi *
//                   (showSecondIcon
//                       ? -(1.0 - widget.animationController.value)
//                       : widget.animationController.value),
//               child: IconShadowWidget(
//                 showSecondIcon
//                     ? Icon(
//                         widget.collapseIcon,
//                         color: widget.iconColor,
//                         size: widget.iconSize,
//                       )
//                     : Icon(
//                         widget.expandIcon,
//                         color: widget.iconColor,
//                         size: widget.iconSize,
//                       ),
//                 shadowColor: widget.shadowColor,
//               ));
//         },
//       ),
//     );
//   }
// }
