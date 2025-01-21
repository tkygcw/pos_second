import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:optimy_second_device/notifier/theme_color.dart';
import 'package:provider/provider.dart';

import '../../translation/AppLocalizations.dart';
import 'display_order.dart';

class OtherOrderPage extends StatefulWidget {
  const OtherOrderPage({Key? key}) : super(key: key);

  @override
  State<OtherOrderPage> createState() => _OtherOrderPageState();
}

class _OtherOrderPageState extends State<OtherOrderPage> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ThemeColor color = context.read<ThemeColor>();
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
          AppLocalizations.of(context)!.translate('table'),
          style: TextStyle(fontSize: 20, color: color.backgroundColor),
        ),
      ),
      body: DisplayOrderPage(),
    );
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
