import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../translation/AppLocalizations.dart';

abstract class CustomToastification {
  final String title;
  final Widget? description;
  final bool isError;
  final bool playSound;
  final int playTimes;
  final int autoCloseDuration;
  final bool showProgressBar;

  CustomToastification({
    required this.title,
    this.description,
    this.isError = false,
    this.playSound = false,
    this.playTimes = 1,
    this.autoCloseDuration = 4,
    this.showProgressBar = false,
  });

  void showToast() {
    _showToastification();
    _playSoundIfNeeded();
  }

  void _showToastification() {
    toastification.show(
      type: isError ? ToastificationType.error : ToastificationType.success,
      style: ToastificationStyle.fillColored,
      alignment: Alignment.topCenter,
      showProgressBar: showProgressBar,
      closeOnClick: true,
      icon: isError ? Icon(Icons.cancel_rounded) : Icon(Icons.check_circle_rounded),
      title: Text(title),
      description: description,
      autoCloseDuration: Duration(seconds: autoCloseDuration),
    );
  }

  void _playSoundIfNeeded() {
    if (playSound) {
      for (int k = 0; k < playTimes; k++) {
        if (k == 0) {
          playReviewSound();
        } else {
          Future.delayed(Duration(seconds: 3), () => playReviewSound());
        }
      }
    }
  }

  void playReviewSound() {
    try {
      final assetsAudioPlayer = AssetsAudioPlayer();
      assetsAudioPlayer.open(
        Audio("audio/review.mp3"),
      );
    } catch (e) {
      print("Play Sound Error: ${e}");
    }
  }
}

class CustomFailedToast extends CustomToastification {
  CustomFailedToast({required String title, String? description, int? duration})
      : super(
    title: title,
    description: description != null ? Text(description) : null,
    isError: true,
    playSound: true,
    playTimes: 2,
    autoCloseDuration: duration ?? 4
  );
}

class CustomSuccessToast extends CustomToastification {
  CustomSuccessToast({required String title, String? description, int? duration})
      : super(
      title: title,
      description: description != null ? Text(description) : null,
      playSound: true,
      playTimes: 2,
      autoCloseDuration: duration ?? 4
  );
}

// Usage
// FailedPrintKitchenToast().showToast();
// PlaceOrderFailedToast("Order could not be placed due to network issues").showToast();
