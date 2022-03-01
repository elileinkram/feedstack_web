import 'package:flutter/material.dart';
import 'package:jasper/constants.dart';

class SearchField extends StatelessWidget {
  final TextEditingController textEditingController;
  final bool isEmpty;
  final VoidCallback onBack;
  final bool autofocus;
  final String hintText;

  final double _fontSize = kTitleFontSize;

  SearchField(
      {@required this.textEditingController,
      @required this.isEmpty,
      @required this.onBack,
      @required this.hintText,
      @required this.autofocus});

  void _clearText() {
    this.textEditingController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            cursorColor: Colors.white,
            controller: this.textEditingController,
            style: TextStyle(color: Colors.white, fontSize: _fontSize),
            textInputAction: TextInputAction.search,
            autofocus: this.autofocus,
            decoration: InputDecoration(
                prefixIcon: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                  onPressed: this.onBack,
                ),
                hintText: this.hintText,
                hintStyle: TextStyle(color: Colors.white, fontSize: _fontSize),
                border: InputBorder.none),
          ),
        ),
        this.isEmpty
            ? Container()
            : IconButton(
                icon: Icon(
                  Icons.clear,
                  color: Colors.white,
                ),
                onPressed: _clearText,
              )
      ],
    );
  }
}
