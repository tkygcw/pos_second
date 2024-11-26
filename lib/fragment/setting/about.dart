import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optimy_second_device/notifier/cart_notifier.dart';
import 'package:optimy_second_device/object/subscription.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../translation/AppLocalizations.dart';

class About extends StatefulWidget {
  const About({Key? key}) : super(key: key);

  @override
  State<About> createState() => _AboutState();
}

class _AboutState extends State<About> {
  late CartModel cart;
  String subscriptionEndDate = '', appVersion = '';
  int daysLeft = 0;
  List<Subscription> subscriptionData = decodeAction.decodedSubscription!;

  @override
  void initState() {
    // preload();
    cart = context.read<CartModel>();
    preload();
    super.initState();
  }

  preload() async {
    await getAppVersion();
    await getSubscriptionDate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar:  MediaQuery.of(context).orientation == Orientation.portrait ? AppBar(
          elevation: 1,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.blueGrey),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          backgroundColor: Colors.white,
          title: Text(AppLocalizations.of(context)!.translate('about'),
              style: TextStyle(fontSize: 20, color: Colors.blueGrey)),
          centerTitle: false,
        )
            : null,
        body: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: [
              Card(
                color: daysLeft < 7 ? Colors.red : Colors.green,
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Optimy Pos License v$appVersionCode',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${AppLocalizations.of(context)!.translate('active_until')} $subscriptionEndDate',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  trailing: Text('$daysLeft ${AppLocalizations.of(context)!.translate('days')}',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20
                      )
                  ),
                ),
              ),
            ],
          ),
        )
    );
  }

  getSubscriptionDate() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd");
    if(subscriptionData.isNotEmpty) {
      DateTime subscriptionEnd = dateFormat.parse(subscriptionData.first.end_date!);
      Duration difference = subscriptionEnd.difference(DateTime.now());
      setState(() {
        subscriptionEndDate = DateFormat("dd/MM/yyyy").format(subscriptionEnd);
        daysLeft = difference.inDays +1;
      });
    }
  }

  getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = "v${packageInfo.version}";
    });
  }
}
