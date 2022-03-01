import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jasper/constants.dart';
import 'package:jasper/human.dart';
import 'package:jasper/user_face.dart';

class UserTile extends StatelessWidget {
  final String profilePhoto;
  final String uid;
  final void Function(
      String uid,
      String username,
      String profilePhoto,
      String coverPhoto,
      dynamic numberOfIthReactions,
      DocumentSnapshot snapshot) navigateToProfilePage;
  final String username;
  final String coverPhoto;
  final DocumentSnapshot snapshot;
  final dynamic numberOfIthReactions;

  UserTile(
      {@required this.profilePhoto,
      @required this.uid,
      @required this.navigateToProfilePage,
      @required this.username,
      @required this.coverPhoto,
      @required this.snapshot,
      @required this.numberOfIthReactions});

  String get _username {
    return this.uid == Human.uid ? Human.username : this.username;
  }

  File get _fProfilePhoto {
    return this.uid == Human.uid ? Human.fProfilePhoto : null;
  }

  String get _profilePhoto {
    return this.uid == Human.uid ? Human.profilePhoto : this.profilePhoto;
  }

  String get _coverPhoto {
    return this.uid == Human.uid ? Human.coverPhoto : this.coverPhoto;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        highlightColor: Colors.blueGrey[50],
        onTap: () {
          this.navigateToProfilePage(this.uid, _username, _profilePhoto,
              _coverPhoto, this.numberOfIthReactions, this.snapshot);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
              vertical: kPanelPadding / 2, horizontal: kPanelPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              UserFace(
                elevation: 10 / 9,
                fProfilePhoto: _fProfilePhoto,
                iconSize: kPostFaceRadius * 2 / 3,
                profilePhoto: _profilePhoto,
                radius: kPostFaceRadius,
              ),
              SizedBox(width: kPanelPadding),
              Expanded(
                child: Text(
                  _username,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: kTitleFontSize * 9 / 10,
                      fontWeight: FontWeight.w400),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
