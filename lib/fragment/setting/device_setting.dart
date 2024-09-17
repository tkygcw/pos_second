import 'dart:convert';
import 'dart:io';

import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:optimy_second_device/notifier/cart_notifier.dart';
import 'package:optimy_second_device/object/client_action.dart';
import 'package:optimy_second_device/page/loading.dart';
import 'package:optimy_second_device/page/login.dart';
import 'package:optimy_second_device/page/pos_pin.dart';
import 'package:optimy_second_device/page/progress_bar.dart';
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
  bool isLoaded = false;
  late CartModel cart;
  late SharedPreferences prefs;
  final List<String> orientationOption = [
    'auto',
    'landscape',
    'portrait'
  ];
  int? orientation = 0;

  @override
  void initState() {
    // preload();
    cart = context.read<CartModel>();
    getPrefData();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar:  MediaQuery.of(context).orientation == Orientation.portrait ? AppBar(
          elevation: 1,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.blueGrey),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          backgroundColor: Colors.white,
          title: Text(AppLocalizations.of(context)!.translate('device_setting'),
              style: TextStyle(fontSize: 20, color: Colors.blueGrey)),
          centerTitle: false,
        )
            : null,
        body: isLoaded ? SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: [
              ListTile(
                title: Text(AppLocalizations.of(context)!.translate('screen_orientation')),
                subtitle: Text(AppLocalizations.of(context)!.translate('screen_orientation_desc')),
                trailing: SizedBox(
                  width: 200,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton2(
                      isExpanded: true,
                      buttonStyleData: ButtonStyleData(
                        height: 55,
                        padding: const EdgeInsets.only(left: 14, right: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: Colors.black26,
                          ),
                        ),
                      ),
                      dropdownStyleData: DropdownStyleData(
                        maxHeight: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.shade100,
                        ),
                        scrollbarTheme: ScrollbarThemeData(
                            thickness: WidgetStateProperty.all(5),
                            mainAxisMargin: 20,
                            crossAxisMargin: 5
                        ),
                      ),
                      items: orientationOption.asMap().entries.map((orientationValue) => DropdownMenuItem<int>(
                        value: orientationValue.key,
                        child: Text(
                          AppLocalizations.of(context)!.translate(orientationValue.value),
                          overflow: TextOverflow.visible,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      )).toList(),
                      value: orientation,
                      onChanged: (int? newValue) async{
                        if (orientation != newValue) {
                          if (await confirm(
                            context,
                            title: Text('${AppLocalizations.of(context)?.translate('screen_orientation')}'),
                            content: Text('${AppLocalizations.of(context)?.translate('to_pos_pin')}'),
                            textOK: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                            textCancel: Text('${AppLocalizations.of(context)?.translate('no')}'),
                          )) {
                            orientation = newValue;
                            prefs.setInt('orientation', orientation!);
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (BuildContext context) => PosPinPage(),
                              ),
                                  (Route route) => false,
                            );
                            setState(() {

                            });
                          }
                          // actionController.sink.add("switch");
                        }
                      },
                    ),
                  ),
                ),
              ),
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
        ): CustomProgressBar()
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

  getPrefData() async {
    try {
      prefs = await SharedPreferences.getInstance();
      if(prefs.getInt('orientation') != null) {
        orientation = prefs.getInt('orientation');
      } else {
        orientation = 0;
        prefs.setInt('orientation', orientation!);
      }
      print("orientation value = $orientation");
      setState(() {
        isLoaded = true;
      });
    } catch (e) {
      orientation = 0;
      setState(() {
        isLoaded = true;
      });
    }
  }
}
