import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lan_scanner/lan_scanner.dart';
import 'package:location/location.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:optimy_second_device/main.dart';
import 'package:optimy_second_device/page/progress_bar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../notifier/theme_color.dart';
import '../page/loading.dart';
import '../page/login.dart';
import '../translation/AppLocalizations.dart';

class ServerIpDialog extends StatefulWidget {
  const ServerIpDialog({Key? key}) : super(key: key);

  @override
  State<ServerIpDialog> createState() => _ServerIpDialogState();
}

class _ServerIpDialogState extends State<ServerIpDialog> {
  late SharedPreferences prefs;
  bool isLoaded = false;

  @override
  void initState() {
    // TODO: implement initState
    getPreferences();
    super.initState();
  }

  getPreferences() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return PopScope(
        canPop: false,
        child: LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return AlertDialog(
                title: Row(
                  children: [
                    Text(AppLocalizations.of(context)!.translate("connect_server_device")),
                    Spacer(),
                    IconButton(
                        onPressed: () async {
                          await logout();
                        },
                        color: Colors.red,
                        icon: Icon(Icons.logout))
                  ],
                ),
                content: isLoaded ?
                SizedBox(
                  width: 500,
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!Platform.isIOS)
                          TabBar(
                            isScrollable: false,
                            unselectedLabelColor: Colors.black,
                            labelColor: color.buttonColor,
                            indicatorColor: color.buttonColor,
                            indicatorSize: TabBarIndicatorSize.tab,
                            tabs: [Tab(icon: Icon(Icons.keyboard_alt_outlined)), Tab(icon: Icon(Icons.radar_outlined))],
                          ),
                        SizedBox(height: 15),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: TabBarView(
                              physics: NeverScrollableScrollPhysics(),
                              children: [
                                TypeIpView(prefs: prefs),
                                ScanIpView(isMobile: false),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ) : CustomProgressBar()
            );
          } else {
            return AlertDialog(
              title: Row(
                children: [
                  Text(AppLocalizations.of(context)!.translate("connect_server_device")),
                ],
              ),
              content: isLoaded ?
              SizedBox(
                height: 300,
                width: 500,
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!Platform.isIOS) // Check if platform is not iOS
                        TabBar(
                          isScrollable: false,
                          unselectedLabelColor: Colors.black,
                          labelColor: color.buttonColor,
                          indicatorColor: color.buttonColor,
                          indicatorSize: TabBarIndicatorSize.tab,
                          tabs: [Tab(icon: Icon(Icons.keyboard_alt_outlined)), Tab(icon: Icon(Icons.radar_outlined))],
                        ),
                      SizedBox(height: 15),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: TabBarView(
                            physics: NeverScrollableScrollPhysics(),
                            children: [
                              TypeIpView(prefs: prefs),
                              ScanIpView(isMobile: true),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ) : CustomProgressBar(),
              actions: [
                ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: logout,
                    icon: Icon(Icons.logout),
                    label: Text(AppLocalizations.of(context)!.translate("logout")))
              ],
            );
          }
        }),
      );
    });
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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
    deleteDirectory();
    displayManager.transferDataToPresentation("refresh_img");
    //deleteFile2();
    Navigator.of(context).pushAndRemoveUntil(
      // the new route
      MaterialPageRoute(
        builder: (BuildContext context) => LoginPage(),
      ),
      (Route route) => false,
    );
  }
}

class TypeIpView extends StatefulWidget {
  final SharedPreferences prefs;
  const TypeIpView({Key? key, required this.prefs}) : super(key: key);

  @override
  State<TypeIpView> createState() => _TypeIpViewState();
}

class _TypeIpViewState extends State<TypeIpView> {
  final ipTextController = TextEditingController();
  late SharedPreferences prefs;
  bool isSubmitted = false, waitingResponse = false;

  @override
  void initState() {
    // TODO: implement initState
    prefs = widget.prefs;
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    // print("dispose called!!!");
    ipTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var color = context.watch<ThemeColor>();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.translate('server_device_ip'),
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
          ),
          SizedBox(height: 10),
          ValueListenableBuilder(
            valueListenable: ipTextController,
            builder: (context, value, __) {
              return TextField(
                autofocus: true,
                enabled: waitingResponse ? false : true,
                controller: ipTextController,
                keyboardType: TextInputType.numberWithOptions(),
                onSubmitted: _onSubmitted,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderSide: BorderSide(color: color.backgroundColor)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: color.backgroundColor),
                  ),
                  hintText: AppLocalizations.of(context)!.translate("enter_server_ip"),
                ),
              );
            },
          ),
          Visibility(
              visible: prefs.getString('server_ip') != null ? true : false,
              child: ListTile(
                contentPadding: EdgeInsets.only(left: 10, right: 10),
                title: Text("${prefs.getString('server_ip')}", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                trailing: TextButton(
                    onPressed: () {
                      ipTextController.text = prefs.getString('server_ip')!;
                    },
                    child: Text(AppLocalizations.of(context)!.translate("add"), style: TextStyle(fontWeight: FontWeight.bold))),
              )
          ),
          SizedBox(height: 5),
          ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: color.backgroundColor
              ),
              icon: Icon(Icons.wifi),
              onPressed: waitingResponse ? null : _onPressed,
              label: Text(AppLocalizations.of(context)!.translate("connect")))
        ],
      ),
    );
  }

  receivedResponse() async {
    await Future.delayed(Duration(seconds: 3), () {
      setState(() {
        waitingResponse = false;
      });
    });
  }

  String? get errorIp {
    final text = ipTextController.value.text;
    if (text.isEmpty) {
      return 'ip_required';
    }
    return null;
  }

  _onSubmitted(String value) async {
    if (ipTextController.text.trim().isNotEmpty) {
      setState(() {
        isSubmitted = true;
        waitingResponse = true;
        FocusManager.instance.primaryFocus?.unfocus();
      });
      if (errorIp == null) {
        await clientAction.connectServer(ipTextController.text, callback: checkStatus);
      }
    } else {
      Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate("ip_required"), backgroundColor: Colors.red);
    }
  }

  _onPressed() async {
    if (ipTextController.text.trim().isNotEmpty) {
      setState(() {
        isSubmitted = true;
        waitingResponse = true;
        FocusManager.instance.primaryFocus?.unfocus();
      });
      if (errorIp == null) {
        await clientAction.connectServer(ipTextController.text, callback: checkStatus);
      }
    } else {
      Fluttertoast.showToast(msg: AppLocalizations.of(context)!.translate("ip_required"), backgroundColor: Colors.red);
    }
  }

  void checkStatus(response) async {
    var json = jsonDecode(response);
    print('status: ${json['status']}');
    switch (json['status']) {
      case '0':
        {
          await receivedResponse();
          if(mounted){
            Fluttertoast.showToast(backgroundColor: Colors.redAccent, msg: AppLocalizations.of(context)!.translate("network_connection_failed"));
          }
        }
        break;
      case '1':
        {
          print("case 1 called!!!");
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoadingPage()));
          prefs.setString('server_ip', ipTextController.text);
        }
        break;
      case '2':
        {
          await logout();
        }
        break;
      default:
        {
          await receivedResponse();
          Fluttertoast.showToast(backgroundColor: Colors.redAccent, msg: "Request action not found, Please check server POS version");
        }
    }
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

  logout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
    deleteDirectory();
    displayManager.transferDataToPresentation("refresh_img");
    //deleteFile2();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
  }
}

class ScanIpView extends StatefulWidget {
  final bool isMobile;

  const ScanIpView({Key? key, required this.isMobile}) : super(key: key);

  @override
  State<ScanIpView> createState() => _ScanIpViewState();
}

class _ScanIpViewState extends State<ScanIpView> {
  StreamController streamController = StreamController();
  final ScrollController scrollController = ScrollController();
  late Stream serverIpStream;
  late Map branchObject;
  List<String> ips = [];
  Text? info;
  String getIPType = "type";
  double percentage = 0.0;
  bool isLoad = false;

  @override
  void initState() {
    // TODO: implement initState
    FocusManager.instance.primaryFocus?.unfocus();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    streamController.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var color = context.watch<ThemeColor>();
    return StreamBuilder(
        stream: streamController.stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data == 'done') {
              return Center(
                child: widget.isMobile
                    ? RefreshIndicator(
                        onRefresh: checkPermission,
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
                                padding: EdgeInsets.only(left: 10.0, right: 10.0),
                                shrinkWrap: true,
                                itemCount: ips.length,
                                itemBuilder: (context, index) {
                                  return Card(
                                    elevation: 5,
                                    child: ListTile(
                                      onTap: () async {
                                        await clientAction.connectServer(ips[index], callback: checkStatus);
                                      },
                                      leading: Icon(
                                        Icons.wifi,
                                        color: Colors.black45,
                                      ),
                                      title: Text(ips[index]),
                                    ),
                                  );
                                }),
                          ),
                        ),
                      )
                    : MediaQuery.removePadding(
                        context: context,
                        removeTop: true,
                        child: Scrollbar(
                            controller: scrollController,
                            thickness: 5.0,
                            trackVisibility: true,
                            thumbVisibility: true,
                            radius: Radius.circular(20.0),
                            child: Stack(
                              children: [
                                ListView.builder(
                                    controller: scrollController,
                                    padding: EdgeInsets.only(left: 10.0, right: 10.0),
                                    shrinkWrap: true,
                                    itemCount: ips.length,
                                    itemBuilder: (context, index) {
                                      return Card(
                                        elevation: 5,
                                        child: ListTile(
                                          onTap: () async {
                                            await clientAction.connectServer(ips[index], callback: checkStatus);
                                          },
                                          leading: Icon(
                                            Icons.wifi,
                                            color: Colors.black45,
                                          ),
                                          title: Text(ips[index]),
                                        ),
                                      );
                                    }),
                                Container(
                                  alignment: Alignment.bottomRight,
                                  padding: EdgeInsets.all(15),
                                  child: FloatingActionButton(
                                    onPressed: () async {
                                      streamController.add("scanning");
                                      await checkPermission();
                                    },
                                    child: Icon(Icons.radar),
                                  ),
                                )
                              ],
                            )),
                      ),
              );
            } else {
              return CircularPercentIndicator(
                  addAutomaticKeepAlive: false,
                  footer: Container(margin: EdgeInsets.only(top: 10), child: info),
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
                  progressColor: color.backgroundColor);
            }
          } else {
            return Center(
              child: widget.isMobile
                  ? ElevatedButton.icon(
                      onPressed: () async {
                        // streamController.add("scanning");
                        await checkPermission();
                      },
                      label: Text(AppLocalizations.of(context)!.translate("start_scan")),
                      icon: Icon(Icons.radar),
                    )
                  : SizedBox(
                      width: MediaQuery.of(context).size.width / 4,
                      height: MediaQuery.of(context).size.height / 12,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await checkPermission();
                        },
                        label: Text(AppLocalizations.of(context)!.translate("start_scan")),
                        icon: Icon(Icons.radar),
                      ),
                    ),
            );
          }
        });
  }

  Future<void> checkPermission() async {
    streamController.add("scanning");
    percentage = 0.0;
    Location location = Location();
    //check location permission is granted or not
    var permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        Navigator.of(context).pop();
      } else {
        //check location is on or not
        var _locationOn = await location.serviceEnabled();
        if (!_locationOn) {
          _locationOn = await location.requestService();
          if (!_locationOn) {
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
      if (!_locationOn) {
        _locationOn = await location.requestService();
        if (!_locationOn) {
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
    print("scan network called!!!");
    final scanner = LanScanner();
    ips = [];

    var wifiIP = await NetworkInfo().getWifiIP();
    var wifiName = await NetworkInfo().getWifiName();

    var subnet = ipToCSubnet(wifiIP!);

    final stream = scanner.icmpScan(subnet, progressCallback: (progress) {
      if (mounted) {
        setState(() {
          if (wifiName != null) {
            info = Text('${AppLocalizations.of(context)!.translate('scanning_device_within')} $wifiName');
          } else {
            info = Text(AppLocalizations.of(context)!.translate('scanning'));
          }
          percentage = progress;
          if (percentage == 1.0) {
            streamController.sink.add("done");
            // isLoad = true;
          }
        });
      }
    });

    stream.listen((Host host) {
      ips.add(host.internetAddress.address);
    });
  }

  checkStatus(response) async {
    var json = jsonDecode(response);
    print('status: ${json['status']}');
    switch (json['status']) {
      case '0':
        {
          Fluttertoast.showToast(backgroundColor: Colors.redAccent, msg: "Connection failed, Please check internet connection");
        }
        break;
      case '1':
        {
          print("case 1 called!!!");
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoadingPage()));
        }
        break;
      case '2':
        {
          await logout();
        }
        break;
      default:
        {
          Fluttertoast.showToast(backgroundColor: Colors.redAccent, msg: "Request action not found, Please check server POS version");
        }
    }
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

  logout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
    deleteDirectory();
    displayManager.transferDataToPresentation("refresh_img");
    //deleteFile2();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
  }
}
