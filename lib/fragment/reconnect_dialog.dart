import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/server_ip_dialog.dart';

import '../main.dart';

class ReconnectDialog extends StatefulWidget {
  const ReconnectDialog({Key? key}) : super(key: key);

  @override
  State<ReconnectDialog> createState() => _ReconnectDialogState();
}

class _ReconnectDialogState extends State<ReconnectDialog> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        title: const Text('Lost connection from server'),
        content: const Text('Server Connection failed. Please check your devices wireless or mobile network setting and reconnect'),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: () {
                    notificationModel.showReconnectDialog = false;
                    Navigator.of(context).pushAndRemoveUntil(
                      // the new route
                      MaterialPageRoute(
                        builder: (BuildContext context) => ServerIpDialog(callBack: () {}, currentPage: "login"),
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
                  onPressed: () async {
                    bool reconnectStatus = await clientAction.connectServer(clientAction.serverIp!);
                    if(reconnectStatus == true){
                      notificationModel.showReconnectDialog = false;
                      Navigator.of(context).pop();
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
}
