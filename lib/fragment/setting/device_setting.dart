import 'package:flutter/material.dart';
import 'package:optimy_second_device/object/client_action.dart';
import 'package:optimy_second_device/page/loading.dart';
import 'package:optimy_second_device/page/pos_pin.dart';

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
              title: Text("Current device socket ip: ${ClientAction.instance.deviceIp}"),
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
              title: Text("Server device socket ip: ${ClientAction.instance.serverIp}"),
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
            Padding(
              padding: EdgeInsets.all(15),
              child: Card(
                color: Colors.green,
                child: ListTile(
                  title: Text("Sync data", style: TextStyle(color: Colors.white)),
                  trailing: Icon(Icons.sync, color: Colors.white),
                  onTap: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (BuildContext context) => LoadingPage(),
                      ),
                          (Route route) => false,
                    );
                  },
                ),
              ),
            ),
            // ListTile(
            //   trailing: Icon(Icons.sync),
            //   title: Text("Sync data"),
            //   onTap: () async{
            //     Navigator.of(context).pushAndRemoveUntil(
            //       MaterialPageRoute(
            //         builder: (BuildContext context) => LoadingPage(),
            //       ),
            //           (Route route) => false,
            //     );
            //   },
            // ),
          ],
        )
    );
  }
}
