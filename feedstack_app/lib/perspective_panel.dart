import 'package:flutter/material.dart';
import 'package:jasper/constants.dart';

class PerspectivePanel extends StatefulWidget {
  final double panelHeight;
  final double fontSize;
  final Color backgroundColor;
  final double radius;
  final double elevation;
  final int reactionSelected;
  final Function(int reactionSelected) onActionChanged;
  final double unselectedOpacity;
  final List<String> emojis;
  final String username;

  PerspectivePanel(
      {@required this.panelHeight,
      @required this.fontSize,
      @required this.backgroundColor,
      @required this.radius,
      @required this.elevation,
      @required this.reactionSelected,
      @required this.onActionChanged,
      @required this.unselectedOpacity,
      @required this.emojis,
      @required this.username});

  _PerspectivePanelState createState() => _PerspectivePanelState();
}

class _PerspectivePanelState extends State<PerspectivePanel>
    with AutomaticKeepAliveClientMixin {
  bool _isCurrentIndex(int index) {
    return widget.reactionSelected == index;
  }

  void _showErrorMsg(String username) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10 * 2 / 3))),
            content: RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: '$username ',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: kTitleFontSize,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: 'has never used this emoji.',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: kTitleFontSize,
                  ),
                ),
              ]),
            ),
            actions: [
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Okay',
                  style: TextStyle(color: Colors.blueAccent),
                ),
              )
            ],
          );
        }).catchError((error) => print(error));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SizedBox(
      height: widget.panelHeight,
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(
              widget.emojis.length - 3,
              (index) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: index == widget.emojis.length - 4
                              ? 0.0
                              : kPanelPadding * 2 / 3),
                      child: Material(
                          color: widget.backgroundColor.withOpacity(
                              widget.emojis[index] == null ? 2 / 3 : 1.0),
                          elevation: widget.elevation,
                          borderRadius:
                              BorderRadius.all(Radius.circular(widget.radius)),
                          child: GestureDetector(
                            onTap: () {
                              if (widget.emojis[index] == null) {
                                _showErrorMsg(widget.username);
                              }
                            },
                            child: IconButton(
                              onPressed: widget.emojis[index] == null ||
                                      _isCurrentIndex(index)
                                  ? null
                                  : () {
                                      widget.onActionChanged(index);
                                    },
                              icon: Text(
                                kEmojis[index],
                                style: TextStyle(
                                    fontSize: widget.fontSize,
                                    color: Colors.blueAccent.withOpacity(
                                        _isCurrentIndex(index)
                                            ? 1.0
                                            : widget.unselectedOpacity)),
                              ),
                            ),
                          )),
                    ),
                  ))),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
