import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/food/food_menu_content.dart';
import 'package:optimy_second_device/fragment/food/food_menu_content_mobile.dart';
import 'package:provider/provider.dart';
import '../../notifier/theme_color.dart';

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
        resizeToAvoidBottomInset: false,
        body: size.height > 500 ?
        FoodMenuContent(color: color):
        FoodMenuContentMobile(color: color),
      );
    });
  }

}
