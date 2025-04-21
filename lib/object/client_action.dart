import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:optimy_second_device/main.dart';
import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fragment/reconnect_dialog.dart';
import 'branch.dart';

class ClientAction {
  final NetworkInfo networkInfo = NetworkInfo();
  static final ClientAction instance = ClientAction.init();
  late Socket socket;
  late Socket requestSocket;
  late String? serverIp;
  static String? _deviceIp;
  Function? serverCallBack;
  String? response, serverResponse;
  bool status = false, loading = false;
  static const messageDelimiter = '\n';
  Timer? timer;
  bool _isReconnectDialogOpen = false;

  ClientAction.init();

  bool get isReconnectDialogOpen => _isReconnectDialogOpen;

  get deviceIp  => _deviceIp;

  set setReconnectDialogStatus (bool value){
    _isReconnectDialogOpen = value;
  }

  Future<String?> getDeviceIp() async {
    var wifiIP= await networkInfo.getWifiIP();
    if(wifiIP == null) {
      List<NetworkInterface> interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var address in interface.addresses) {
          wifiIP = address.address;
        }
      }
    }
    _deviceIp = wifiIP;
    return _deviceIp;
  }

  Future<Map<String, dynamic>> getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    return json.decode(branch!);
  }

  void disconnectFromServer(){
    if(serverIp != '0.0.0.0'){
      socket.destroy();
    }
  }

  connectServer(String ips, {Function? callback}) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    Map<String, dynamic> branchMap = await getPreferences();
    Branch branchObject = Branch.fromJson(branchMap);
    currency_code = branchObject.currency_code ?? 'MYR';
    currency_symbol = branchObject.currency_symbol ?? 'RM';
    notificationModel.showReconnectDialog = false;
    int i = 0;
    Map<String, dynamic>? result;
    StringBuffer buffer = StringBuffer();
    String? receivedData;
    serverCallBack = callback;
    if(ips != '0.0.0.0'){
      try{
        socket = await Socket.connect(ips, 9999, timeout: const Duration(seconds: 3));
      }catch(e){
        print('connect server error: $e');
        Map<String, dynamic> result = {'status': '0', 'exception': e.toString()};
        if(serverCallBack != null){
          serverCallBack!(jsonEncode(result));
        }
        return;
      }
      serverIp = ips;
      //send first request to server side
      Map<String, dynamic> param = {
        'branch_id': branchObject.branch_id.toString(),
        'app_version': packageInfo.version
      };
      result = {'action': '-1', 'param': jsonEncode(param)};
      socket.write('${jsonEncode(result)}\n');

      //socket stream listen for data
      socket.cast<List<int>>().transform(utf8.decoder).listen( (data) async  {
        // Track the received data
        receivedData = data;
        if(receivedData != null){
          buffer.write(receivedData);
          if(receivedData!.contains(messageDelimiter)){
            final messages = buffer.toString().split('\n');
            String firstRequest = messages[0];
            for(int i = 0; i < messages.length; i++){
              if(i != 0){
                buffer.clear();
                buffer.write(messages[i]);
              }
            }
            processData(message: firstRequest);
          }
        }
        //split request call every 1 sec
        //splitRequest(buffer: buffer, serverSocket: socket);
      }, cancelOnError: true,
          onError: (err){
            print('listen error: $err');
            // timer?.cancel();
            socket.destroy();
            // openReconnectDialog(keepAlive: true);
          },onDone: (){
            print('server down');
            // timer?.cancel();
            socket.destroy();
            // openReconnectDialog(keepAlive: true);
          });
    } else {
      result = {'status': '1'};
      serverCallBack!(jsonEncode(result));
    }
  }

  showRefresh(){
    //call custom flush bar
    // Flushbar(
    //   icon: Icon(Icons.error, size: 32, color: Colors.white),
    //   shouldIconPulse: false,
    //   title: "New update from server",
    //   message: "Click to get latest data",
    //   duration: null,
    //   backgroundColor: Colors.green,
    //   messageColor: Colors.white,
    //   flushbarPosition: FlushbarPosition.TOP,
    //   maxWidth: 350,
    //   margin: EdgeInsets.all(8),
    //   borderRadius: BorderRadius.circular(8),
    //   padding: EdgeInsets.fromLTRB(40, 20, 40, 20),
    //   onTap: (flushbar) {
    //     Map<String, dynamic>? result = {'action': '1', 'param': ''};
    //     socket.write('${jsonEncode(result)}\n');
    //     flushbar.dismiss(true);
    //   },
    //   onStatusChanged: (status) {
    //     flushbarStatus = status.toString();
    //   },
    // )
    //   .show(context);
    // Future.delayed(Duration(seconds: 3), () {
    //   print("status change: ${flushbarStatus}");
    //   if (flushbarStatus != "FlushbarStatus.IS_HIDING" && flushbarStatus != "FlushbarStatus.DISMISSED") playSound();
    // });
  }

  splitRequest({required StringBuffer buffer, required Socket serverSocket}) {
    if(loading == false && buffer.toString() != ''){
      print("if called!!!");
      loading = true;
      final messages = buffer.toString().split('\n');
      String firstRequest = messages[0];
      for(int i = 0; i < messages.length; i++){
        if(i != 0){
          buffer.clear();
          buffer.write(messages[i]);
        }
      }
      //processData(message: firstRequest, serverSocket: serverSocket);
      loading = false;
    } else {
      print("else called");
      return;
    }
  }

  processData({message}) {
    print("process data message: ${message}");
    if (message != '' && message != 'null') {
      serverResponse = message;
      var json = jsonDecode(serverResponse!);
      if(json['action'] != null){
        return decodeAction.checkAction();
      } else {
        if(serverCallBack != null){
          serverCallBack!(message);
        }
      }
    } else {
      Map<String, dynamic> result = {'status': '-1'};
      serverCallBack!(jsonEncode(result));
      // socket.destroy();
    }
  }

  bool isCompleteResponse(List<int> data) {
    // Check if the received data indicates a complete response
    // This can be based on a specific termination marker or the expected data size
    // You may need to adapt this logic based on your server's response format
    // For example, assuming the response ends with a newline character:
    return utf8.decode(data).endsWith('\n');
  }

  connectRequestPort({required String action, String? param, Function? callback}) async {
    print("request port called!");
    int retries = 3;
    notificationModel.showReconnectDialog = false;
    Map<String, dynamic>? result;
    if(param != null){
      result = {'action': action, 'param': param};
    } else {
      result = {'action': action, 'param': ''};
    }
    if(serverIp != '0.0.0.0'){
      while(retries > 0){
        try{
          requestSocket = await Socket.connect(serverIp, 8888, timeout: const Duration(seconds: 3));
        }catch(e){
          print("connect request port error: $e");
          retries = 0;
          if(callback != null){
            result = {'status': '0', 'action': action, 'param': param};
            callback(jsonEncode(result));
          }
          return;
        }
        try{
          final buffer = StringBuffer();
          String receivedData = '';
          requestSocket.write('${jsonEncode(result)}\n');
          //handle data
          StreamSubscription streamSubscription = requestSocket.cast<List<int>>().transform(utf8.decoder).listen((data) {
            receivedData = data;
            buffer.write(receivedData);
            if (receivedData.endsWith(messageDelimiter)) {
              final messages = buffer.toString().trim();
              print("message: ${messages}");
              response = messages;
              if(callback != null){
                callback(response);
              }

              receivedData = '';

              //Reset buffer
              buffer.clear();
              requestSocket.flush();
              requestSocket.destroy();
            }
          });
          await streamSubscription.asFuture<void>().timeout(Duration(seconds: getTimeoutLimit(action)));
          break;
        } catch(e) {
          print("connect request port error: $e");
          retries--;
          requestSocket.destroy();
          if(callback != null){
            result = {'status': '0', 'action': action, 'param': param};
            callback(jsonEncode(result));
          }
        }
      }
    } else {
      result = {'status': '-1'};
      callback!(jsonEncode(result));
    }
  }

  int getTimeoutLimit(String action){
    if(action == '8'){
      return 30;
    } else {
      return 5;
    }
  }

  openReconnectDialog({String? action, String? param, bool? keepAlive, Function? callback, bool? disableQuickConnect}) async {
    print("is reconnect dialog opened: ${_isReconnectDialogOpen}");
    if (_isReconnectDialogOpen == false) {
      _isReconnectDialogOpen = true;
      return showGeneralDialog(
          barrierColor: Colors.black.withOpacity(0.5),
          transitionBuilder: (context, a1, a2, widget) {
            final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
            return Transform(
              transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
              child: Opacity(
                opacity: a1.value,
                child: ReconnectDialog(
                  action: action,
                  param: param,
                  callback: callback,
                  keepAliveCall: keepAlive,
                  disableQuickConnect: disableQuickConnect,
                ),
              ),
            );
          },
          transitionDuration: Duration(milliseconds: 200),
          barrierDismissible: false,
          context: MyApp.navigatorKey.currentContext!,
          pageBuilder: (context, animation1, animation2) {
            // ignore: null_check_always_fails
            return null!;
          });
    } else if (_isReconnectDialogOpen == true && keepAlive == null){
      Navigator.of(MyApp.navigatorKey.currentContext!).pop();
      return showGeneralDialog(
          barrierColor: Colors.black.withOpacity(0.5),
          transitionBuilder: (context, a1, a2, widget) {
            final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
            return Transform(
              transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
              child: Opacity(
                opacity: a1.value,
                child: ReconnectDialog(
                  action: action,
                  param: param,
                  callback: callback,
                  keepAliveCall: keepAlive,
                ),
              ),
            );
          },
          transitionDuration: Duration(milliseconds: 200),
          barrierDismissible: false,
          context: MyApp.navigatorKey.currentContext!,
          pageBuilder: (context, animation1, animation2) {
            // ignore: null_check_always_fails
            return null!;
          });
    }
  }

  sendRequest({required String action, String? param}){
    Map<String, dynamic>? result;
    if(param != null){
      result = {'action': action, 'param': param};
    } else {
      result = {'action': action, 'param': ''};
    }
    print("result: ${jsonEncode(result)}");
    socket.write('${jsonEncode(result)}\n');
  }
}