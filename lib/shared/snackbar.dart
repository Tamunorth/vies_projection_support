import 'package:flutter/material.dart';

class CustomNotification {
  static void show(BuildContext context, String message,
      {bool isSuccess = true}) {
    final snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.down,
        margin: EdgeInsets.only(
          left: 16,
          right: MediaQuery.of(context).size.width -
              316, // 300 width + 16 left margin
          bottom: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
        ),
        content: Text(message),
        duration: Duration(
          seconds: 2,
        ));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
