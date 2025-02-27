import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:optimy_second_device/notifier/app_setting_notifier.dart';
import 'package:optimy_second_device/object/product.dart';
import 'package:optimy_second_device/page/pos_pin.dart';
import 'package:optimy_second_device/page/progress_bar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';

import '../notifier/theme_color.dart';
import 'login.dart';


class LoadingPage extends StatefulWidget {
  const LoadingPage({Key? key}) : super(key: key);

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  StreamController controller = StreamController();
  List<String> decodedBase64ImageList = [];
  Uint8List? decodedByte;
  bool isDecodeComplete = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    startLoad();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
          stream: controller.stream,
          builder: (context, snapshot) {
            if(snapshot.hasData){
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PosPinPage()));
              });
              return SizedBox.shrink();
            } else {
              return CustomProgressBar();
            }
          }
      ),
    );
  }

  startLoad() async  {
    print("start load called!!!");
    await clientAction.connectRequestPort(action: '1', callback: checkStatus);
    // await Future.delayed(Duration(seconds: 3), () {
    //   decodeAction.decodeAllFunction();
    // });
    // if(decodeAction.decodedProductList != null && decodeAction.decodedProductList!.isNotEmpty){
    //   await _createProductImgFolder();
    // } else {
    //   backToLoginPage();
    // }
  }

  checkStatus(response) async {
    if(response != null){
      var json = jsonDecode(response);
      switch(json['status']){
        case '-1': {
          Future.delayed(Duration(seconds: 2), () {
          controller.sink.add("done");
          });
        }break;
        case '1': {
          decodeAction.decodeAllFunction(response);
          initAppSetting();
          if(decodeAction.decodedProductList != null && decodeAction.decodedProductList!.isNotEmpty){
            await _createProductImgFolder();
          } else {
            backToLoginPage();
          }
        }break;
        default: {
          clientAction.openReconnectDialog(action: json['action'], callback: checkStatus);
        }
      }
    }
  }

  initAppSetting(){
    if(decodeAction.decodedAppSetting!.show_sku == 1){
      AppSettingModel.instance.setShowSKUStatus(true);
    } else {
      AppSettingModel.instance.setShowSKUStatus(false);
    }
    AppSettingModel.instance.setTableOrder = decodeAction.decodedAppSetting!.table_order!;
    appLanguage.changeLanguage(Locale(decodeAction.appLanguageCode));
  }

  backToLoginPage(){
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (BuildContext context) => LoginPage(),
      ),
          (Route route) => false,
    );
  }

  toNextPage(){
    Timer(Duration(seconds: 8), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PosPinPage()));
    });
  }

/*
  create folder to save product image
*/
  Future<String> get _localPath async {
    final directory = await getApplicationSupportDirectory();
    return directory.path;
  }

  _createProductImgFolder() async {
    final prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    Map userObject = json.decode(user!);

    final folderName = userObject['company_id'];
    final directory = await _localPath;
    final path = '$directory/assets/$folderName';
    final pathImg = Directory(path);
    pathImg.create();
    await prefs.setString('local_path', path);
    await downloadProductImage(pathImg.path);
  }

  /*
  download product image
*/
  downloadProductImage(String path) async {
    bool isCompleted = true;
    List<Product> productList = decodeAction.decodedProductList!.where((e) => e.graphic_type == '2').toList();
    for(int i = 0; i < productList.length; i++){
      await clientAction.connectRequestPort(action: '0', param: productList[i].image, callback: decodeBase64Image);
      if(decodedByte != null){
        var localPath = '$path/${productList[i].image}';
        final imageFile = File(localPath);
        await imageFile.writeAsBytes(decodedByte!);
      }
      // else {
      //   isCompleted = false;
      //   break;
      // }
    }
    controller.sink.add("done");
    // if(isCompleted){
    //   controller.sink.add("done");
    // } else {
    //   clientAction.openReconnectDialog(callback: startLoad);
    // }
  }

  void decodeBase64Image(response){
    if(response != null){
      var json = jsonDecode(response);
      switch(json['status']){
        case '1': {
          decodedByte = base64Decode(json['data']['image_name']);
        }break;
        default: {
          decodedByte = null;
        }

      }
    }
  }

}




