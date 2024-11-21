import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/server_ip_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../page/login.dart';

class ReconnectDialog extends StatefulWidget {
  final String? action;
  final String? param;
  final Function? callback;
  final bool? keepAliveCall;
  const ReconnectDialog({Key? key, this.action, this.param, this.keepAliveCall, this.callback}) : super(key: key);

  @override
  State<ReconnectDialog> createState() => _ReconnectDialogState();
}

class _ReconnectDialogState extends State<ReconnectDialog> {
  bool isButtonDisable = false;

  @override
  void initState() {
    clientAction.setReconnectDialogStatus = true;
    print("is dialog open in init state: ${clientAction.isReconnectDialogOpen}");
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Lost connection from server'),
        content: const Text('Server Connection failed. Please check your devices wireless or mobile network setting and reconnect'),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: isButtonDisable ? null : () {
                    clientAction.setReconnectDialogStatus = false;
                    Navigator.of(context).pushAndRemoveUntil(
                      // the new route
                      MaterialPageRoute(
                        builder: (BuildContext context) => ServerIpDialog(),
                      ),

                      // this function should return true when we're done removing routes
                      // but because we want to remove all other screens, we make it
                      // always return false
                          (Route route) => false,
                    );
                  },
                  child: const Text('Rescan server')
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                  onPressed: isButtonDisable ? null : () async {
                    setState(() {
                      isButtonDisable = true;
                    });
                    Navigator.of(context).pop();
                    if(widget.keepAliveCall == true){
                      clientAction.setReconnectDialogStatus = false;
                      await clientAction.connectServer(clientAction.serverIp!, callback: checkStatus);
                    } else {
                      clientAction.setReconnectDialogStatus = false;
                      clientAction.connectServer(clientAction.serverIp!);
                      print("pass action: ${widget.action}");
                      if(widget.action != null){
                        await clientAction.connectRequestPort(action: widget.action!, param: widget.param, callback: widget.callback);
                      } else {
                        print("else called!!!");
                        widget.callback!();
                      }
                    }
                  },
                  child: const Text('Quick connect')
              ),
            ],
          ),
        ],
      ),
    );
  }

  checkStatus(response) async {
    var json = jsonDecode(response);
    print('status: ${json['status']}');
    switch(json['status']){
      case '1': {
        print("im revive");
      }break;
      case '2': {
        await logout();
      }break;
      default: {
        clientAction.openReconnectDialog(keepAlive: true, callback: checkStatus);
      }
    }
  }

  logout() async{
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
    deleteDirectory();
    // displayManager.transferDataToPresentation("refresh_img");
    //deleteFile2();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => LoginPage()));
  }

  Future<Directory> get _localDirectory async {
    final directory = await getApplicationSupportDirectory();
    final path = directory.path;
    return Directory('$path/assets');
  }

  Future<int> deleteDirectory() async {
    try {
      final folder = await _localDirectory;
      folder.delete(recursive: true);
      print("delete successful");
      return 1;
    } catch (e) {
      print(e);
      return 0;
    }
  }
}
