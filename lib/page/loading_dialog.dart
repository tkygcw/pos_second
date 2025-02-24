import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifier/theme_color.dart';
import '../translation/AppLocalizations.dart';

class LoadingDialog extends StatefulWidget {
  final bool? isTableMenu;
  const LoadingDialog({Key? key, this.isTableMenu}) : super(key: key);

  @override
  State<LoadingDialog> createState() => _LoadingDialogState();
}

class _LoadingDialogState extends State<LoadingDialog> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return WillPopScope(
        onWillPop: () async => true,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(
                color: color.backgroundColor,
              ),
              Container(
                  margin: EdgeInsets.only(left: 15),
                  child: widget.isTableMenu == true ?
                  Text(AppLocalizations.of(context)!.translate('please_wait')) :
                  Text(AppLocalizations.of(context)!.translate('placing_order_please_wait') )),
            ],
          ),
        ),
      );
    });

  }
}
