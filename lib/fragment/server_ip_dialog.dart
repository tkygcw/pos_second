import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lan_scanner/lan_scanner.dart';
import 'package:location/location.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:optimy_second_device/main.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';

import '../notifier/theme_color.dart';
import '../page/loading.dart';
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
  List<String> ips = [];
  Text? info;
  double percentage = 0.0;
  bool isLoad = false;

  @override
  initState() {
    super.initState();
    checkPermission();
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
      return AlertDialog(
        title: const Text('Choose main device IP'),
        content: isLoad ? SizedBox(
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
                            bool status = await clientAction.connectServer(ips[index]);
                            print('status: $status');
                            if(status == false){
                              Fluttertoast.showToast(backgroundColor: Colors.redAccent, msg: "Connection error, Please choose again");
                            } else if(widget.currentPage == "login") {
                              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoadingPage()));
                            } else {
                              Navigator.of(context).pop();
                              widget.callBack();
                            }

                            // widget.callBack(jsonEncode(ips[index]));
                            // printerModel
                            //     .addPrinter(jsonEncode(ips[index]));

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
            ))
            : CircularPercentIndicator(
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

        ],
      );
    });
  }
}
