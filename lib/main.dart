
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:optimy_second_device/object/decode_action.dart';
import 'package:optimy_second_device/object/table.dart';
import 'package:optimy_second_device/page/loading.dart';
import 'package:optimy_second_device/page/login.dart';
import 'package:optimy_second_device/page/second_display.dart';
import 'package:optimy_second_device/translation/AppLocalizations.dart';
import 'package:optimy_second_device/translation/appLanguage.dart';
import 'package:presentation_displays/display.dart';
import 'package:presentation_displays/displays_manager.dart';
import 'package:provider/provider.dart';

import 'notifier/cart_notifier.dart';
import 'notifier/connectivity_change_notifier.dart';
import 'notifier/notification_notifier.dart';
import 'notifier/printer_notifier.dart';
import 'notifier/report_notifier.dart';
import 'notifier/table_notifier.dart';
import 'notifier/theme_color.dart';
import 'object/client_action.dart';
import 'object/lcd_display.dart';

final snackBarKey = GlobalKey<ScaffoldMessengerState>();
final NotificationModel notificationModel = NotificationModel();
final ClientAction clientAction = ClientAction.instance;
final LCDDisplay lcdDisplay = LCDDisplay();
final DecodeAction decodeAction = DecodeAction();
DisplayManager displayManager = DisplayManager();

void main() async  {
  WidgetsFlutterBinding.ensureInitialized();

  //init lcd screen
  initLCDScreen();

  //check second screen
  getSecondScreen();

  //device detect
  deviceDetect();

  //other method
  statusBarColor();

  AppLanguage appLanguage = AppLanguage();
  await appLanguage.fetchLocale();
  runApp(ChangeNotifierProvider.value(
    value: notificationModel,
    child: MyApp(appLanguage: appLanguage),
  ));
}

class MyApp extends StatelessWidget {
  final AppLanguage appLanguage;
  const MyApp({super.key, required this.appLanguage});

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Set landscape orientation
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppLanguage>(
          create: (_) => appLanguage,
        ),
        ChangeNotifierProvider(create: (_) {
          ConnectivityChangeNotifier changeNotifier = ConnectivityChangeNotifier();
          changeNotifier.initialLoad();
          return changeNotifier;
        }),
        ChangeNotifierProvider(
          create: (_) => ThemeColor(),
        ),
        ChangeNotifierProvider(
          create: (_) => CartModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => PrinterModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => TableModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportModel(),
        ),
      ],
      child: Consumer<AppLanguage>(builder: (context, model, child) {
        return MaterialApp(
          navigatorKey: MyApp.navigatorKey,
          scaffoldMessengerKey: snackBarKey,
          locale: model.appLocal,
          supportedLocales: [
            Locale('en', ''),
            Locale('zh', ''),
            Locale('ms', ''),
          ],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            DefaultCupertinoLocalizations.delegate
          ],
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.white24,
                titleTextStyle: TextStyle(color: Colors.black),
                iconTheme: IconThemeData(color: Colors.orange), //
              ),
              primarySwatch: Colors.teal,
              inputDecorationTheme: InputDecorationTheme(
                focusColor: Colors.black,
                labelStyle: TextStyle(
                  color: Colors.black54,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.black26,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.orangeAccent,
                    width: 2.0,
                  ),
                ),
              )),
          routes: {
            '/loading': (context) => LoadingPage(),
            '/': (context) => LoginPage(),
            'presentation': (context) => SecondDisplay(),
          },
        );
      }),
    );
  }
}

initLCDScreen() async {
  await lcdDisplay.initLcd();
}

deviceDetect() async {
  final double screenWidth = WidgetsBinding
      .instance.platformDispatcher.views.first.physicalSize.width /
      WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
  //final double screenWidth = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize.width;
  print('screen width: ${screenWidth}');
  if (screenWidth < 500) {
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  } else {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
}
getSecondScreen() async {
  List<Display?> displays = [];
  final values = await displayManager.getDisplays();
  displays.clear();
  displays.addAll(values!);
  if (displays.length > 1) {
    notificationModel.setHasSecondScreen();
    notificationModel.insertDisplay(value: displays);
    //await displayManager.showSecondaryDisplay(displayId: 1, routerName: "/init");
  }
  print('display list = ${displays.length}');
}

statusBarColor() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.white, // status bar color
    statusBarBrightness: Brightness.dark, //status bar brightness
    statusBarIconBrightness: Brightness.dark,
  ));
}

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});
//
//   final String title;
//
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   String incomingMessage = "";
//   List<PosTable> tableList = [];
//   final TextEditingController _controller = TextEditingController();
//   var channel;
//   bool isLoaded = false;
//   late Socket socket;
//
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     //listen();
//     connectServer();
//   }
//
//   @override
//   void dispose() {
//     channel.sink.close();
//     _controller.dispose();
//     super.dispose();
//   }
//
//   // void listen() async {
//   //   final wsUrl = Uri.parse('ws://192.168.0.223:9999');
//   //   channel = WebSocketChannel.connect(wsUrl);
//   //   isLoaded = true;
//   // }
//   //
//   // void _sendMessage() {
//   //   if (_controller.text.isNotEmpty) {
//   //     channel.sink.add(_controller.text);
//   //   }
//   // }
//
//   void connectServer(){
//     Socket.connect("192.168.0.223", 9999).then((socket) {
//       this.socket = socket;
//       print('client connected : ${socket.remoteAddress.address}:${socket.remotePort}');
//       socket.write('1');
//       socket.listen((data) {
//         //print("client listen  : ${String.fromCharCodes(data).trim()}");
//         incomingMessage = String.fromCharCodes(data).trim();
//         setState(() {
//           // incomingMessage;
//            var result = jsonDecode(incomingMessage);
//            if(result['status'] == '1'){
//              tableList = List<PosTable>.from(result['data'].map((json) => PosTable.fromJson(json)));
//            }
//           // var result = jsonDecode(incomingMessage);
//           // print('result: ${jsonDecode(incomingMessage)}');
//           // tableList = List<PosTable>.from(result.map((json) => PosTable.fromJson(json)));
//         });
//       }, onDone: () {
//         print("client done");
//         // socket.destroy();
//       });
//     });
//   }
//
//   void socketSend(String message) {
//     Map<String, dynamic>? result;
//     print('socket send called!');
//     setState(() {
//       incomingMessage = "sending...";
//     });
//     if(message != 'getAllTable'){
//       result = {'action': '2', 'param': message};
//     } else {
//       result = {'action': '1', 'param': ''};
//     }
//     socket.write(jsonEncode(result));
//     // Socket.connect("192.168.0.223", 9999).then((socket) {
//     //   print('client connected : ${socket.remoteAddress.address}:${socket.remotePort}');
//     //
//     //   socket.write(message);
//     //
//     //   socket.listen((data) {
//     //     print("client listen  : ${String.fromCharCodes(data).trim()}");
//     //     setState(() {
//     //       incomingMessage = String.fromCharCodes(data).trim();
//     //     });
//     //   }, onDone: () {
//     //     print("client done");
//     //     // socket.destroy();
//     //   });
//     // });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//       ),
//       body:  Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             //Text(incomingMessage),
//             tableList.isNotEmpty ?
//             Text('Current table length: ${tableList.length}')
//             : const Text('Wait response from the server...'),
//             Container(
//               height: 100,
//               width: 100,
//               child: TextField(controller: _controller),
//             ),
//             ElevatedButton(onPressed: () => socketSend(_controller.text), child: const Text("Send")),
//             ElevatedButton(onPressed: () => socketSend('getAllTable'), child: const Text("Get all table")),
//             ElevatedButton(onPressed: () => connectServer(), child: const Text("Reconnect")),
//           ],
//         ),
//       ),
//       // body: isLoaded == true ?
//       // Padding(
//       //   padding: const EdgeInsets.all(20.0),
//       //   child: Column(
//       //     crossAxisAlignment: CrossAxisAlignment.start,
//       //     children: [
//       //       Form(
//       //         child: TextFormField(
//       //           controller: _controller,
//       //           decoration: const InputDecoration(labelText: 'Send a message'),
//       //         ),
//       //       ),
//       //       const SizedBox(height: 24),
//       //       StreamBuilder(
//       //         stream: channel.stream,
//       //         builder: (context, snapshot) {
//       //           return Text(snapshot.hasData ? '${snapshot.data}' : '');
//       //         },
//       //       )
//       //     ],
//       //   ),
//       // )
//       //     :
//       // Container(),
//       // floatingActionButton: FloatingActionButton(
//       //   onPressed: _sendMessage,
//       //   tooltip: 'Send message',
//       //   child: const Icon(Icons.send),
//       // ),
//     );
//   }
// }
