import 'package:flutter/cupertino.dart';
import 'package:presentation_displays/display.dart';

class NotificationModel extends ChangeNotifier {
  static final NotificationModel instance = NotificationModel();
  bool stopTimer = false;
  bool _notificationStatus = false;
  bool notificationStarted = false;
  bool syncCountStarted = false;
  bool contentLoad = false, contentLoaded = false;
  bool cartContentLoaded = false;
  bool showReconnectDialog = false;
  List<Display?> displays = [];
  bool hasSecondScreen = false;
  bool secondScreenEnable = true;

  bool get notificationStatus  => _notificationStatus;

  void setNotification(bool status){
    _notificationStatus = status;
    notifyListeners();
    print('notification status: ${_notificationStatus}');
  }

  void setTimer(bool status){
    stopTimer = status;
    notifyListeners();
    print('timer status: ${stopTimer}');
  }

  void resetTimer(){
    stopTimer = false;
  }

  void resetNotification({bool? listeners}){
    _notificationStatus = false;
    if(listeners != null && listeners == true){
      notifyListeners();
    }
  }

  void setNotificationAsStarted(){
    notificationStarted = true;
  }

  void setSyncCountAsStarted(){
    syncCountStarted = true;
  }

  void resetSyncCount(){
    syncCountStarted = false;
  }

  void setContentLoad(){
    contentLoad = true;
  }

  void resetContentLoad(){
    contentLoad = false;
  }

  void setContentLoaded(){
    contentLoaded = true;
    notifyListeners();
  }

  void resetContentLoaded(){
    contentLoaded = false;
  }

  void setCartContentLoaded(){
    cartContentLoaded = true;
    notifyListeners();
  }

  void resetCartContentLoaded(){
    cartContentLoaded = false;
  }

  void setHasSecondScreen(){
    hasSecondScreen = true;
  }

  void insertDisplay({value}){
    displays = value;
  }

  void disableSecondDisplay(){
    secondScreenEnable = false;
  }

  void enableSecondDisplay(){
    secondScreenEnable = true;
  }

  void enableReconnectDialog(){
    showReconnectDialog = true;
    notifyListeners();
  }


}