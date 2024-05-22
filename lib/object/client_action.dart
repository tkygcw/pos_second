import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:optimy_second_device/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fragment/reconnect_dialog.dart';

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

  Future<Map> getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    return json.decode(branch!);
  }

  void disconnectFromServer(){
    socket.destroy();
  }

  connectServer(String ips, {Function? callback}) async {
    Map branchObject = await getPreferences();
    notificationModel.showReconnectDialog = false;
    int i = 0;
    Map<String, dynamic>? result;
    StringBuffer buffer = StringBuffer();
    String? receivedData;
    serverCallBack = callback;
    try{
      socket = await Socket.connect(ips, 9999, timeout: const Duration(seconds: 3));
    }catch(e){
      print('connect server error: $e');
      Map<String, dynamic> result = {'status': '0', 'exception': e.toString()};
      serverCallBack!(jsonEncode(result));
      return;
    }
    serverIp = ips;
    //send first request to server side
    result = {'action': '-1', 'param': branchObject['branchID'].toString()};
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
    }, cancelOnError: true
        ,onError: (err){
          print('listen error: $err');
          timer?.cancel();
          socket.destroy();
          notificationModel.enableReconnectDialog();
        },onDone: (){
          print('client done');
          timer?.cancel();
          socket.destroy();
          notificationModel.enableReconnectDialog();
        });
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
    // timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
    //   print("loading status: $loading");
    //   print("splitRequest- buffer: ${buffer.toString()}");
    //   if(loading == false && buffer.toString() != ''){
    //     print("if called!!!");
    //     loading = true;
    //     final messages = buffer.toString().split('\n');
    //     String firstRequest = messages[0];
    //     for(int i = 0; i < messages.length; i++){
    //       if(i != 0){
    //         buffer.clear();
    //         buffer.write(messages[i]);
    //       }
    //     }
    //     processData(message: firstRequest, serverSocket: serverSocket);
    //     loading = false;
    //   } else {
    //     print("else called");
    //     return;
    //   }
    // });
  }

  processData({message}) {
    print("process data message: ${message}");
    if (message != '' && message != 'null') {
      serverResponse = message;
      var json = jsonDecode(serverResponse!);
      if(json['action'] != null){
        return decodeAction.checkAction();
      } else {
        serverCallBack!(message);
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
    notificationModel.showReconnectDialog = false;
    print("request port called!");
    Map<String, dynamic>? result;
    if(param != null){
      result = {'action': action, 'param': param};
    } else {
      result = {'action': action, 'param': ''};
    }
    try{
      requestSocket = await Socket.connect(serverIp, 8888, timeout: const Duration(seconds: 3));
    }catch(e){
      print("connect request port error: $e");
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
      },
          // onDone: (){
          //   print("client done");
          //   socket.destroy();
          // },
          // onError: (error){
          //   print("connection error");
          //   socket.destroy();
          // },
      );
      await streamSubscription.asFuture<void>().timeout(Duration(seconds: 5));
    } catch(e) {
      print("connect request port error: $e");
      requestSocket.destroy();
      if(callback != null){
        result = {'status': '0', 'action': action, 'param': param};
        callback(jsonEncode(result));
      }
    }
  }

  Future<Future<Object?>> openReconnectDialog({String? action, String? param, Function? callback}) async {
    print("is reconnect dialog opened: ${_isReconnectDialogOpen}");
    if (!_isReconnectDialogOpen) {
      _isReconnectDialogOpen = true;
    }
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