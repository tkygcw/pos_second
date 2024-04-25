import 'package:flutter/material.dart';
import 'package:optimy_second_device/notifier/app_setting_notifier.dart';
import 'package:optimy_second_device/notifier/theme_color.dart';
import 'package:provider/provider.dart';

import '../../translation/AppLocalizations.dart';

class GeneralSetting extends StatefulWidget {
  const GeneralSetting({Key? key}) : super(key: key);

  @override
  State<GeneralSetting> createState() => _GeneralSettingState();
}

class _GeneralSettingState extends State<GeneralSetting> {

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child){
      return Scaffold(
        body: SingleChildScrollView(
          child: Consumer<AppSettingModel>(builder: (context, AppSettingModel appSettingModel, child){
            return SwitchListTile(
              activeColor: color.backgroundColor,
              title: Text(AppLocalizations.of(context)!.translate('show_sku'), style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),),
              subtitle: Text(AppLocalizations.of(context)!.translate('show_sku_desc')),
              value: appSettingModel.showSKUStatus!,
              onChanged: (bool value) {
                appSettingModel.setShowSKUStatus(value);
              },
            );
          }),
        ),
      );
    });
  }
}
