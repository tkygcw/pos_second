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

  @override
  void initState() {
    // TODO: implement initState
    setScreenLayout();
    super.initState();
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

  setScreenLayout() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
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
              //side nav bar
              child: CollapsibleSidebar(
                  sidebarBoxShadow: [
                    BoxShadow(
                      color: Colors.transparent,
                    ),
                  ],
                  badgeBackgroundColor: Colors.red,
                  isCollapsed: true,
                  items: _items,
                  avatarImg: AssetImage("drawable/logo.png"),
                  title: "${widget.user!.name!}\n${_truncateTitle((branchName ?? ''), 17)}\n${AppLocalizations.of(context)!.translate(role.toLowerCase())}",
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
                  )),
            )),
      );
    });
  }

  String _truncateTitle(String title, int? maxLength) {
    if (title.length > maxLength!) {
      return '${title.substring(0, maxLength)}...';
    }
    return title;
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
        }),
        isSelected: true,
      ),
      CollapsibleItem(
        text: AppLocalizations.of(context)!.translate('setting'),
        icon: Icons.settings,
        onPressed: () => setState(() => currentPage = 'setting'),
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
}
