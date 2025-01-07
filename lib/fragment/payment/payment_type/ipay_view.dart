import 'dart:developer';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../../../notifier/cart_notifier.dart';
import '../../../translation/AppLocalizations.dart';
import '../function/payment_function.dart';
import '../payment_method_widget.dart';
import 'shared_widget/button_widget.dart';
import 'shared_widget/final_amount_widget.dart';

class IpayView extends StatefulWidget {
  const IpayView({super.key});

  @override
  State<IpayView> createState() => _IpayViewState();
}

class _IpayViewState extends State<IpayView> {
  bool startScan = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ScanWidget(scanning: startScan),
        ButtonWidget(paymentTypeEnum: PaymentTypeEnum.ipay, scanQR: scanQR,)
      ],
    );
  }

  bool scanQR(){
    setState(() {
      if(!startScan){
        startScan = true;
      } else {
        startScan = false;
      }
    });
    return startScan;
  }
}

class _ScanWidget extends StatefulWidget {
  final bool scanning;
  const _ScanWidget({super.key, required this.scanning});

  @override
  State<_ScanWidget> createState() => _ScanWidgetState();
}

class _ScanWidgetState extends State<_ScanWidget> {
  QRViewController? controller;
  Barcode? result;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 || MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 350.0;
    if(!widget.scanning) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child:
        ///***If you have exported images you must have to copy those images in assets/images directory.
        Image(
          height: 250,
          width: 250,
          image: AssetImage("drawable/TNG.jpg"),
        ),
      );
    } else {
      return SizedBox(
        height: 250,
        width: 250,
        child: QRView(
          key: qrKey,
          onQRViewCreated: _onQRViewCreated,
          overlay: QrScannerOverlayShape(
              borderColor: Colors.red,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: scanArea),
          onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
        ),
      );
    }
  }

  void _onQRViewCreated(QRViewController p1) {
    try{
      var cart = context.read<CartModel>();
      var paymentFunc = context.read<PaymentFunction>();
      this.controller = p1;
      p1.scannedDataStream.listen((scanData) async {
        result = scanData;
        print('result:${result?.code}');
        p1.pauseCamera();
        //Make payment
        print("Call server make payment");
        await paymentFunc.makePayment(cart, ipayResultCode: result!.code!);
        // assetsAudioPlayer.open(
        //   Audio("audio/scan_sound.mp3"),
        // );
        // Map<String, dynamic> apiRes = await paymentApi();
        // if (apiRes['status'] == '1') {
        //   await callCreateOrder(finalAmount, ipayTransId: apiRes['data']);
        //   assetsAudioPlayer.open(
        //     Audio("audio/payment_success.mp3"),
        //   );
        //   //pass trans id from api res to payment success dialog
        //   openPaymentSuccessDialog(widget.dining_id, split_payment, isCashMethod: false, diningName: widget.dining_name, ipayTransId: apiRes['data']);
        // } else {
        //   assetsAudioPlayer.open(
        //     Audio("audio/error_sound.mp3"),
        //   );
        //   Fluttertoast.showToast(
        //       backgroundColor: Color(0xFFFF0000), msg: "${apiRes['data']}");
        //   FLog.error(
        //     className: "make_payment_dialog",
        //     text: "paymentApi return error",
        //     exception: "ipay API res: ${apiRes['data']}",
        //   );
        //   Navigator.pop(context);
        // }
      });
    }catch(e){
      print("error: $e");
    }
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
            Text(AppLocalizations.of(context)!.translate('no_permission'))),
      );
    }
  }
}

