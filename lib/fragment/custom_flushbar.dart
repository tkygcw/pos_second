import 'package:another_flushbar/flushbar.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class CustomFlushbar {
  static final CustomFlushbar instance = CustomFlushbar.init();
  String flushbarStatus = '';
  BuildContext context = MyApp.navigatorKey.currentContext!;

  CustomFlushbar.init();

  showFlushbar(String title, String message, Color backgroundColor, Function(Flushbar flushbar) onTap, {Duration? duration}){
    Flushbar(
      icon: Icon(Icons.error, size: 32, color: Colors.white),
      shouldIconPulse: false,
      title: title,
      message: message,
      duration: duration,
      backgroundColor: backgroundColor,
      messageColor: Colors.white,
      flushbarPosition: FlushbarPosition.TOP,
      maxWidth: 350,
      margin: EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      padding: EdgeInsets.fromLTRB(40, 20, 40, 20),
      onTap: onTap,
      onStatusChanged: (status) {
        flushbarStatus = status.toString();
      },
    ).show(context);
    playSound();
    // if(duration != null){
    //   Future.delayed(duration, () {
    //     print("status change: ${flushbarStatus}");
    //     if (flushbarStatus != "FlushbarStatus.IS_HIDING" && flushbarStatus != "FlushbarStatus.DISMISSED") playSound();
    //   });
    // }
  }

  playSound() {
    try {
      final assetsAudioPlayer = AssetsAudioPlayer();
      assetsAudioPlayer.open(
        Audio("audio/review.mp3"),
      );
    } catch(e) {
      print("Play Sound Error: ${e}");
    }
  }
}