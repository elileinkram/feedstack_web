import 'package:flutter/material.dart';

class Qna extends StatefulWidget {
  final String q;
  final VoidCallback onNext;
  final List<String> hintFields;
  final List<bool> obscureFields;
  final List<String Function(String txt)> getErrorMsg;
  final List<Widget> suffixIcons;
  final String buttonTxt;
  final List<int> maxFieldLengths;
  final bool isLoading;
  final VoidCallback onBack;
  final int numberOfFields;
  final Widget bottomWidget;

  Qna({
    @required this.q,
    @required this.onNext,
    @required this.hintFields,
    @required this.obscureFields,
    @required this.getErrorMsg,
    @required this.buttonTxt,
    @required this.suffixIcons,
    @required this.isLoading,
    @required this.numberOfFields,
    @required this.maxFieldLengths,
    @required this.bottomWidget,
    this.onBack,
  });

  @override
  _QnaState createState() => _QnaState();
}

class _QnaState extends State<Qna> with AutomaticKeepAliveClientMixin {
  UnderlineInputBorder _underlineInputBorder(Color color) {
    return UnderlineInputBorder(borderSide: BorderSide(color: color));
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<String> _errorMsgs = List<String>();
  final List<bool> _fieldHasError = List<bool>();
  final List<FocusNode> _focusNodes = List<FocusNode>();

  Color _buttonColor() {
    if (_thereIsAnError()) {
      return Colors.black87.withOpacity(1 / 9);
    }
    return Colors.white;
  }

  Color _buttonTxtColor() {
    if (_thereIsAnError()) {
      return Colors.white.withOpacity(2 / 3);
    }
    return Colors.blueAccent;
  }

  void _updateError(int index, bool hasError) {
    final bool isPositiveBefore = !_thereIsAnError();
    _fieldHasError[index] = hasError;
    final bool isPositiveAfter = !_thereIsAnError();
    if (isPositiveAfter != isPositiveBefore) {
      setState(() {});
    }
  }

  bool _thereIsAnError() {
    return _fieldHasError.contains(true);
  }

  bool _isTheLastIndex(int index) {
    return index == widget.numberOfFields - 1;
  }

  TextInputAction _textInputAction(int index) {
    if (_indexIsLast(index)) {
      return TextInputAction.done;
    }
    return TextInputAction.next;
  }

  void _shiftFocusFromAToB(int from, int to) {
    _focusNodes[from].unfocus();
    _focusNodes[to].requestFocus();
  }

  bool _indexIsLast(int index) {
    return index == widget.numberOfFields - 1;
  }

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.numberOfFields; i++) {
      final String errorMsg = widget.getErrorMsg[i]('');
      _errorMsgs.add(errorMsg);
      _fieldHasError.add(errorMsg != null);
      _focusNodes.add(FocusNode());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: EdgeInsets.only(top: 12.0),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
            elevation: 0.0,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            title: widget.onBack == null
                ? Container()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10 / 3),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          color: Colors.white,
                          onPressed: widget.onBack,
                        ),
                      ),
                    ],
                  )),
        backgroundColor: Colors.transparent,
        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.only(
                left: MediaQuery.of(context).size.width * 1 / 12,
                right: MediaQuery.of(context).size.width * 1 / 12,
                top: MediaQuery.of(context).size.height * 1 / 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.q,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                      fontSize: 24),
                ),
                SizedBox(
                  height: 10 * 2 / 3 * 2,
                ),
                Column(
                  children: List.generate(
                    widget.numberOfFields,
                    (index) => Padding(
                      padding: EdgeInsets.only(
                          bottom: _isTheLastIndex(index) ? 0.0 : 18.0),
                      child: TextFormField(
                        focusNode: _focusNodes[index],
                        enabled: !widget.isLoading,
                        maxLength: widget.maxFieldLengths[index],
                        validator: (_) {
                          return _errorMsgs[index];
                        },
                        onChanged: (String txt) {
                          String Function(String txt) getErrorMsg =
                              widget.getErrorMsg[index];
                          _errorMsgs[index] = getErrorMsg(txt.trim());
                          if (_errorMsgs[index] == null) {
                            _formKey.currentState.validate();
                            _updateError(index, false);
                          } else {
                            _updateError(index, true);
                          }
                        },
                        cursorColor: Colors.white,
                        style: TextStyle(color: Colors.white),
                        obscureText: widget.obscureFields[index],
                        textInputAction: _textInputAction(index),
                        onFieldSubmitted: (_) {
                          if (_indexIsLast(index)) {
                            return;
                          }
                          _shiftFocusFromAToB(index, index + 1);
                        },
                        decoration: InputDecoration(
                            errorMaxLines: 3,
                            counterStyle: TextStyle(color: Colors.white),
                            hintText: widget.hintFields[index],
                            hintStyle: TextStyle(
                                color: Colors.white.withOpacity(2 / 3)),
                            suffixIcon: widget.suffixIcons[index],
                            errorStyle: TextStyle(color: Colors.yellowAccent),
                            errorBorder: _underlineInputBorder(
                                Colors.yellowAccent.withOpacity(0.5)),
                            disabledBorder: _underlineInputBorder(
                                Colors.white.withOpacity(1 / 3)),
                            focusedErrorBorder:
                                _underlineInputBorder(Colors.yellowAccent),
                            enabledBorder: _underlineInputBorder(
                                Colors.white.withOpacity(1 / 3)),
                            focusedBorder: _underlineInputBorder(
                                Colors.white.withOpacity(3 / 4))),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10 * 2 / 3 * 2),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: double.infinity,
                    child: Theme(
                      data: ThemeData(canvasColor: Colors.transparent),
                      child: FlatButton(
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(4.8))),
                        color: _buttonColor(),
                        child: Text(
                          widget.buttonTxt,
                          style: TextStyle(color: _buttonTxtColor()),
                        ),
                        onPressed: () {
                          final bool _isValid =
                              _formKey.currentState.validate();
                          if (_isValid) {
                            widget.onNext();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                widget.bottomWidget
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    super.dispose();
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].dispose();
    }
  }
}
