import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:jasper/human.dart';
import 'package:jasper/post_page.dart';
import 'package:jasper/profile.dart';
import 'package:jasper/search_page.dart';
import 'package:jasper/user_face.dart';
import 'constants.dart';

class MainActions extends StatefulWidget {
  final VoidCallback updateTownHall;
  final ScrollController scrollController;

  MainActions({@required this.updateTownHall, @required this.scrollController});

  @override
  _MainActionsState createState() => _MainActionsState();
}

class _MainActionsState extends State<MainActions> {

  void _navigateToProfilePage(BuildContext context) {
    Navigator.of(context)
        .push(CupertinoPageRoute(builder: (BuildContext context) {
      return Profile(
        reactionSelected: 0,
        initialIndex: 0,
        comesWithUserSnap: true,
        uid: Human.uid,
        username: Human.username,
        profilePhoto: Human.profilePhoto,
        coverPhoto: Human.coverPhoto,
        heroTag: 'ur',
      );
    })).then((_) {
      this.widget.updateTownHall();
    }).catchError((error) => print(error));
  }

  void _navigateToSearchPage(BuildContext context) async {
    Navigator.of(context)
        .push(CupertinoPageRoute(builder: (BuildContext context) {
      return SearchPage();
    })).then((_) {
      this.widget.updateTownHall();
    }).catchError((error) => print(error));
  }

  void _navigateToPostPage(BuildContext context) async {
    Navigator.of(context)
        .push(CupertinoPageRoute(builder: (BuildContext context) {
          return PostPage();
        }))
        .catchError((error) => print(error))
        .then((_) {
          this.widget.updateTownHall();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Align(
              widthFactor: 1 / 4.5,
              child: IconButton(
                  onPressed: null,
                  icon: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    radius: kPostFaceRadius * 9 / 10,
                  )),
            ),
            IconButton(
              icon: Icon(
                FontAwesome5Solid.align_center,
                color: Colors.white,
                size: 22.0,
              ),
              onPressed: null,
            ),
            Text(
              'Feedstack',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            )
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.search,
                color: Colors.white,
              ),
              onPressed: () => _navigateToSearchPage(context),
            ),
            IconButton(
              icon: Icon(
                Icons.add,
                color: Colors.white,
              ),
              onPressed: () => _navigateToPostPage(context),
            ),
            Align(
              widthFactor: 1 / 9,
              child: IconButton(
                  onPressed: null,
                  icon: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    radius: kPostFaceRadius * 9 / 10,
                  )),
            ),
            Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: Hero(
                      tag: 'ur',
                      child: UserFace(
                        elevation: 10 / 3,
                        fProfilePhoto: Human.fProfilePhoto,
                        iconSize: kPostFaceRadius * (3 / 4 + 9 / 10) / 3,
                        radius: kPostFaceRadius * (3 / 4 + 9 / 10) / 2,
                        profilePhoto: Human.profilePhoto,
                      ),
                    ),
                  ),
                ),
                IconButton(
                    onPressed: () => _navigateToProfilePage(context),
                    icon: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      radius: kPostFaceRadius * 9 / 10,
                    )),
              ],
            ),
            Align(
              widthFactor: 1 / 4.5,
              child: IconButton(
                  onPressed: null,
                  icon: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    radius: kPostFaceRadius * 9 / 10,
                  )),
            ),
          ],
        )
      ],
    );
  }
}
