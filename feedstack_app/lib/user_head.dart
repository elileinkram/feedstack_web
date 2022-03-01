import 'dart:io';
import 'dart:ui';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jasper/user_face.dart';

class UserHead extends StatefulWidget {
  final String profilePhoto;
  final String coverPhoto;
  final double expandedHeight;
  final VoidCallback onBack;
  final File fProfilePhoto;
  final File fCoverPhoto;
  final String heroTag;
  final void Function(bool isCover) seekImage;

  UserHead(
      {@required this.profilePhoto,
      @required this.coverPhoto,
      @required this.expandedHeight,
      @required this.onBack,
      @required this.fProfilePhoto,
      @required this.fCoverPhoto,
      @required this.heroTag,
      this.seekImage});

  @override
  _UserHeadState createState() => _UserHeadState();
}

class _UserHeadState extends State<UserHead> {
  bool get _hasCoverPhoto {
    return this.widget.fCoverPhoto != null || this.widget.coverPhoto != null;
  }

  Widget child;

  double get _radius {
    return this.widget.expandedHeight / 4.5;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.seekImage != null ? widget.seekImage(true) : null,
      child: Stack(
        children: [
          Positioned.fill(
              child: Material(
            color: Colors.white,
          )),
          Positioned.fill(
            child: !_hasCoverPhoto
                ? Material(
                    color: Colors.blueAccent,
                  )
                : this.widget.fCoverPhoto != null
                    ? Image.file(this.widget.fCoverPhoto, fit: BoxFit.cover)
                    : FancyShimmerImage(
                        imageUrl: this.widget.coverPhoto,
                        boxFit: BoxFit.cover,
                      ),
          ),
          !_hasCoverPhoto
              ? Container()
              : Positioned.fill(
                  child: ClipRect(
                      child: BackdropFilter(
                          filter: ImageFilter.blur(
                              sigmaX: 10.0 * 2 / 3, sigmaY: 10.0 * 2 / 3),
                          child: Container(
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                  Colors.black87.withOpacity(1 / 3 * 2 / 3),
                                  Colors.black87
                                      .withOpacity(1 / 3 * 2 / 3 * 1 / 3),
                                  Colors.black87.withOpacity(
                                      1 / 3 * 2 / 3 * 1 / 3 * 2 / 3),
                                  Colors.black87.withOpacity(
                                      1 / 3 * 2 / 3 * 1 / 3 * 2 / 3),
                                  Colors.black87
                                      .withOpacity(1 / 3 * 2 / 3 * 1 / 3),
                                  Colors.black87.withOpacity(1 / 3 * 2 / 3)
                                ])),
                          ))),
                ),
          Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: widget.heroTag != null
                      ? Hero(
                          tag: widget.heroTag,
                          child: UserFace(
                            elevation: 10 / 3,
                            radius: _radius,
                            iconSize: _radius * 2 / 3,
                            profilePhoto: widget.profilePhoto,
                            fProfilePhoto: widget.fProfilePhoto,
                          ),
                        )
                      : UserFace(
                          elevation: 10 / 3,
                          radius: _radius,
                          iconSize: _radius * 2 / 3,
                          profilePhoto: widget.profilePhoto,
                          fProfilePhoto: widget.fProfilePhoto,
                        ),
                ),
              ),
              widget.seekImage == null
                  ? Container()
                  : Positioned.fill(
                      child: GestureDetector(
                        onTap: () => widget.seekImage(false),
                        child: Center(
                            child: Stack(
                          children: [
                            ClipOval(
                              child: SizedBox(
                                height: _radius * 2 - 100 / 9,
                                width: _radius * 2 - 100 / 9,
                                child: Material(color: Colors.transparent),
                              ),
                            ),
                            Positioned.fill(
                                child: Align(
                                    alignment: Alignment.bottomRight,
                                    child: SizedBox(
                                      width: 100 / 3,
                                      height: 100 / 3,
                                      child: FloatingActionButton(
                                        heroTag: 'upp',
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        onPressed: () =>
                                            widget.seekImage(false),
                                        backgroundColor: Colors.blueAccent,
                                        child: Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 20.0,
                                        ),
                                      ),
                                    )))
                          ],
                        )),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
