import 'package:flutter/material.dart';
import 'package:jasper/constants.dart';

class ReactionPanel extends StatefulWidget {
  final double panelHeight;
  final double fontSize;
  final Color backgroundColor;
  final double radius;
  final double elevation;
  final int reactionSelected;
  final Function(int reactionSelected) onActionChanged;
  final double unselectedOpacity;
  final List<String> emojis;

  ReactionPanel(
      {@required this.panelHeight,
      @required this.fontSize,
      @required this.backgroundColor,
      @required this.radius,
      @required this.elevation,
      @required this.reactionSelected,
      @required this.onActionChanged,
      @required this.unselectedOpacity,
      @required this.emojis});

  _ReactionPanelState createState() => _ReactionPanelState();
}

class _ReactionPanelState extends State<ReactionPanel>
    with AutomaticKeepAliveClientMixin {
  bool _isCurrentIndex(int index) {
    return widget.reactionSelected == index;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SizedBox(
        height: widget.panelHeight,
        child: Material(
          color: widget.backgroundColor,
          elevation: widget.elevation,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
                widget.emojis.length - 3,
                (index) => IconButton(
                      onPressed: () {
                        widget.onActionChanged(index);
                      },
                      icon: Text(
                        widget.emojis[index] ?? kEmojis[index],
                        style: TextStyle(
                            fontSize: widget.fontSize,
                            color: Colors.blueAccent.withOpacity(
                                _isCurrentIndex(index)
                                    ? 1.0
                                    : widget.unselectedOpacity)),
                      ),
                    )),
          ),
        ));
  }

  @override
  bool get wantKeepAlive => true;
}


