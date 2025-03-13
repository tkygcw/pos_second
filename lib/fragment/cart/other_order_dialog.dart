import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/other_order/other_order_function.dart';
import 'package:optimy_second_device/object/order_cache.dart';
import 'package:optimy_second_device/page/progress_bar.dart';
import 'package:provider/provider.dart';

import '../../notifier/cart_notifier.dart';
import '../../notifier/theme_color.dart';
import '../../object/cart_product.dart';
import '../../translation/AppLocalizations.dart';
import '../../utils/Utils.dart';
import '../toast/custom_toastification.dart';

class OtherOrderDialog extends StatefulWidget {
  const OtherOrderDialog({super.key});

  @override
  State<OtherOrderDialog> createState() => _OtherOrderDialogState();
}

class _OtherOrderDialogState extends State<OtherOrderDialog> {
  late OtherOrderFunction orderFunction;
  late CartModel cartModel;
  late Future<List<OrderCache>> orderCache;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    orderFunction = context.read<OtherOrderFunction>();
    cartModel = context.read<CartModel>();
    orderCache = orderFunction.readAllOrderCache(diningName: cartModel.selectedOption);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Select order"),
          Spacer(),
          IconButton(
            onPressed: (){
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.close),
            color: Colors.redAccent,
          )
        ],
      ),
      content: SizedBox(
        width: 500,
        child: FutureBuilder<List<OrderCache>>(
          future: orderCache,
          builder: (context, snapshot){
            if(snapshot.connectionState == ConnectionState.waiting){
              return CustomProgressBar();
            } else {
              if(snapshot.hasData){
                if(snapshot.data!.isNotEmpty){
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: orderFunction.orderCacheList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _OrderCard(orderCache: orderFunction.orderCacheList[index]);
                    },
                  );
                } else {
                  return Center(
                    child: Text("No Order"),
                  );
                }
              } else {
                return Text("Something went wrong");
              }
            }
          },
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderCache orderCache;
  const _OrderCard({super.key, required this.orderCache});

  @override
  Widget build(BuildContext context) {
    OtherOrderFunction orderFunction = context.read<OtherOrderFunction>();
    ThemeColor color = context.read<ThemeColor>();
    CartModel cart = context.read<CartModel>();
    return Card(
      elevation: 5,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.white, width: 3.0),
          borderRadius: BorderRadius.circular(4.0)),
      child: InkWell(
        onTap: () async {
          if(orderCache.custom_table_number != '' && orderCache.custom_table_number != null)
            cart.selectedTableIndex = orderCache.custom_table_number!;
          int status = await orderFunction.readAllOrderDetail(orderCache);
          if(status == 1){
            List<cartProductItem> itemList = [];
            for(var order in orderFunction.orderDetailList){
              var item = cartProductItem(
                product_sku: order.product_sku,
                product_name: order.productName,
                price: order.price,
                base_price: order.original_price,
                orderModifierDetail: order.orderModifierDetail,
                productVariantName: order.product_variant_name,
                unit: order.unit,
                quantity: num.parse(order.quantity!),
                remark: order.remark,
                refColor: Colors.black,
                first_cache_created_date_time: orderCache.created_at,
                first_cache_batch: orderCache.batch_id,
                table_use_key: orderCache.table_use_key,
                per_quantity_unit: order.per_quantity_unit,
                status: 1,
                category_id: order.product_category_id,
                order_queue: orderCache.order_queue,
              );
              itemList.add(item);
            }
            cart.selectedOption = orderCache.dining_name!;
            cart.addAllCurrentOrderCache(orderFunction.selectedOrderCache);
            cart.addAllItem(itemList);
          } else {
            CustomFailedToast(title: AppLocalizations.of(context)!.translate('order_is_in_payment')).showToast();
          }
          Navigator.of(context).pop();
        },
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
