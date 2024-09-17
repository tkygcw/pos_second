import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/setting/about.dart';
import 'package:optimy_second_device/main.dart';
import 'package:optimy_second_device/page/home.dart';
import 'package:provider/provider.dart';
import 'package:side_navigation/side_navigation.dart';

import '../../notifier/theme_color.dart';
import '../../page/pos_pin.dart';
import '../../page/progress_bar.dart';
import '../../translation/AppLocalizations.dart';
import 'device_setting.dart';

class SettingMenu extends StatefulWidget {
  const SettingMenu({Key? key}) : super(key: key);

  @override
  State<SettingMenu> createState() => _SettingMenuState();
}

class _SettingMenuState extends State<SettingMenu> {
  bool isLoaded = false;
  List<Widget> views = [];
  int selectedIndex = 0;

  @override
  void initState() {
    // TODO: implement initState
    getView();
    super.initState();
  }

  getView(){
    views = [
      DeviceSetting(),
      About()
    ];
    setState(() {
      isLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return LayoutBuilder(builder: (context,  constraints) {
        if(constraints.maxWidth > 900 && constraints.maxHeight > 500){
          return Padding(
            padding: EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: this.isLoaded ?
            Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                automaticallyImplyLeading: false,
                leading: isLandscapeOrien() ? null : IconButton(
                  icon: Icon(Icons.menu, color: color.buttonColor),
                  onPressed: () {
                    isCollapsedNotifier.value = !isCollapsedNotifier.value;
                  },
                ),
                title: Text(AppLocalizations.of(context)!.translate('setting'),
                    style: TextStyle(fontSize: 25, color: Colors.black)),
                backgroundColor: Color(0xffFAFAFA),
                elevation: 0,
              ),
              body: Row(
                children: [
                  /// Pretty similar to the BottomNavigationBar!
                  SideNavigationBar(
                    expandable: false,
                    footer: SideNavigationBarFooter(
                        label: Column(
                          children: [
                            Text("IP: ${clientAction.deviceIp}"),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color.backgroundColor,
                              ),
                              onPressed: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (BuildContext context) => PosPinPage(),
                                  ),
                                      (Route route) => false,
                                );
                              },
                              icon: Icon(Icons.dialpad),
                              label: Text(AppLocalizations.of(context)!.translate('back_to_pos_pin')),
                            ),
                          ],
                        )),
                    theme: SideNavigationBarTheme(
                      backgroundColor: Colors.white,
                      togglerTheme: SideNavigationBarTogglerTheme.standard(),
                      itemTheme: SideNavigationBarItemTheme(
                        selectedItemColor: color.backgroundColor,
                      ),
                      dividerTheme: SideNavigationBarDividerTheme.standard(),
                    ),
                    selectedIndex: selectedIndex,
                    items: [
                      SideNavigationBarItem(
                        icon: Icons.devices_other,
                        label: AppLocalizations.of(context)!.translate("device_setting"),
                      ),
                      SideNavigationBarItem(
                        icon: Icons.info,
                        label: AppLocalizations.of(context)!.translate("about"),
                      ),
                    ],
                    onTap: (index) {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                  ),
                  /// Make it take the rest of the available width
                  Expanded(
                    child: views.elementAt(selectedIndex),
                  )
                ],
              ),
            ) : CustomProgressBar(),
          );
        } else {
          ///mobile layout
          return MediaQuery.of(context).orientation == Orientation.landscape ? Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 8, 15),
            child: this.isLoaded ?
            Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                automaticallyImplyLeading: false,
                leading: isLandscapeOrien() ? null : IconButton(
                  icon: Icon(Icons.menu, color: color.buttonColor),
                  onPressed: () {
                    isCollapsedNotifier.value = !isCollapsedNotifier.value;
                  },
                ),
                title: Text(AppLocalizations.of(context)!.translate('setting'),
                    style: TextStyle(fontSize: 25, color: Colors.black)),
                backgroundColor: Color(0xffFAFAFA),
                elevation: 0,
              ),
              body: Row(
                children: [
                  /// Pretty similar to the BottomNavigationBar!
                  Expanded(
                    flex: 2,
                    child: SideNavigationBar(
                      expandable: false,
                      footer: SideNavigationBarFooter(
                          label: Column(
                            children: [
                              Text("IP: ${clientAction.deviceIp}"),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color.backgroundColor,
                                ),
                                onPressed: () async {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (BuildContext context) => PosPinPage(),
                                    ),
                                        (Route route) => false,
                                  );

                                },
                                child: Text(AppLocalizations.of(context)!.translate('back_to_pos_pin')),
                              ),
                            ],
                          )),
                      theme: SideNavigationBarTheme(
                        backgroundColor: Colors.white,
                        togglerTheme: SideNavigationBarTogglerTheme.standard(),
                        itemTheme: SideNavigationBarItemTheme(
                          selectedItemColor: color.backgroundColor,
                        ),
                        dividerTheme: SideNavigationBarDividerTheme.standard(),
                      ),
                      selectedIndex: selectedIndex,
                      items: [
                        SideNavigationBarItem(
                          icon: Icons.devices_other,
                          label: AppLocalizations.of(context)!.translate("device_setting"),
                        ),
                        SideNavigationBarItem(
                          icon: Icons.info,
                          label: AppLocalizations.of(context)!.translate("about"),
                        ),
                      ],
                      onTap: (index) {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                    ),
                  ),

                  /// Make it take the rest of the available width
                  Expanded(
                    flex: 3,
                    child: views.elementAt(selectedIndex),
                  )
                ],
              ),
            ) : CustomProgressBar(),
          ) :
        Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 8, 15),
            child: this.isLoaded ?
            Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                automaticallyImplyLeading: false,
                leading: IconButton(
                  icon: Icon(Icons.menu, color: color.buttonColor),
                  onPressed: () {
                    isCollapsedNotifier.value = !isCollapsedNotifier.value;
                  },
                ),
                title: Text(AppLocalizations.of(context)!.translate('setting'),
                    style: TextStyle(fontSize: 20, color: color.backgroundColor)),
                centerTitle: false,
                backgroundColor: Color(0xffFAFAFA),
                elevation: 1,
              ),
              body: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.devices_other),
                    title: Text(AppLocalizations.of(context)!.translate("device_setting")),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => views.elementAt(0),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.info),
                    title: Text(AppLocalizations.of(context)!.translate("about")),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => views.elementAt(1),
                        ),
                      );
                    },
                  ),
                ],
              ),
                bottomNavigationBar: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text("IP: ${clientAction.deviceIp}"),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color.backgroundColor,
                      ),
                      onPressed: () async {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (BuildContext context) => PosPinPage(),
                          ),
                              (Route route) => false,
                        );

                      },
                      child: Text(AppLocalizations.of(context)!.translate('back_to_pos_pin')),
                    ),

                  ],
                )
            ) : CustomProgressBar(),
          );
        }
      });
    });
  }

  bool isLandscapeOrien() {
    try {
      if(MediaQuery.of(context).orientation == Orientation.landscape) {
        return true;
      } else {
        return false;
      }
    } catch(e) {
      print("isLandscapeOrien error: $e");
      return false;
    }
  }
}
