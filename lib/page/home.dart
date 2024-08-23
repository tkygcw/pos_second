import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/reconnect_dialog.dart';
import 'package:optimy_second_device/fragment/setting/setting.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fragment/cart/cart.dart';
import '../fragment/order/order.dart';
import '../fragment/other_order/other_order.dart';
import '../fragment/table/table_page.dart';
import '../main.dart';
import '../notifier/cart_notifier.dart';
import '../notifier/theme_color.dart';
import '../object/app_setting.dart';
import '../object/user.dart';
import '../translation/AppLocalizations.dart';

ValueNotifier<bool> isCollapsedNotifier = ValueNotifier<bool>(true);

class HomePage extends StatefulWidget {
  final User? user;
  final bool isNewDay;

  const HomePage({Key? key, this.user, required this.isNewDay}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<CollapsibleItem> _items;
  late String currentPage;
  late String role;
  String? branchName;
  Timer? timer, notificationTimer;
  bool hasNotification = false, willPop = false;
  int count = 0;
  late ThemeColor themeColor;
  List<AppSetting> appSettingList = [];
  bool isCartExpanded = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // if(notificationModel.notificationStarted == false){
    //   setupFirebaseMessaging();
    // }
    setScreenLayout();
    // initSecondDisplay();
    // _items = _generateItems;
    // currentPage = 'menu';
    // getRoleName();
    // getBranchName();
    // if (widget.isNewDay) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     showDialog(
    //         barrierDismissible: false,
    //         context: context,
    //         builder: (BuildContext context) {
    //           return WillPopScope(child: CashDialog(isCashIn: true, callBack: () {}, isCashOut: false, isNewDay: true), onWillPop: () async => false);
    //           //CashDialog(isCashIn: true, callBack: (){}, isCashOut: false, isNewDay: true,);
    //         });
    //   });
    // }
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    _items = _generateItems;
    currentPage = 'menu';
    getRoleName();
    getBranchName();

    super.didChangeDependencies();
  }

  @override
  dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  initSecondDisplay() async {
    if(notificationModel.hasSecondScreen == true){
      await displayManager.showSecondaryDisplay(displayId: notificationModel.displays[1]!.displayId, routerName: "presentation");
    }
  }

  setScreenLayout() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // Future<Future<Object?>> openLogOutDialog() async {
  //   return showGeneralDialog(
  //       barrierColor: Colors.black.withOpacity(0.5),
  //       transitionBuilder: (context, a1, a2, widget) {
  //         final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
  //         return Transform(
  //           transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
  //           child: Opacity(
  //             opacity: a1.value,
  //             child: LogoutConfirmDialog(),
  //           ),
  //         );
  //       },
  //       transitionDuration: Duration(milliseconds: 200),
  //       barrierDismissible: false,
  //       context: context,
  //       pageBuilder: (context, animation1, animation2) {
  //         // ignore: null_check_always_fails
  //         return null!;
  //       });
  // }

  @override
  Widget build(BuildContext context) {
    print("home rebuild!!!");
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      this.themeColor = color;
      return PopScope(
        canPop: willPop,
        onPopInvoked: (didPop) {
          showSecondDialog(context, color);
        },
        child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: SafeArea(
              child: isLandscapeOrien() ? CollapsibleSidebar(
                  sidebarBoxShadow: [
                    BoxShadow(
                      color: Colors.transparent,
                    ),
                  ],
                  // maxWidth: 80,
                  isCollapsed: true,
                  items: _items,
                  avatarImg: AssetImage("drawable/logo.png"),
                  title: widget.user!.name! + "\n" + _truncateTitle((branchName ?? ''), 17) + "\n" + AppLocalizations.of(context)!.translate(role.toLowerCase()),
                  backgroundColor: color.backgroundColor,
                  selectedTextColor: color.iconColor,
                  textStyle: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                  titleStyle: TextStyle(fontSize: 17, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
                  toggleTitleStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  customItemOffsetX: 20,
                  selectedIconColor: color.iconColor,
                  selectedIconBox: color.buttonColor,
                  unselectedIconColor: Colors.white,
                  body: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _body(context),
                      ),
                      //cart page
                      Visibility(
                        visible: currentPage != 'product' &&
                            currentPage != 'setting' &&
                            currentPage != 'settlement' &&
                            currentPage != 'qr_order' &&
                            currentPage != 'setting' &&
                            currentPage != 'report'
                            ? true
                            : false,
                        child: Expanded(
                            flex: MediaQuery.of(context).size.height > 500 ? 1 : 2,
                            child: CartPage(
                              currentPage: currentPage,
                            )),
                      )
                    ],
                  ))
                  : Stack(
                children: [
                  _buildBody(context),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: isCollapsedNotifier,
                      builder: (context, isCollapsedNotifier, child) {
                        return SizedBox(
                          child: CollapsibleSidebar(
                            sidebarBoxShadow: [
                              BoxShadow(
                                color: Colors.transparent,
                              ),
                            ],
                            minWidth: 0,
                            isCollapsed: isCollapsedNotifier,
                            items: _items,
                            avatarImg: AssetImage("drawable/logo.png"),
                            title: widget.user!.name! + "\n" + _truncateTitle((branchName ?? ''), 20) + "\n" + AppLocalizations.of(context)!.translate(role.toLowerCase()),
                            backgroundColor: color.backgroundColor,
                            selectedTextColor: color.iconColor,
                            textStyle: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                            titleStyle: TextStyle(fontSize: 17, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
                            toggleTitleStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            customItemOffsetX: 20,
                            iconSize: 30,
                            screenPadding: 0,
                            selectedIconColor: color.iconColor,
                            selectedIconBox: color.buttonColor,
                            unselectedIconColor: Colors.white,
                            body: Container(),
                          ),
                        );
                      },
                    ))
                ],
              ),
            )),
      );
    });
  }

  Widget _buildBody(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      if (isLandscapeOrien()) {
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: _body(context),
            ),
            Visibility(
              visible: currentPage != 'product' &&
                  currentPage != 'setting' &&
                  currentPage != 'settlement' &&
                  currentPage != 'qr_order' &&
                  currentPage != 'setting' &&
                  currentPage != 'report'
                  ? true
                  : false,
              child: Expanded(
                  flex: MediaQuery.of(context).size.height > 500 ? 1 : 2,
                  child: CartPage(
                    currentPage: currentPage,
                  )),
            )
          ],
        );
      } else {
        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  flex: 1,
                  child: _body(context),
                ),
                Visibility(
                  visible: currentPage != 'product' &&
                      currentPage != 'setting' &&
                      currentPage != 'settlement' &&
                      currentPage != 'qr_order' &&
                      currentPage != 'report',
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 700),
                    curve: Curves.fastOutSlowIn,
                    height: isCartExpanded ? MediaQuery.of(context).size.height * 0.8 : 0,
                    child: isCartExpanded
                        ? Column(
                      children: [
                        Expanded(
                          child: CartPage(
                            currentPage: currentPage,
                          ),
                        ),
                      ],
                    )
                        : SizedBox.shrink(),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: SizedBox(
                height: 50,
                width: 50,
                child: FloatingActionButton(
                  backgroundColor: color.backgroundColor,
                  onPressed: () {
                    setState(() {
                      isCartExpanded = !isCartExpanded;
                    });
                  },
                  child: Icon(Icons.shopping_cart),
                ),
              ),
            ),
          ],
        );
      }
    });

  }

  Future<Future<Object?>> openDialog() async {
    print("open dialog called");
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: ReconnectDialog(),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        });
  }

  List<CollapsibleItem> get _generateItems {
    CartModel cart = Provider.of<CartModel>(context, listen: false);
    return [
      CollapsibleItem(
        text: AppLocalizations.of(context)!.translate('menu'),
        icon: Icons.add_shopping_cart,
        onPressed: () => setState(() {
          currentPage = 'menu';
          cart.initialLoad();
          isCollapsedNotifier.value = !isCollapsedNotifier.value;
        }),
        isSelected: true,
      ),
      // CollapsibleItem(
      //   text: 'Table',
      //   icon: Icons.table_restaurant,
      //   onPressed: () => setState(() => currentPage = 'table'),
      // ),
      // CollapsibleItem(
      //   text: 'Qr Order',
      //   icon: Icons.qr_code_2,
      //   onPressed: () => setState(() => currentPage = 'qr_order'),
      // ),
      // CollapsibleItem(
      //   text: 'Other Order',
      //   icon: Icons.delivery_dining,
      //   onPressed: () => setState(() => currentPage = 'other_order'),
      // ),
      CollapsibleItem(
        text: AppLocalizations.of(context)!.translate('setting'),
        icon: Icons.settings,
        onPressed: () => setState(() {
          currentPage = 'setting';
          isCollapsedNotifier.value = !isCollapsedNotifier.value;
        }),
      ),
      // CollapsibleItem(
      //   text: 'Counter',
      //   icon: Icons.point_of_sale,
      //   onPressed: () => setState(() => currentPage = 'settlement'),
      // ),
      // CollapsibleItem(
      //   text: 'Report',
      //   icon: Icons.monetization_on,
      //   onPressed: () => setState(() => currentPage = 'report'),
      // ),
      // CollapsibleItem(
      //   text: 'Product',
      //   icon: Icons.fastfood,
      //   onPressed: () => setState(() => currentPage = 'product'),
      // ),
      // CollapsibleItem(
      //   text: 'Setting',
      //   icon: Icons.settings,
      //   onPressed: () => setState(() => currentPage = 'setting'),
      // ),
    ];
  }

  Widget _body(BuildContext context) {
    switch (currentPage) {
      case 'menu':
        return OrderPage();
      // case 'product':
      //   return ProductPage();
      case 'table':
        return TablePage();
      // case 'qr_order':
      //   return QrOrderPage();
      // case 'bill':
      //   return BillPage();
      case 'other_order':
        return OtherOrderPage();
      case 'setting':
        return SettingMenu();
      // case 'report':
      //   return InitReportPage();
      // case 'settlement':
      //   return SettlementPage();
      default:
        return OrderPage();
    }
  }

  getRoleName() {
    if (widget.user?.role.toString() == "0") {
      role = 'Owner';
    } else if (widget.user!.role! == 1) {
      role = 'Cashier';
    } else if (widget.user!.role! == 2) {
      role = 'Manager';
    } else if (widget.user!.role! == 3) {
      role = 'Waiter';
    }
  }

  getBranchName() async {
    // branchName = "testing";
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    setState(() {
      branchName = branchObject['name'];
    });
    // Branch? data = await PosDatabase.instance.readBranchName(branch_id.toString());
    // setState(() {
    //   branchName = data!.name!;
    // });
    // print('branch name : $branchName');
  }

  Future showSecondDialog(BuildContext context, ThemeColor color) {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState){
            return Center(
              child: SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                child: AlertDialog(
                  title: Text(AppLocalizations.of(context)!.translate('exit_app')),
                  content: SizedBox(
                    height: 100.0,
                    width: 350.0,
                    child: Text(AppLocalizations.of(context)!.translate('are_you_sure_to_exit_app')),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: Text('${AppLocalizations.of(context)?.translate('close')}'),
                      onPressed: () {
                        willPop = false;
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: Text('${AppLocalizations.of(context)?.translate('yes')}'),
                      onPressed: () {
                        willPop = true;
                        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                      },
                    ),
                  ],
                ),
              ),
            );
          });
        }
    );
  }

  String _truncateTitle(String title, int? maxLength) {
    if (title.length > maxLength!) {
      return title.substring(0, maxLength) + '...';
    }
    return title;
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


  /*
  *
  *   handle Push notification purpose
  *
  * */
  // Future<void> setupFirebaseMessaging() async {
  //   print('setup firebase called');
  //   notificationModel.setNotificationAsStarted();
  //   // Update the iOS foreground notification presentation options to allow
  //   // heads up notifications.
  //   await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
  //     alert: true,
  //     badge: true,
  //     sound: true,
  //   );
  //
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     print('has notification');
  //     showFlutterNotification(message);
  //   });
  //
  //   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
  //     print('testing purpose on app open');
  //   });
  //
  //   FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
  //     if (message != null) {}
  //   });
  // }
  //
  // void showFlutterNotification(RemoteMessage message) async {
  //   RemoteNotification? notification = message.notification;
  //   AndroidNotification? android = message.notification?.android;
  //   if (notification != null && android != null) {
  //     /*
  //     * qr ordering come in
  //     * */
  //     if (message.data['type'] == '0') {
  //       if(qrOrder.count == 0){
  //         qrOrder.getQrOrder();
  //         manageNotificationTimer();
  //         qrOrder.count = 0;
  //       }
  //     }
  //     /*
  //     * sync request
  //     * */
  //     else {
  //       notificationModel.setNotification(true);
  //       notificationModel.setContentLoad();
  //       Fluttertoast.showToast(backgroundColor: Colors.green, msg: "Cloud db change! sync from cloud");
  //       // await SyncRecord().syncFromCloud();
  //       if(syncRecord.count == 0){
  //         await syncRecord.syncFromCloud();
  //         syncRecord.count = 0;
  //       }
  //     }
  //   }
  // }
  //
  // manageNotificationTimer() {
  //   // showSnackBar();
  //   // playSound();
  //   //cancel previous timer if new order come in
  //   if (notificationTimer != null && notificationTimer!.isActive) {
  //     notificationTimer!.cancel();
  //   }
  //   //set timer when new order come in
  //   int no = 1;
  //   notificationTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
  //     if (no <= 3) {
  //       //showSnackBar();
  //       snackBarKey.currentState!.showSnackBar(SnackBar(
  //         content: const Text('New order is received!'),
  //         backgroundColor: themeColor.backgroundColor,
  //         action: SnackBarAction(
  //           textColor: themeColor.iconColor,
  //           label: 'Check it now!',
  //           onPressed: () {
  //             if(mounted){
  //               setState(() {
  //                 currentPage = 'qr_order';
  //                 notificationTimer!.cancel();
  //               });
  //             }
  //             no = 3;
  //           },
  //         ),
  //       ));
  //       playSound();
  //     } else
  //       timer.cancel();
  //     no++;
  //   });
  // }
  //
  // showSnackBar() {
  //   snackBarKey.currentState!.showSnackBar(SnackBar(
  //     content: const Text('New order is received!'),
  //     backgroundColor: themeColor.backgroundColor,
  //     action: SnackBarAction(
  //       textColor: themeColor.iconColor,
  //       label: 'Check it now!',
  //       onPressed: () {
  //         if(mounted){
  //           setState(() {
  //             currentPage = 'qr_order';
  //             notificationTimer!.cancel();
  //           });
  //         }
  //       },
  //     ),
  //   ));
  // }
  //
  // playSound() {
  //   final assetsAudioPlayer = AssetsAudioPlayer();
  //   assetsAudioPlayer.open(
  //     Audio("audio/notification.mp3"),
  //   );
  // }
}
