import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:optimy_second_device/main.dart';
import 'package:optimy_second_device/object/client_action.dart';
import 'package:provider/provider.dart';

import '../../notifier/theme_color.dart';
import '../../object/order_cache.dart';
import '../../object/order_detail.dart';
import '../../page/progress_bar.dart';
import '../../utils/Utils.dart';
import 'adjust_stock_dialog.dart';

class QrMainPage extends StatefulWidget {
  const QrMainPage({Key? key}) : super(key: key);

  @override
  State<QrMainPage> createState() => _QrMainPageState();
}

class _QrMainPageState extends State<QrMainPage> {
  final ClientAction qrClientAction = ClientAction(serverIp: clientAction.serverIp);
  late StreamController controller;
  List<OrderCache> qrOrderCacheList = [];
  List<OrderDetail> orderDetailList = [], noStockOrderDetailList = [];
  bool isLoaded = false, hasNoStockProduct = false;

  @override
  void initState() {
    super.initState();
    controller = StreamController();
    isLoaded = true;
    preload();
  }

  @override
  void deactivate() {
    //clientAction.qrOrderController.sink.close();
    super.deactivate();
  }

  @override
  void dispose() {
    controller.sink.close();
    //clientAction.qrOrderController.sink.close();
    super.dispose();
  }

  preload() async {
    await clientAction.connectRequestPort(action: '19');
    decodeData();
  }

  decodeData(){
    var json = jsonDecode(clientAction.response!);
    Iterable value1 = json['data']['qrOrderCacheList'];
    qrOrderCacheList = value1.map((tagJson) => OrderCache.fromJson(tagJson)).toList();
    decodeAction.qrOrderController.sink.add(qrOrderCacheList);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeColor>(builder: (context, ThemeColor color, child) {
      return Scaffold(
        appBar: AppBar(
          primary: false,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: ElevatedButton(onPressed: () async { await clientAction.connectServer("192.168.0.223");}, child: Text("Qr order", style: TextStyle(fontSize: 25))),
        ),
        body: StreamBuilder(
            stream: decodeAction.qrStream,
            builder: (context, snapshot) {
              if(snapshot.hasData){
                print("has data called");
                qrOrderCacheList = snapshot.data;
                return Container(
                  padding: EdgeInsets.all(10),
                  child: qrOrderCacheList.isNotEmpty ?
                  ListView.builder(
                      shrinkWrap: true,
                      itemCount: qrOrderCacheList.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Card(
                          elevation: 5,
                          child: ListTile(
                            contentPadding: EdgeInsets.all(10),
                            //isThreeLine: true,
                            title: qrOrderCacheList[index].dining_name == 'Dine in'
                                ? Text('Table No: ${qrOrderCacheList[index].table_number}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey))
                                : qrOrderCacheList[index].dining_name == 'Take Away'
                                ? Text('Take Away', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey))
                                : Text('Delivery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                            subtitle: RichText(
                              text: TextSpan(
                                style: TextStyle(color: Colors.black, fontSize: 16),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: 'Date: ${Utils.formatDate(qrOrderCacheList[index].created_at)}',
                                      style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
                                  TextSpan(text: '\n'),
                                  TextSpan(
                                    text: 'Amount: ${Utils.convertTo2Dec(qrOrderCacheList[index].total_amount)}',
                                    style: TextStyle(color: Colors.black87, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            leading: CircleAvatar(
                                backgroundColor: Colors.grey.shade200,
                                child: Icon(
                                  Icons.qr_code,
                                  color: Colors.grey,
                                )),
                            trailing: Text('#${qrOrderCacheList[index].batch_id}', style: TextStyle(fontSize: 18)),
                            onTap: () async {
                              await checkOrderDetail(qrOrderCacheList[index].order_cache_sqlite_id!);
                              //pop stock adjust dialog
                              openAdjustStockDialog(
                                  orderDetailList,
                                  qrOrderCacheList[index].order_cache_sqlite_id!,
                                  qrOrderCacheList[index].qr_order_table_sqlite_id!,
                                  qrOrderCacheList[index].batch_id!);
                            },
                          ),
                        );
                      })
                      :
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, size: 40.0),
                        Text('NO ORDER', style: TextStyle(fontSize: 24)),
                      ],
                    ),
                  ),
                );
              } else {
                return CustomProgressBar();
              }
            }),
      );
    });
  }

  checkOrderDetail(int orderCacheLocalId) async {
    await qrClientAction.connectRequestPort(action: '20', param: orderCacheLocalId.toString());
    decodeData2();
  }

  decodeData2(){
    try{
      print("response: ${qrClientAction.response!}");
      var json = jsonDecode(qrClientAction.response!);
      if(json['status'] == '1'){
        Iterable value1 = json['data']['orderDetailList'];
        orderDetailList = value1.map((tagJson) => OrderDetail.fromJson(tagJson)).toList();
      }
    }catch(e){
      print("check order detail decode error: $e");
    }
  }

  openAdjustStockDialog(List<OrderDetail> orderDetail, int localId, String tableLocalId, String batchNumber) async {
    print("adjust stock dialog open called!");
    return showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: AdjustStockDialog(
                orderDetailList: orderDetail,
                tableLocalId: tableLocalId,
                orderCacheLocalId: localId,
                callBack: () => preload(),
                orderCacheList: qrOrderCacheList,
                currentBatch: batchNumber,
              ),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {
          // ignore: null_check_always_fails
          return null!;
        });
  }
}
