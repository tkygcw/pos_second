
import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/table/table_view.dart';
import 'package:provider/provider.dart';

import '../../notifier/theme_color.dart';
import '../../translation/AppLocalizations.dart';

class TableMenu extends StatefulWidget {
  const TableMenu({Key? key}) : super(key: key);

  @override
  State<TableMenu> createState() => _TableMenuState();
}

class _TableMenuState extends State<TableMenu> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
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
        body: TableView(themeColor: color),
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
