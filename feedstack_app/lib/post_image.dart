import 'dart:io';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:jasper/constants.dart';

class PostImage extends StatefulWidget {
  final dynamic image;
  final String heroTag;

  PostImage({@required this.image, @required this.heroTag});

  @override
  _PostImageState createState() => _PostImageState();
}

class _PostImageState extends State<PostImage> {
  Widget _child;
  Widget _expandedChild;

  void _onBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _expandPhoto() async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Stack(
            children: [
              Positioned.fill(
                  child: Material(
                color: Colors.black87,
              )),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: kPanelPadding,
                      horizontal: kPanelPadding / 2.875),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.all(Radius.circular(kPanelPadding)),
                    child: InteractiveViewer(
                      child: _expandedChild,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: kPanelPadding * 1.5),
                  child: Transform.scale(
                    scale: 0.875,
                    child: FloatingActionButton(
                      heroTag: widget.heroTag + 'rem',
                      elevation: 0.0,
                      onPressed: () => _onBack(context),
                      mini: true,
                      backgroundColor: Colors.black87.withOpacity(3 / 4),
                      child: Icon(
                        Icons.clear,
                        color: Colors.white,
                        size: 20.0,
                      ),
                    ),
                  ),
                ),
              )
            ],
          );
        });
  }

  @override
  void initState() {
    super.initState();
    _child = widget.image is File
        ? Image.file(
            widget.image,
            fit: BoxFit.cover,
          )
        : FancyShimmerImage(
            imageUrl: this.widget.image,
            boxFit: BoxFit.cover,
          );

    _expandedChild = widget.image is File
        ? Image.file(
            widget.image,
            fit: BoxFit.contain,
          )
        : FancyShimmerImage(
            imageUrl: this.widget.image,
            boxFit: BoxFit.contain,
          );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
        constraints:
            BoxConstraints(minWidth: double.infinity, maxHeight: 1000 / 3.5),
        child: Padding(
            padding: EdgeInsets.only(
                bottom: kPanelPadding * 2 / 3,
                right: kPanelPadding * 2 / 3,
                left: kPanelPadding * 2 / 3),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(kPanelPadding)),
              child: GestureDetector(child: _child, onTap: _expandPhoto),
            )));
  }
}
