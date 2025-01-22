import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/other_order/other_order_function.dart';
import 'package:optimy_second_device/notifier/theme_color.dart';
import 'package:optimy_second_device/object/order_cache.dart';
import 'package:provider/provider.dart';

import '../../translation/AppLocalizations.dart';
import '../../utils/Utils.dart';

class DisplayOrderPage extends StatefulWidget {
  const DisplayOrderPage({Key? key}) : super(key: key);

  @override
  State<DisplayOrderPage> createState() => _DisplayOrderPageState();
}

class _DisplayOrderPageState extends State<DisplayOrderPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<OtherOrderFunction>(
        builder: (context, orderFunction, child){
          return orderFunction.orderCache.isNotEmpty ? 
          ListView.builder(
            shrinkWrap: true,
            itemCount: orderFunction.orderCache.length,
            itemBuilder: (BuildContext context, int index) {
              return _OrderCard(orderCache: orderFunction.orderCache[index],);
            },
          ):
              Center(child: Text("No data"),);
    });
  }
}

class _OrderCard extends StatelessWidget {
  final OrderCache orderCache;
  const _OrderCard({super.key, required this.orderCache});

  @override
  Widget build(BuildContext context) {
    var color = context.read<ThemeColor>();
    return Card(
      elevation: 5,
      color: Colors.white,
      shape: orderCache.is_selected
          ? RoundedRectangleBorder(
          side: BorderSide(
              color: color.backgroundColor, width: 3.0),
          borderRadius: BorderRadius.circular(4.0))
          : RoundedRectangleBorder(
          side: BorderSide(color: Colors.white, width: 3.0),
          borderRadius: BorderRadius.circular(4.0)),
      child: InkWell(
        onTap: (){},
        child: Padding(
          padding: MediaQuery.of(context).orientation == Orientation.landscape || MediaQuery.of(context).size.width > 500 ? const EdgeInsets.all(16.0) : EdgeInsets.fromLTRB(0, 16, 0, 16),
          child: ListTile(
              leading:
              orderCache.dining_name == 'Take Away'
                  ? Icon(
                Icons.fastfood_sharp,
                color: color.backgroundColor,
                size: 30.0,
              )
                  : orderCache.dining_name == 'Delivery'
                  ? Icon(
                Icons.delivery_dining,
                color: color.backgroundColor,
                size: 30.0,
              )
                  : Icon(
                Icons.local_dining_sharp,
                color: color.backgroundColor,
                size: 30.0,
              ),
              trailing: Text(
                '#${orderCache.batch_id}',
                style: TextStyle(fontSize: MediaQuery.of(context).orientation == Orientation.landscape || MediaQuery.of(context).size.width > 500 ? 20 : 15),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${AppLocalizations.of(context)!.translate('order_by')}: ${orderCache.order_by!}',
                    style: TextStyle(fontSize: MediaQuery.of(context).orientation == Orientation.landscape || MediaQuery.of(context).size.width > 500 ? 14 : 13),
                  ),
                  Text('${AppLocalizations.of(context)!.translate('order_at')}: ${Utils.formatDate(orderCache.created_at!)}',
                    style: TextStyle(fontSize: MediaQuery.of(context).orientation == Orientation.landscape || MediaQuery.of(context).size.width > 500 ? 14 : 13),
                  ),
                ],
              ),
              title: Text(
                Utils.convertTo2Dec(orderCache.total_amount!,),
                style: TextStyle(fontSize: MediaQuery.of(context).orientation == Orientation.landscape || MediaQuery.of(context).size.width > 500 ? 20 : 18),
              )),
        ),
      ),
    );
  }
}


