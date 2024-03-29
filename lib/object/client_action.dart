import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:optimy_second_device/main.dart';

class ClientAction{
  late Socket socket;
  late Socket requestSocket;
  late String? serverIp;
  String? response;
  bool status = false, loading = false;
  static const messageDelimiter = '\n';
  Timer? timer;


  ClientAction({
    this.serverIp
  });

  connectServer(String ips) async  {
    try{
      Map<String, dynamic>? result;
      final buffer = StringBuffer();
      bool connectStatus = false;

      socket = await Socket.connect(ips, 9999, timeout: const Duration(seconds: 3));
      serverIp = ips;
      //send first request to server side
      result = {'action': '1', 'param': ''};
      socket.write('${jsonEncode(result)}\n');

      //split request call every 1 sec
      splitRequest(buffer: buffer, serverSocket: socket, response: response);

      //socket stream listen for data
      socket.listen( (data) {
        /// Track the received data
        String receivedData = utf8.decode(data);
        buffer.write(receivedData);
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

      return connectStatus = true;

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

  splitRequest({required StringBuffer buffer, required Socket serverSocket, response}) {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      print("buffer: ${buffer.toString()}");
      if(loading == false && buffer.toString() != ''){
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
        return;
      }
    });
  }

  processData({required Socket serverSocket, message}){
    print("message: ${message}");
    if (message != '') {
      response = message;
      Future.delayed(const Duration(milliseconds: 1000), () {
        decodeAction.checkAction();
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

  connectRequestPort({required String action, String? param}) async {
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
      StreamSubscription streamSubscription = requestSocket.listen((data) async {
        receivedData = utf8.decode(data);
        buffer.write(receivedData);
        if (receivedData.endsWith(messageDelimiter)) {
          final messages = buffer.toString().trim();
          print("message: ${messages}");
          response = messages;

          receivedData = '';

          //Reset buffer
          buffer.clear();
          requestSocket.flush();
          requestSocket.destroy();
        }

      },
          onDone: (){
            print("client done");
            socket.destroy();
          },
          onError: (error){
            print("connection error");
            socket.destroy();
          },
      );
      await streamSubscription.asFuture("true");
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