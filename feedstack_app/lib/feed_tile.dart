import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'constants.dart';

class FeedTile extends StatelessWidget {
  final String name;
  final String photo;
  final String description;
  final bool hasDownloaded;
  final String code;
  final int bookmark;
  final void Function(
      String name,
      String channelID,
      String photo,
      String description,
      bool hasDownloaded,
      String code,
      int bookmark,
      DocumentSnapshot snapshot) navigateToFeedInfo;
  final String channelID;
  final DocumentSnapshot snapshot;

  FeedTile({
    @required this.name,
    @required this.photo,
    @required this.channelID,
    @required this.navigateToFeedInfo,
    @required this.description,
    @required this.code,
    @required this.hasDownloaded,
    @required this.bookmark,
    @required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        highlightColor: Colors.blueGrey[50],
        onTap: () {
          this.navigateToFeedInfo(name, channelID, photo, description,
              hasDownloaded, code, bookmark, snapshot);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: kPanelPadding, vertical: kPanelPadding * 0.5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Material(
                  borderRadius: BorderRadius.all(
                      Radius.circular(kPostFaceRadius * 0.875)),
                  elevation: 10 / 9 * (1 + 1 / 30),
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(
                        Radius.circular(kPostFaceRadius * 0.875)),
                    child: SizedBox(
                      height: kPostFaceRadius * 2 * (1 + 1 / 30),
                      width: kPostFaceRadius * 2 * (1 + 1 / 30),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Material(color: Colors.blueGrey[50]),
                          ),
                          Positioned.fill(
                              child: Center(
                            child: Icon(
                              FontAwesome5Solid.stream,
                              color: Colors.blueGrey[200],
                              size: kPostFaceRadius * 2 / 3 * (1 + 1 / 30),
                            ),
                          )),
                          Positioned.fill(
                              child: FancyShimmerImage(
                            imageUrl: this.photo,
                            boxFit: BoxFit.cover,
                          ))
                        ],
                      ),
                    ),
                  )),
              SizedBox(width: kPanelPadding),
              Expanded(
                child: Text(
                  this.name,
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
