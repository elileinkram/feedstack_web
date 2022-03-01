import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hashtagable/widgets/hashtag_text_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jasper/constants.dart';
import 'package:jasper/human.dart';
import 'package:jasper/playground_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:jasper/profile.dart';
import 'package:permission_handler/permission_handler.dart';

class Playground extends StatefulWidget {
  final double fontSize;

  Playground({@required this.fontSize});

  @override
  _PlaygroundState createState() => _PlaygroundState();
}

class _PlaygroundState extends State<Playground> {
  final TextEditingController _textEditingController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  File _imageFile;
  bool _isEmpty;
  final Map<String, dynamic> _newPost = Map<String, dynamic>();

  final List<IconData> _icons = [
    Foundation.paperclip,
    Icons.camera_alt,
    MaterialCommunityIcons.arrow_expand
  ];

  List<VoidCallback> get _iconFunctions {
    return [_fetchPhoto, _takePhoto, _expandPhoto];
  }

  Future<bool> _hasPermission(bool fromGallery) async {
    PermissionStatus status;
    if (fromGallery) {
      if (Platform.isIOS) {
        status = await Permission.camera.status
                .catchError((error) => print(error)) ??
            PermissionStatus.denied;
      } else {
        status = await Permission.storage.status
                .catchError((error) => print(error)) ??
            PermissionStatus.denied;
      }
    } else {
      status =
          await Permission.camera.status.catchError((error) => print(error)) ??
              PermissionStatus.denied;
    }
    if (status != PermissionStatus.granted) {
      if (fromGallery) {
        if (Platform.isIOS) {
          status = await Permission.camera
                  .request()
                  .catchError((error) => print(error)) ??
              PermissionStatus.denied;
        } else {
          status = await Permission.storage
                  .request()
                  .catchError((error) => print(error)) ??
              PermissionStatus.denied;
        }
      } else {
        status = await Permission.camera
                .request()
                .catchError((error) => print(error)) ??
            PermissionStatus.denied;
      }
      if (status == PermissionStatus.granted) {
        return true;
      }
    } else {
      return true;
    }
    return false;
  }

  Future<File> _getImage(bool fromGallery) async {
    if (await _hasPermission(fromGallery) == false) {
      return null;
    }
    final PickedFile pickedFile = await _imagePicker
        .getImage(
            source: fromGallery ? ImageSource.gallery : ImageSource.camera)
        .catchError((error) => print(error));
    if (pickedFile == null) {
      return null;
    }
    return File(pickedFile.path);
  }

  void _resetImage() {
    this._imageFile = null;
  }

  bool _isLastIndex(int index) {
    return index == _icons.length - 1;
  }

  void _updateImage(File imageFile) {
    if (imageFile == null) {
      return;
    }
    this._imageFile = imageFile;
    if (mounted) {
      setState(() {});
    }
  }

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
                      child: Image(
                        image: FileImage(_imageFile),
                        fit: BoxFit.contain,
                      ),
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
                      heroTag: 'bbb',
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

  void _fetchPhoto() async {
    final File imageFile = await _getImage(true);
    _updateImage(imageFile);
  }

  void _takePhoto() async {
    final File imageFile = await _getImage(false);
    _updateImage(imageFile);
  }

  bool _hasImage() {
    return _imageFile != null;
  }

  Future<String> _pushImageToBase(File imageFile, String docID) async {
    String photoUrl;
    final StorageReference storageRef = FirebaseStorage.instance
        .ref()
        .child('users/${Human.uid}/images/posts/$docID');
    final StorageUploadTask storageUploadTask = storageRef.putFile(
        imageFile, StorageMetadata(contentType: 'image/png'));
    final StorageTaskSnapshot storageTaskSnapshot =
        await storageUploadTask.onComplete.catchError((error) => print(error));
    if (storageUploadTask != null) {
      photoUrl = await storageTaskSnapshot.ref
          .getDownloadURL()
          .catchError((error) => print(error));
    }
    return photoUrl;
  }

  Future<HttpsCallableResult> _pushToStore(
      DocumentReference docRef, String caption) async {
    String imageUrl;
    if (_hasImage()) {
      imageUrl = await _pushImageToBase(_imageFile, docRef.id);
      if (imageUrl == null) {
        return null;
      }
    }
    final HttpsCallable makePost =
        CloudFunctions.instance.getHttpsCallable(functionName: 'makePost');
    return makePost.call({
      'image': imageUrl,
      'uid': Human.uid,
      'caption': caption,
      'postID': docRef.id
    }).catchError((error) => print(error));
  }

  void _showErrorMsg([String msg]) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10 * 2 / 3))),
            content: Text(msg ?? kDefaultErrorMsg),
            actions: [
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Okay',
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
            ],
          );
        }).catchError((error) => print(error));
  }

  void _setMapsToVal(
      List<Map<String, dynamic>> maps, String key, dynamic value) {
    for (int i = 0; i < maps.length; i++) {
      maps[i][key] = value;
    }
  }

  void _initPost(Map<String, dynamic> post1, String docID) {
    _setMapsToVal([post1], 'authorUID', Human.uid);
    _setMapsToVal([post1], 'username', Human.username);
    _setMapsToVal([post1], 'bookmark', DateTime.now().millisecondsSinceEpoch);
    _setMapsToVal([post1], 'profilePhoto', Human.profilePhoto);
    _setMapsToVal([post1], 'coverPhoto', Human.coverPhoto);
    _setMapsToVal([post1], 'caption', _textEditingController.text.trim());
    if (_hasImage()) {
      post1['image'] = _imageFile;
    }
    post1['postID'] = docID;
    post1['key'] = UniqueKey();
    post1['reactionSelected'] = kNullActionValue;
    post1['seen'] = true;
    _setMapsToVal([post1], 'numberOfComments', 0);
  }

  Future<void> _uploadPost() async {
    final DocumentReference docRef =
        FirebaseFirestore.instance.collection('posts').doc();
    final String docID = docRef.id;
    _initPost(_newPost, docID);
    _pushToStore(docRef, _textEditingController.text.trim())
        .catchError((error) => print(error));
  }

  Future<bool> _shouldSend() {
    return showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10 * 2 / 3))),
            content: Text('Do you want to upload this post?'),
            actions: [
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text(
                  'No',
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text(
                  'Yes',
                  style: TextStyle(color: Colors.blueAccent),
                ),
              )
            ],
          );
        }).catchError((error) => print(error));
  }

  Future<void> _onPressed() async {
    if (await _shouldSend() ?? false) {
      _uploadPost();
      if (mounted) {
        Navigator.of(context).pushReplacement(
            CupertinoPageRoute(builder: (BuildContext context) {
          return Profile(
            newPost: _newPost,
            username: Human.username,
            uid: Human.uid,
            reactionSelected: 0,
            profilePhoto: Human.profilePhoto,
            initialIndex: 0,
            coverPhoto: Human.coverPhoto,
            comesWithUserSnap: true,
          );
        })).catchError((error) => print(error));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _isEmpty = true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(kPanelPadding)),
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: kPanelPadding, vertical: kPanelPadding / 3),
            child: Column(
              children: [
                Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: kPanelPadding * 2 / 3),
                    child: Column(
                      children: [
                        HashTagTextField(
                          decorateAtSign: true,
                          autofocus: true,
                          onChanged: (String txt) {
                            final bool isEmpty = txt.trim().isEmpty;
                            if (isEmpty != _isEmpty) {
                              _isEmpty = isEmpty;
                              setState(() {});
                            }
                          },
                          textInputAction: TextInputAction.done,
                          controller: _textEditingController,
                          cursorColor: Colors.blueAccent,
                          textCapitalization: TextCapitalization.sentences,
                          buildCounter: (BuildContext context,
                                  {int currentLength,
                                  int maxLength,
                                  bool isFocused}) =>
                              null,
                          decoratedStyle: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: widget.fontSize),
                          basicStyle: TextStyle(
                              color: Colors.black87, fontSize: widget.fontSize),
                          decoration: InputDecoration(
                            hintText: 'Type something...',
                            hintStyle: TextStyle(
                                color: Colors.blueGrey[200],
                                fontSize: widget.fontSize),
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                          maxLength: kPostMaxLength,
                        ),
                        !_hasImage()
                            ? Container()
                            : Align(
                                alignment: Alignment.centerLeft,
                                child: PlaygroundImage(
                                  imageFile: _imageFile,
                                  resetImage: () {
                                    _resetImage();
                                    setState(() {});
                                  },
                                ),
                              )
                      ],
                    )),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                        children:
                            List<Widget>.generate(_icons.length, (int index) {
                      if (_isLastIndex(index) && !_hasImage()) {
                        return Container();
                      }
                      return IconButton(
                        icon: Icon(
                          _icons[index],
                          color: Colors.blueGrey[200],
                          size: 22.5,
                        ),
                        onPressed: _iconFunctions[index],
                      );
                    })),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: (1 + 1 / 3) * kPanelPadding),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {
                _showErrorMsg('Type something, then send.');
              },
              child: FlatButton(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                disabledColor: Colors.blueGrey[100],
                color: Colors.blueAccent,
                shape: StadiumBorder(),
                child: Text(
                  'Create new post',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: _isEmpty ? null : _onPressed,
              ),
            ),
          ),
        )
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    _textEditingController.dispose();
  }
}

