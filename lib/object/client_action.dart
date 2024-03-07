import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:optimy_second_device/main.dart';
import 'package:optimy_second_device/object/cart_product.dart';

class ClientAction{
  static final ClientAction instance = ClientAction.init();
  late Socket socket;
  late Socket requestSocket;
  late String? serverIp;
  String? response;
  bool status = false, loading = false;
  static const messageDelimiter = '\n';
  Timer? timer;

  ClientAction.init();

  connectServer(String ips) async {
    try{
      int i = 0;
      Map<String, dynamic>? result;
      final buffer = StringBuffer();

      socket = await Socket.connect(ips, 9999, timeout: const Duration(seconds: 3));
      serverIp = ips;
      //send first request to server side
      result = {'action': '1', 'param': ''};
      socket.write('${jsonEncode(result)}\n');

      //socket stream listen for data
      socket.listen( (data) {
        print("data chunk received: ${i+1}");
        // Track the received data
        String receivedData = utf8.decode(data);
        print("received data: ${receivedData}");
        if(receivedData == 'refresh'){
          showRefresh();
          return;
        }
        buffer.write(receivedData);
        //split request call every 1 sec
        splitRequest(buffer: buffer, serverSocket: socket, response: response);
      },onError: (err){
        print('listen error: $err');
        timer?.cancel();
        socket.destroy();
        notificationModel.enableReconnectDialog();
        throw "listen error";
      },onDone: (){
        print('client done');
        timer?.cancel();
        socket.destroy();
        notificationModel.enableReconnectDialog();
      });

      return true;

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
      print('connect error2: $e');
      return false;
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

  splitRequest({required StringBuffer buffer, required Socket serverSocket, response}) {
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
      processData(message: firstRequest, serverSocket: serverSocket);
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

  processData({required Socket serverSocket, message}){
    print("process data message: ${message}");
    if (message != '') {
      response = message;
      Future.delayed(const Duration(milliseconds: 1000), () {
        //decodeAction.checkAction();
        var json = jsonDecode(response!);
        if(json['action'] == '0'){
          return decodeAction.checkAction();
        }
        decodeAction.decodeAllFunction();
      });
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
      print("request port called!");
      Map<String, dynamic>? result;
      if(param != null){
        result = {'action': action, 'param': param};
      } else {
        result = {'action': action, 'param': ''};
      }
      requestSocket = await Socket.connect(serverIp, 8888, timeout: const Duration(seconds: 3));
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
      await streamSubscription.asFuture<void>();
    } catch(e) {
      print("connect request port error: $e");
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