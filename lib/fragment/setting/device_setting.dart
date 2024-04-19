import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:optimy_second_device/fragment/server_ip_dialog.dart';
import 'package:optimy_second_device/object/client_action.dart';
import 'package:optimy_second_device/page/loading.dart';
import 'package:optimy_second_device/page/login.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
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
                title: Text("Quick connect server IP"),
                subtitle: Text("Server device IP: ${ClientAction.instance.serverIp}"),
                trailing: Icon(Icons.link),
                onTap: () async {
                  await clientAction.connectServer(clientAction.serverIp!, callback: checkStatus);
                },
              ),
              Divider(
                color: Colors.grey,
                height: 1,
                thickness: 1,
                indent: 20,
                endIndent: 20,
              ),
              SizedBox(height: 10),
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
                  onTap: () async {
                    await logout();
                  },
                ),
              ),
            ],
          ),
        )
    );
  }

  checkStatus(response) async {
    var json = jsonDecode(response);
    print('status: ${json['status']}');
    switch(json['status']){
      case '1': {
        Fluttertoast.showToast(
          backgroundColor: Colors.green,
          msg: "Connect successful",
        );
      }break;
      case '2': {
        Fluttertoast.showToast(
          backgroundColor: Colors.red,
          msg: "Login credential did not match",
        );
        await logout();
      }break;
      default: {
        Fluttertoast.showToast(
          msg: json['exception'],
        );
      }
    }
  }

  logout() async{
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
    deleteDirectory();
    clientAction.disconnectFromServer();
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
