import 'package:flutter/material.dart';

class FinalAmountWidget extends StatelessWidget {
  final String finalAmount;
  const FinalAmountWidget({super.key, required this.finalAmount});

  @override
  Widget build(BuildContext context) {
    return Text(
      'RM: $finalAmount',
      style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
    );
  }
}
