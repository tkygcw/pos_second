import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/setting/setting.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fragment/cart/cart.dart';
import '../fragment/order/order.dart';
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
    // setScreenLayout();
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
    super.dispose();
  }

  setScreenLayout() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      this.themeColor = color;
      return PopScope(
        canPop: willPop,
        onPopInvokedWithResult: (didPop, result) => showSecondDialog(context, color),
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
                  Stack(
                    children: [
                      _buildBody(context),
                        ValueListenableBuilder<bool>(
                          valueListenable: isCollapsedNotifier,
                          builder: (context, isCollapsed, child) {
                            return !isCollapsed ? GestureDetector(
                              child: Container(
                                color: Colors.black.withOpacity(0.5),
                              ),
                              onTap: () {
                                setState(() {
                                  isCollapsedNotifier.value = !isCollapsedNotifier.value;
                                });
                              },
                            ) : Container();
                          }
                        ),
                    ],
                  ),
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
      return Consumer<CartModel>(builder: (context, CartModel cart, child) {
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
                    child: Stack(
                      children: [
                        _body(context),
                        if (isCartExpanded)
                          GestureDetector(
                            child: Container(
                              color: Colors.black.withOpacity(0.5),
                            ),
                            onTap: () {
                              setState(() {
                                isCartExpanded = !isCartExpanded;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: currentPage != 'product' &&
                        currentPage != 'setting' &&
                        currentPage != 'settlement' &&
                        currentPage != 'qr_order' &&
                        currentPage != 'report',
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 0),
                      height: isCartExpanded ? MediaQuery.of(context).size.height * 0.85 : 0,
                      child: isCartExpanded
                          ? Column(
                        children: [
                          AppBar(
                            automaticallyImplyLeading: false,
                            elevation: 0,
                            centerTitle: true,
                            title: Text(
                              AppLocalizations.of(context)!.translate('cart'),
                              style: TextStyle(fontSize: 25, color: color.backgroundColor),
                            ),
                            backgroundColor: Colors.white,
                            actions: [
                              IconButton(
                                color: color.buttonColor,
                                onPressed: (){
                                  setState(() {
                                    isCartExpanded = false;
                                  });
                                },
                                icon: Icon(Icons.close),
                              )
                            ],

                          ),
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
              Visibility(
                visible: !isCartExpanded && currentPage == 'menu',
                child: Positioned(
                  bottom: 16,
                  right: 16,
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: color.backgroundColor,
                    child: IconButton(
                      tooltip: 'cart',
                      icon: Badge(
                        isLabelVisible: cart.cartNotifierItem.isEmpty ? false : true,
                        label: Text("${cart.cartNotifierItem.length}"),
                        child: const Icon(
                          Icons.shopping_cart,
                        ),
                      ),
                      color: Colors.white,
                      onPressed: () {
                        setState(() {
                          isCartExpanded = !isCartExpanded;
                          print('cart.selectedOption: ${cart.selectedOption}');
                          print('cart.selectedOptionId: ${cart.selectedOptionId}');

                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      });
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
      CollapsibleItem(
        text: AppLocalizations.of(context)!.translate('setting'),
        icon: Icons.settings,
        onPressed: () => setState(() {
          currentPage = 'setting';
          isCollapsedNotifier.value = !isCollapsedNotifier.value;
        }),
      ),
    ];
  }

  Widget _body(BuildContext context) {
    switch (currentPage) {
      case 'menu':
        return OrderPage();
      case 'setting':
        return SettingMenu();
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
    final prefs = await SharedPreferences.getInstance();
    final String? branch = prefs.getString('branch');
    Map branchObject = json.decode(branch!);
    setState(() {
      branchName = branchObject['name'];
    });
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
