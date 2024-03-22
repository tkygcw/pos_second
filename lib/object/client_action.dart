import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:optimy_second_device/main.dart';
import 'package:path_provider/path_provider.dart';
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

  ClientAction.init();

  get deviceIp  => _deviceIp;

  Future<String?> getDeviceIp() async {
    _deviceIp = await networkInfo.getWifiIP();
    return _deviceIp;
  }

  connectServer(String ips, String branchId, {Function? callback}) async {
    notificationModel.showReconnectDialog = false;
    int i = 0;
    Map<String, dynamic>? result;
    final buffer = StringBuffer();
    serverCallBack = callback;
    try{
      socket = await Socket.connect(ips, 9999, timeout: const Duration(seconds: 3));
    }catch(e){
      print('connect server error: $e');
      Map<String, dynamic> result = {'status': '0'};
      serverCallBack!(jsonEncode(result));
      return;
    }
    try{
      serverIp = ips;
      //send first request to server side
      result = {'action': '-1', 'param': branchId};
      socket.write('${jsonEncode(result)}\n');

      //socket stream listen for data
      socket.listen( (data) async  {
        //print("data chunk received: ${i+1}");
        // Track the received data
        String receivedData = utf8.decode(data);
        print("received data: ${receivedData}");
        if(receivedData == 'refresh'){
          showRefresh();
          return;
        }
        buffer.write(receivedData);
        final messages = buffer.toString().split('\n');
        String firstRequest = messages[0];
        for(int i = 0; i < messages.length; i++){
          if(i != 0){
            buffer.clear();
            buffer.write(messages[i]);
          }
        }
        processData(message: firstRequest);
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
      // Socket.connect(ips, 9999, timeout: const Duration(seconds: 3)).then((socket) {
      //   connectStatus = true;
      //   print('client connected : ${socket.remoteAddress.address}:${socket.remotePort}');
      //   this.socket = socket;
      //   serverIp = ips;
      //   result = {'action': '1', 'param': ''};
      //   socket.write('${jsonEncode(result)}\n');
      //
      //   //List<int> receivedData = [];
      //   final buffer = StringBuffer();
      //   splitRequest(buffer: buffer, serverSocket: socket, response: response);
      //
      //   socket.listen( (data) {
      //     /// Track the received data
      //     String receivedData = utf8.decode(data);
      //     buffer.write(receivedData);
      //     // if(buffer.toString() != ''){
      //     //   qrOrderController.sink.add("rebuild");
      //     // }
      //
      //     // if (receivedData.endsWith(messageDelimiter)) {
      //     //   final messages = buffer.toString().split('\n');
      //     //   for(int i = 0; i < messages.length; i++){
      //     //     final message = messages[i];
      //     //     if(message.isNotEmpty){
      //     //       response = message;
      //     //     }
      //     //   }
      //     //   // Update the buffer with the remaining incomplete message
      //     //   buffer.clear();
      //     //   buffer.write(messages.last);
      //     // }
      //     // if (receivedData.endsWith('\n')) {
      //     //   /// Process the complete response
      //     //   //response = utf8.decode(receivedData);
      //     //   // Remove the end-of-message marker before processing the data
      //     //   receivedData = receivedData.substring(0, receivedData.length - 1);
      //     //   response = receivedData;
      //     //   print('Received response: $response');
      //     //   notificationModel.setContentLoaded();
      //     //   //reset data
      //     //   receivedData = '';
      //     // }
      //     //socket.close();
      //   },onError: (err){
      //     print('listen error: $err');
      //     //socket.destroy();
      //   },onDone: (){
      //     print('client done');
      //     timer?.cancel();
      //     socket.destroy();
      //   });
      // }).catchError((error){
      //   print("socket connect error: ${error}");
      //   connectStatus = false;
      // });
    }catch(e){
      print('connect server error2: $e');
      socket.destroy();
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
        if(json['action'] == '0'){
          return decodeAction.checkAction();
        }
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
    try{
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
        openDialog(action: action, param: param, callback: callback);
        // notificationModel.enableReconnectDialog();
        return;
      }
      print("encode request ${jsonEncode(result)}");
      requestSocket.write('${jsonEncode(result)}\n');

      final buffer = StringBuffer();
      String receivedData = '';
      //handle data
      StreamSubscription streamSubscription = requestSocket.listen((data) {
        receivedData = utf8.decode(data);
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
      notificationModel.enableReconnectDialog();
    }
  }

  Future<Future<Object?>> openDialog({required String action, String? param, Function? callback}) async {
    print("open dialog called");
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