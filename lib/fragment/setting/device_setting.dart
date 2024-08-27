import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:optimy_second_device/notifier/cart_notifier.dart';
import 'package:optimy_second_device/object/client_action.dart';
import 'package:optimy_second_device/page/loading.dart';
import 'package:optimy_second_device/page/login.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../../translation/AppLocalizations.dart';

class DeviceSetting extends StatefulWidget {
  const DeviceSetting({Key? key}) : super(key: key);

  @override
  State<DeviceSetting> createState() => _DeviceSettingState();
}

class _DeviceSettingState extends State<DeviceSetting> {
  late CartModel cart;

  @override
  void initState() {
    // preload();
    cart = context.read<CartModel>();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: [
              ListTile(
                title: Text(AppLocalizations.of(context)!.translate('quick_connect_server_ip'), style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                subtitle: Text("${AppLocalizations.of(context)!.translate('server_device_ip')}: ${ClientAction.instance.serverIp}"),
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
                  title: Text(AppLocalizations.of(context)!.translate('sync'), style: TextStyle(color: Colors.white)),
                  trailing: Icon(Icons.sync, color: Colors.white),
                  onTap: () {
                    cart.initialLoad();
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
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (BuildContext context) => LoginPage(),
      ),
          (Route route) => false,
    );
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
