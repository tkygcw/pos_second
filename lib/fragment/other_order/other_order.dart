import 'dart:async';

import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:optimy_second_device/fragment/other_order/other_order_function.dart';
import 'package:optimy_second_device/notifier/theme_color.dart';
import 'package:optimy_second_device/object/dining_option.dart';
import 'package:optimy_second_device/page/progress_bar.dart';
import 'package:provider/provider.dart';

import '../../translation/AppLocalizations.dart';
import 'display_order.dart';

class OtherOrderPage extends StatefulWidget {
  const OtherOrderPage({Key? key}) : super(key: key);

  @override
  State<OtherOrderPage> createState() => _OtherOrderPageState();
}

class _OtherOrderPageState extends State<OtherOrderPage> {
  StreamController streamController = StreamController();
  OtherOrderFunction otherOrderFunction = OtherOrderFunction.instance;
  List<DiningOption> diningOption = [];
  late DiningOption selectedOption;
  late StreamSubscription subscription;
  late Stream stream;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    stream = streamController.stream;
    getAllDiningOption();
  }

  getAllDiningOption() async {
    diningOption = await otherOrderFunction.readAllDiningOption();
    selectedOption = diningOption.first;
    streamController.sink.add('refresh');
  }

  listenStream(){
    // subscription = stream.listen(onData)
  }

  @override
  Widget build(BuildContext context) {
    ThemeColor color = context.read<ThemeColor>();
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if(snapshot.hasData){
          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              elevation: 0,
              leading: isLandscapeOrien() ? null : IconButton(
                icon: Icon(Icons.menu, color: color.buttonColor),
                onPressed: () {
                  isCollapsedNotifier.value = !isCollapsedNotifier.value;
                },
              ),
              title: Text(
                AppLocalizations.of(context)!.translate('other_order'),
                style: TextStyle(fontSize: 20, color: color.backgroundColor),
              ),
              actions: [
                SizedBox(
                  width: MediaQuery.of(context).orientation == Orientation.landscape ? 200 : 150,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton2(
                      isExpanded: true,
                      buttonStyleData: ButtonStyleData(
                        height: 55,
                        // padding: const EdgeInsets.only(left: 14, right: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: Colors.black26,
                          ),
                        ),
                      ),
                      dropdownStyleData: DropdownStyleData(
                        maxHeight: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.shade100,
                        ),
                        scrollbarTheme: ScrollbarThemeData(
                            thickness: WidgetStateProperty.all(5),
                            mainAxisMargin: 20,
                            crossAxisMargin: 5
                        ),
                      ),
                      items: diningOption.map((option) => DropdownMenuItem<DiningOption>(
                        value: option,
                        child: Text(
                          option.name!,
                          overflow: TextOverflow.visible,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      )).toList(),
                      value: selectedOption,
                      onChanged: (value) async {
                        setState(() {
                          selectedOption = value!;
                        });
                        await otherOrderFunction.readAllOrderCache(selectedOption.name!);
                        // actionController.sink.add("prod_sort_by");
                      },
                    ),
                  ),
                )
              ],
            ),
            body: DisplayOrderPage(),
          );
        } else {
          return CustomProgressBar();
        }
      }
    );
  }

  bool isLandscapeOrien() {
    try {
      if(MediaQuery.of(context).orientation == Orientation.landscape) {
        return true;
      } else {
        return false;
      }
    } catch(e) {
      return false;
    }
  }
}
