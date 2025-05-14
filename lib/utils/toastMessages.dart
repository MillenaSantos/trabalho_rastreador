import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastMessage {
  void success({
    required String message,
    ToastGravity? position = ToastGravity.TOP,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: position,
      backgroundColor: Colors.green[300],
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void warning({
    required String message,
    ToastGravity? position = ToastGravity.TOP,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: position,
      backgroundColor: Colors.indigo[50],
      textColor: Colors.black,
      fontSize: 16.0,
    );
  }

  void error({
    required String message,
    ToastGravity? position = ToastGravity.TOP,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: position,
      backgroundColor: Colors.red[400],
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
