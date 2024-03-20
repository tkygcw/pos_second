import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lan_scanner/lan_scanner.dart';
import 'package:location/location.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:optimy_second_device/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../notifier/theme_color.dart';
import '../page/loading.dart';
import '../page/login.dart';
import '../translation/AppLocalizations.dart';

class ServerIpDialog extends StatefulWidget {
  final String? currentPage;
  final Function() callBack;
  const ServerIpDialog({Key? key, required this.callBack, this.currentPage}) : super(key: key);

  @override
  State<ServerIpDialog> createState() => _ServerIpDialogState();
}

class _ServerIpDialogState extends State<ServerIpDialog> {
  final ScrollController scrollController = ScrollController();
  late Map branchObject;
  List<String> ips = [];
  Text? info;
  double percentage = 0.0;
  bool isLoad = false;

  @override
  initState() {
    super.initState();
    checkPermission();
    getPreferences();
  }

  getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    branchObject = json.decode(branch!);
  }

  checkPermission() async {
    Location location = Location();
    //check location permission is granted or not
    var permissionGranted = await location.hasPermission();
    if(permissionGranted == PermissionStatus.denied){
      permissionGranted = await location.requestPermission();
      if(permissionGranted != PermissionStatus.granted){
        Navigator.of(context).pop();
      } else {
        //check location is on or not
        var _locationOn = await location.serviceEnabled();
        if(!_locationOn){
          _locationOn = await location.requestService();
          if(!_locationOn){
            Navigator.of(context).pop();
          } else {
            await scan_network();
          }
        } else {
          await scan_network();
        }
      }
    } else {
      //check location is on or not
      var _locationOn = await location.serviceEnabled();
      if(!_locationOn){
        _locationOn = await location.requestService();
        if(!_locationOn){
          Navigator.of(context).pop();
        } else {
          await scan_network();
        }
      } else {
        await scan_network();
      }
    }
  }

  scan_network() async {
    final scanner = LanScanner();
    ips = [];

    var wifiIP = await NetworkInfo().getWifiIP();
    var wifiName = await NetworkInfo().getWifiName();

    var subnet = ipToCSubnet(wifiIP!);

    final stream = scanner.icmpScan(subnet, progressCallback: (progress) {
      if (mounted) {
        setState(() {
          info = Text('Scanning device within $wifiName');
          percentage = progress;
          if (percentage == 1.0) {
            isLoad = true;
          }
        });
      }
    });

    stream.listen((HostModel host) {
      ips.add(host.ip);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Choose main device IP'),
          content: isLoad ?
          SizedBox(
              height: 360,
              width: MediaQuery.of(context).size.width / 4,
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: Scrollbar(
                  controller: scrollController,
                  thickness: 5.0,
                  trackVisibility: true,
                  thumbVisibility: true,
                  radius: Radius.circular(20.0),
                  child: ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: ips.length,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 5,
                          child: ListTile(
                            onTap: () async  {
                              await clientAction.connectServer(ips[index], branchObject['branchID'].toString(), callback: checkStatus);
                            },
                            leading: Icon(
                              Icons.wifi,
                              color: Colors.black45,
                            ),
                            title: Text('${ips[index]}'),
                          ),
                        );
                      }),
                ),
              )) :
          CircularPercentIndicator(
              footer: Container(
                  margin: EdgeInsets.only(top: 10),
                  child: info
              ),
              circularStrokeCap: CircularStrokeCap.round,
              radius: 90.0,
              lineWidth: 10.0,
              percent: percentage,
              center: Text(
                "${(percentage * 100).toStringAsFixed(0)} %",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              progressColor: color.backgroundColor),
          actions: [
            Visibility(
              visible: !isLoad ? false : true,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.backgroundColor,
                ),
                child: Text(
                  'Rescan',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async  {
                  setState(() {
                    percentage = 0.0;
                    isLoad = false;
                  });
                  await scan_network();
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  checkStatus(response) async {
    var json = jsonDecode(response);
    print('status: ${json['status']}');
    switch(json['status']){
      case '0': {
        Fluttertoast.showToast(backgroundColor: Colors.redAccent, msg: "Connection failed, Please check internet connection");
      } break;
      case '1': {
        print("case 1 called!!!");
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoadingPage()));
      }break;
      case '2': {
        await logout();
      }break;
      default: {
        Fluttertoast.showToast(backgroundColor: Colors.redAccent, msg: "Request action not found, Please check server POS version");
      }
    }
  }

  Future<Directory> get _localDirectory async {
    final directory = await getApplicationSupportDirectory();
    final path = directory.path;
    return Directory('$path/assets');
  }

  logout() async{
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
    deleteDirectory();
    displayManager.transferDataToPresentation("refresh_img");
    //deleteFile2();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => LoginPage()));
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
