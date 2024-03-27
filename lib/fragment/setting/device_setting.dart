import 'package:flutter/material.dart';
import 'package:optimy_second_device/object/client_action.dart';
import 'package:optimy_second_device/page/loading.dart';

class DeviceSetting extends StatefulWidget {
  const DeviceSetting({Key? key}) : super(key: key);

  @override
  State<DeviceSetting> createState() => _DeviceSettingState();
}

class _DeviceSettingState extends State<DeviceSetting> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
          children: [
            ListTile(
              title: Text("Server socket ip: ${ClientAction.instance.deviceIp}"),
              onTap: () async{
                //await ClientAction.instance.bindServer();
              },
            ),
            Divider(
              color: Colors.grey,
              height: 1,
              thickness: 1,
              indent: 20,
              endIndent: 20,
            ),
            ListTile(
              title: Text("Sync data"),
              onTap: () async{
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (BuildContext context) => LoadingPage(),
                  ),
                      (Route route) => false,
                );
              },
            ),
          ],
        )
    );
  }
}
