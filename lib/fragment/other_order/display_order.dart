import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/other_order/other_order_function.dart';
import 'package:optimy_second_device/notifier/cart_notifier.dart';
import 'package:optimy_second_device/notifier/theme_color.dart';
import 'package:optimy_second_device/object/order_cache.dart';
import 'package:provider/provider.dart';

import '../../object/cart_product.dart';
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
    var cart = context.read<CartModel>();
    var isInCart = context.select<CartModel, bool>(
          (cart) {
        return cart.currentOrderCache.contains(orderCache);
      },
    );
    return Card(
      elevation: 5,
      color: Colors.white,
      shape: isInCart ? RoundedRectangleBorder(
          side: BorderSide(
            color: color.backgroundColor,
            width: 3.0,
          ),
          borderRadius: BorderRadius.circular(4.0))
          : RoundedRectangleBorder(
          side: BorderSide(color: Colors.white, width: 3.0),
          borderRadius: BorderRadius.circular(4.0)),
      child: InkWell(
        onTap: () async {
          OtherOrderFunction orderFunction = OtherOrderFunction.instance;
          if(isInCart){
            cart.removeSpecificCurrentOrderCache(orderCache.order_cache_sqlite_id);
            cart.removeSpecificBatchItem(orderCache.batch_id);
          } else {
            int status = await orderFunction.readAllOrderDetail(orderCache);
            if(status == 1){
              List<cartProductItem> itemList = [];
              for(var order in orderFunction.orderDetail){
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
                  status: 0,
                  category_id: order.product_category_id,
                );
                itemList.add(item);
              }
              cart.addCurrentOrderCache(orderCache);
              cart.addAllItem(itemList);
            }
          }
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


