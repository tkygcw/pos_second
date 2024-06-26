import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:optimy_second_device/main.dart';

class ConnectivityChangeNotifier extends ChangeNotifier {
  bool _hasInternetAccess = false;
  ConnectivityChangeNotifier() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) async  {
      _hasInternetAccess = await InternetConnectionChecker().hasConnection;
      print('has internet access (listeners): ${_hasInternetAccess}');
      resultHandler(result, _hasInternetAccess);

    });
  }

  ConnectivityResult _connectivityResult = ConnectivityResult.none;
  bool _connection = false;

  ConnectivityResult get connectivity => _connectivityResult;

  bool get isConnect => _connection;

  void resultHandler(ConnectivityResult result, bool hasAccess){
    _connectivityResult = result;
    if(hasAccess == true){
      if (result == ConnectivityResult.none) {
        _connection = false;
        notificationModel.enableReconnectDialog();
      } else if (result == ConnectivityResult.mobile) {
        _connection = true;
      } else if (result == ConnectivityResult.wifi) {
        _connection = true;
      }
    } else {
      _connectivityResult = ConnectivityResult.none;
      _connection = false;
    }
    notifyListeners();
  }

  void initialLoad() async {
    ConnectivityResult connectivityResult = await (Connectivity().checkConnectivity());
    _hasInternetAccess = await InternetConnectionChecker().hasConnection;
    print('has internet access (initial): ${_hasInternetAccess}');
    resultHandler(connectivityResult, _hasInternetAccess);
  }
}
