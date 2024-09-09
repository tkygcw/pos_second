import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/food/food_menu_content.dart';
import 'package:optimy_second_device/fragment/food/food_menu_content_mobile.dart';
import 'package:provider/provider.dart';
import '../../notifier/theme_color.dart';
import '../../page/home.dart';
import '../../translation/AppLocalizations.dart';

class FoodMenu extends StatefulWidget {

  const FoodMenu({Key? key}) : super(key: key);

  @override
  _FoodMenuState createState() => _FoodMenuState();
}

class _FoodMenuState extends State<FoodMenu> with TickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          leading: isLandscapeOrien() ? null : IconButton(
            icon: Icon(Icons.menu, color: color.buttonColor),
            onPressed: () {
              isCollapsedNotifier.value = !isCollapsedNotifier.value;
            },
          ),
          title: Text(
            AppLocalizations.of(context)!.translate('menu'),
            style: TextStyle(fontSize: 25, color: color.backgroundColor),
          ),
        ),
        resizeToAvoidBottomInset: false,
        body: size.width > 500 && size.height > 500 ?
        FoodMenuContent(color: color):
        FoodMenuContentMobile(color: color),
      );
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
      return false;
    }
  }

}
