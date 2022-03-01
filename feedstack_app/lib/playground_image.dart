import 'package:flutter/material.dart';
import 'dart:io';

class PlaygroundImage extends StatelessWidget {
  final VoidCallback resetImage;
  final File imageFile;

  PlaygroundImage({@required this.resetImage, @required this.imageFile});

  final double _clearIconSize = 18.5;
  final double _iconDilation = (2 / 3 + 1 / 2) / 2;
  final double _imageSize = 45.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
              bottom: _clearIconSize / 2 * _iconDilation,
              top: _clearIconSize / 2 * _iconDilation,
              right: _clearIconSize / 2 * _iconDilation),
          child: Material(
            elevation: 10.0 / 9,
            shadowColor: Colors.blueAccent,
            color: Colors.blueGrey[50],
            borderRadius: BorderRadius.all(Radius.circular(10 * 2 / 3)),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(10 * 2 / 3)),
              child: SizedBox(
                width: _imageSize,
                height: _imageSize,
                child: Image.file(
                  this.imageFile,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
            child: Align(
          alignment: Alignment.topRight,
          child: ClipOval(
            child: SizedBox(
              height: _clearIconSize - 10 / 3,
              width: _clearIconSize - 10 / 3,
              child: Material(
                color: Colors.white,
              ),
            ),
          ),
        )),
        Positioned.fill(
          child: Align(
              alignment: Alignment.topRight,
              child: Hero(
                tag: 'bbb',
                child: Icon(Icons.cancel,
                    color: Colors.black87, size: _clearIconSize),
              )),
        ),
        Positioned.fill(
            child: Align(
          alignment: Alignment.topRight,
          child: SizedBox(
            height: _clearIconSize,
            width: _clearIconSize,
            child: FloatingActionButton(
                heroTag: 'rmi',
                onPressed: this.resetImage,
                elevation: 0.0,
                backgroundColor: Colors.transparent,
                child: Container()),
          ),
        ))
      ],
    );
  }
}
