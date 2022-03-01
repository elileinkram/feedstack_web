import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jasper/constants.dart';
import 'package:jasper/human.dart';
import 'package:jasper/user_head.dart';
import 'package:jasper/waiting_widget.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfileUpdate extends StatefulWidget {
  final double expandedHeight;

  ProfileUpdate({@required this.expandedHeight});

  @override
  _ProfileUpdateState createState() => _ProfileUpdateState();
}

class _ProfileUpdateState extends State<ProfileUpdate> {
  void _onBack() {
    Navigator.of(context).pop();
  }

  final TextEditingController _textEditingController =
      TextEditingController(text: Human.username);
  final InputBorder _focusedInputBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.blueAccent, width: 10 / 6));
  final InputBorder _unfocusedInputBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.blueGrey[100], width: 10 / 6));
  String _usernameErrorMsg;
  dynamic _profilePhoto;
  dynamic _coverPhoto;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading;
  final ImagePicker _imagePicker = ImagePicker();

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

  bool _usernameHasChanged() {
    return Human.username != _getUsername();
  }

  bool _photoHasChanged(bool isCover) {
    final bool hasRemoved = _hasRemoved(isCover);
    if (isCover) {
      return _coverPhoto is File &&
              (Human.fCoverPhoto == null ||
                  _coverPhoto.path != Human.fCoverPhoto.path) ||
          hasRemoved;
    }
    return _profilePhoto is File &&
            (Human.fProfilePhoto == null ||
                _profilePhoto.path != Human.fProfilePhoto.path) ||
        hasRemoved;
  }

  bool _hasRemoved(bool isCover) {
    if (isCover) {
      return _coverPhoto == null && _comesWithPhoto(isCover);
    }
    return _profilePhoto == null && _comesWithPhoto(isCover);
  }

  bool _hasChanged() {
    return _usernameHasChanged() ||
        _photoHasChanged(true) ||
        _photoHasChanged(false);
  }

  bool _usernameIsBadlyFormatted() {
    return _usernameErrorMsg != null;
  }

  String _getUsername() {
    return _textEditingController.text.trim();
  }

  Color _buttonColor() {
    if (_usernameIsBadlyFormatted() || !_hasChanged()) {
      return Colors.blueGrey[100];
    }
    return Colors.blueAccent;
  }

  String _getUsernameErrorMsg(String txt) {
    if (!RegExp(r"^[a-zA-Z0-9_]*$").hasMatch(txt.trim())) {
      return kUsernameErrors['content'];
    }
    if (txt.length < 3) {
      return kUsernameErrors['length'];
    }
    return null;
  }

  void _resetImage(bool isCover) {
    if (isCover) {
      _coverPhoto = null;
    } else {
      _profilePhoto = null;
    }
    setState(() {});
  }

  void _updateImage(File imageFile, bool isCover) {
    if (imageFile == null) {
      return;
    }
    if (isCover) {
      _coverPhoto = imageFile;
    } else {
      _profilePhoto = imageFile;
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showErrorMsg([String msg]) {
    return showDialog(
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

  void _seekImage(bool isCover) async {
    WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
    final bool hasPhoto = isCover ? _coverPhoto != null : _profilePhoto != null;
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10 * 2 / 3))),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                FlatButton(
                  splashColor: Colors.transparent,
                  color: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Text(
                    isCover ? 'Cover Photo' : 'Profile Photo',
                    style: TextStyle(
                        fontWeight: FontWeight.w500, fontSize: kTitleFontSize),
                  ),
                  onPressed: () {},
                ),
              ],
            ),
            contentPadding: EdgeInsets.all(0.0),
            titlePadding: EdgeInsets.only(top: 10),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FlatButton(
                  child: Row(
                    children: <Widget>[
                      Text(
                        'Camera',
                        style: TextStyle(
                            fontWeight: FontWeight.w400, fontSize: 16.0),
                      ),
                    ],
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    _updateImage(await _getImage(false), isCover);
                  },
                ),
                FlatButton(
                  child: Row(
                    children: <Widget>[
                      Text(
                        'Gallery',
                        style: TextStyle(
                            fontWeight: FontWeight.w400, fontSize: 16.0),
                      ),
                    ],
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    _updateImage(await _getImage(true), isCover);
                  },
                ),
                !hasPhoto
                    ? Container()
                    : FlatButton(
                        child: Row(
                          children: <Widget>[
                            Text(
                              'Remove',
                              style: TextStyle(
                                  fontWeight: FontWeight.w400, fontSize: 16.0),
                            ),
                          ],
                        ),
                        onPressed: () {
                          _resetImage(isCover);
                          Navigator.of(context).pop();
                        },
                      ),
              ],
            ),
          );
        }).catchError((onError) => print(onError));
  }

  bool _comesWithPhoto(bool isCover) {
    if (isCover) {
      return Human.fCoverPhoto != null || Human.coverPhoto != null;
    }
    return Human.fProfilePhoto != null || Human.profilePhoto != null;
  }

  void _hideKeypad() {
    WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
  }

  Future<String> _pushImageToBase(File imageFile, String filePath) async {
    String photoUrl;
    final StorageReference storageRef =
        FirebaseStorage.instance.ref().child(filePath);
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

  Future<bool> _isTaken(String data) async {
    final QuerySnapshot qs = await FirebaseFirestore.instance
        .collection('users')
        .where('displayName', isEqualTo: data.toLowerCase())
        .get()
        .catchError((error) => print(error));
    if (qs != null) {
      return qs.docs.isNotEmpty &&
          (qs.docs.length != 1 || qs.docs.first.id != Human.uid);
    }
    return true;
  }

  Future<void> _makeChanges() async {
    final Map<String, dynamic> data = Map<String, dynamic>();
    final String profilePath =
        'users/${Human.uid}/images/profilePhoto/${DateTime.now().millisecondsSinceEpoch}';
    final String coverPath =
        'users/${Human.uid}/images/coverPhoto/${DateTime.now().millisecondsSinceEpoch}';
    bool deleteCover = false;
    bool deleteProfile = false;
    if (_photoHasChanged(false)) {
      Human.fProfilePhoto = _profilePhoto;
      if (Human.fProfilePhoto != null) {
        data['profilePhoto'] =
            await _pushImageToBase(Human.fProfilePhoto, profilePath);
        if (data['profilePhoto'] == null) {
          data.remove('profilePhoto');
        } else {
          Human.profilePhoto = data['profilePhoto'];
        }
      } else {
        Human.profilePhoto = null;
        deleteProfile = true;
      }
    }
    if (_photoHasChanged(true)) {
      Human.fCoverPhoto = _coverPhoto;
      if (Human.fCoverPhoto != null) {
        data['coverPhoto'] =
            await _pushImageToBase(Human.fCoverPhoto, coverPath);
        if (data['coverPhoto'] == null) {
          data.remove('coverPhoto');
        } else {
          Human.coverPhoto = data['coverPhoto'];
        }
      } else {
        Human.coverPhoto = null;
        deleteCover = true;
      }
    }
    final String username = _textEditingController.text.trim();
    data['username'] = Human.username = username;
    final HttpsCallable updateProfile =
        CloudFunctions.instance.getHttpsCallable(functionName: 'updateProfile');
    updateProfile.call({
      'username': data['username'],
      'coverPhoto': data['coverPhoto'],
      'profilePhoto': data['profilePhoto'],
      'deleteProfile': deleteProfile,
      'deleteCover': deleteCover,
      'uid': Human.uid,
      'coverPath': coverPath,
      'profilePath': profilePath,
    }).catchError((error) => print(error));
  }

  void _toggleLoading() {
    _isLoading = !_isLoading;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _profilePhoto = Human.fProfilePhoto ?? Human.profilePhoto;
    _coverPhoto = Human.fCoverPhoto ?? Human.coverPhoto;
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.blueAccent,
      child: SafeArea(
        child: GestureDetector(
          onTap: _hideKeypad,
          child: Material(
            color: Colors.white,
            child: DefaultTabController(
              length: 2,
              child: NestedScrollView(
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      elevation: 0.0,
                      forceElevated: true,
                      automaticallyImplyLeading: false,
                      backgroundColor: Colors.blueAccent,
                      floating: false,
                      pinned: true,
                      title: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          Text(
                            'Update profile',
                            style: TextStyle(
                                color: Colors.white, fontSize: kTitleFontSize),
                          ),
                        ],
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: UserHead(
                          heroTag: 'update_user',
                          onBack: _onBack,
                          coverPhoto:
                              _photoHasChanged(true) ? null : Human.coverPhoto,
                          fCoverPhoto: _photoHasChanged(true)
                              ? _coverPhoto
                              : Human.fCoverPhoto,
                          expandedHeight: widget.expandedHeight,
                          profilePhoto: _photoHasChanged(false)
                              ? null
                              : Human.profilePhoto,
                          fProfilePhoto: _photoHasChanged(false)
                              ? _profilePhoto
                              : Human.fProfilePhoto,
                          seekImage: _seekImage,
                        ),
                      ),
                      expandedHeight: widget.expandedHeight,
                    ),
                  ];
                },
                body: Padding(
                    padding: const EdgeInsets.only(
                        left: 20.0, right: 20.0, top: 17.5),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          SizedBox(height: 10 / 3),
                          TextFormField(
                            enabled: !_isLoading,
                            cursorColor: Colors.blueAccent,
                            onChanged: (String txt) {
                              txt = txt.trim();
                              final String errorMsg = _getUsernameErrorMsg(txt);
                              if (errorMsg != _usernameErrorMsg) {
                                _usernameErrorMsg = errorMsg;
                                if (_usernameErrorMsg == null) {
                                  _formKey.currentState.validate();
                                }
                              }
                              setState(() {});
                            },
                            validator: (_) {
                              return _usernameErrorMsg;
                            },
                            textCapitalization: TextCapitalization.sentences,
                            maxLength: kUsernameMaxLength,
                            controller: _textEditingController,
                            autofocus: true,
                            style: TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                                hintText: 'Username',
                                errorMaxLines: 3,
                                hintStyle: TextStyle(
                                    color: Colors.black87.withOpacity(1 / 3)),
                                counterStyle:
                                    TextStyle(color: Colors.blueGrey[200]),
                                border: _focusedInputBorder,
                                focusedErrorBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.redAccent)),
                                errorBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.redAccent)),
                                enabledBorder: _unfocusedInputBorder,
                                disabledBorder: _unfocusedInputBorder,
                                focusedBorder: _focusedInputBorder),
                          ),
                          SizedBox(height: 8.75),
                          SizedBox(
                            width: double.infinity,
                            child: FlatButton(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(10 / 3))),
                              onPressed: () async {
                                if (_isLoading) {
                                  return;
                                }
                                if (!_hasChanged()) {
                                  _showErrorMsg(
                                      'Make sure you change photos or username.');
                                } else if (_formKey.currentState.validate()) {
                                  _toggleLoading();
                                  final String username =
                                      _textEditingController.text.trim();
                                  final bool usernameIsTaken =
                                      username.toLowerCase() == kAppName ||
                                          (username != Human.username &&
                                              (await _isTaken(username)));
                                  if (usernameIsTaken) {
                                    _showErrorMsg(
                                        'Someone else is already using this username.');
                                  } else {
                                    await _makeChanges();
                                    _showErrorMsg(
                                            'Great success. Your profile has been updated.')
                                        .then((_) {
                                      if (mounted) {
                                        _onBack();
                                      }
                                    });
                                  }
                                  _toggleLoading();
                                }
                              },
                              child: Text(
                                'Save changes',
                                style: TextStyle(color: Colors.white),
                              ),
                              color: _buttonColor(),
                            ),
                          ),
                          Expanded(
                              child: Center(
                            child: WaitingWidget(
                              isLoading: _isLoading,
                              color: Colors.blueAccent,
                            ),
                          )),
                          Padding(
                            padding: EdgeInsets.only(bottom: 10 * 2 / 3),
                            child: FlatButton(
                              child: Text(
                                'Tap on the photo you want to update',
                                style: TextStyle(
                                    color:
                                        Colors.blueAccent.withOpacity(2 / 3)),
                              ),
                              onPressed: null,
                            ),
                          )
                        ],
                      ),
                    )),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _textEditingController.dispose();
  }
}
