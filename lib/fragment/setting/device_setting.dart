import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/server_ip_dialog.dart';
import 'package:optimy_second_device/object/client_action.dart';
import 'package:optimy_second_device/page/loading.dart';
import 'package:optimy_second_device/page/login.dart';

import '../../translation/AppLocalizations.dart';

class DeviceSetting extends StatefulWidget {
  const DeviceSetting({Key? key}) : super(key: key);

  @override
  State<DeviceSetting> createState() => _DeviceSettingState();
}

class _DeviceSettingState extends State<DeviceSetting> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: [
              ListTile(
                title: Text("Current device IP: ${ClientAction.instance.deviceIp}"),
              ),
              Divider(
                color: Colors.grey,
                height: 1,
                thickness: 1,
                indent: 20,
                endIndent: 20,
              ),
              ListTile(
                title: Text("Server device IP: ${ClientAction.instance.serverIp}"),
              ),
              Divider(
                color: Colors.grey,
                height: 1,
                thickness: 1,
                indent: 20,
                endIndent: 20,
              ),
              Card(
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
              Card(
                color: Colors.red,
                child: ListTile(
                  title: Text(AppLocalizations.of(context)!.translate("logout"), style: TextStyle(color: Colors.white)),
                  trailing: Icon(Icons.logout, color: Colors.white),
                  onTap: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (BuildContext context) => LoginPage(),
                      ),
                          (Route route) => false,
                    );
                  },
                ),
              ),
            ],
          ),
        )
    );
  }
}
