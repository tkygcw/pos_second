import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/food/food_menu_content.dart';
import 'package:optimy_second_device/fragment/food/food_menu_content_mobile.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../notifier/theme_color.dart';
import '../../object/product.dart';
import '../../object/search_delegate.dart';
import '../../page/progress_bar.dart';
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
      if(size.height > 500){
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: FoodMenuContent(color: color),
        );
      } else {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: FoodMenuContentMobile(color: color),
        );
      }
    });
  }

}
