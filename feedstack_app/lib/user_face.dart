import 'dart:io';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class UserFace extends StatelessWidget {
  final String profilePhoto;
  final double iconSize;
  final double radius;
  final File fProfilePhoto;
  final double elevation;

  UserFace(
      {@required this.profilePhoto,
      @required this.iconSize,
      @required this.radius,
      @required this.fProfilePhoto,
      @required this.elevation});

  bool get _hasProfilePhoto {
    return this.profilePhoto != null || this.fProfilePhoto != null;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: CircleBorder(),
      elevation: this.elevation,
      child: CircleAvatar(
          radius: this.radius,
          backgroundColor: Colors.blueGrey[50],
          child: ClipOval(
              child: Stack(
            children: [
              Center(
                child: Icon(
                  FontAwesome5Solid.user,
                  size: this.iconSize,
                  color: Colors.blueGrey[200],
                ),
              ),
              _hasProfilePhoto
                  ? this.fProfilePhoto != null
                      ? Positioned.fill(
                          child: Image.file(
                            this.fProfilePhoto,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Positioned.fill(
                          child: FancyShimmerImage(
                          imageUrl: this.profilePhoto,
                          boxFit: BoxFit.cover,
                        ))
                  : Container()
            ],
          ))),
    );
  }
}
