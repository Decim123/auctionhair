// trade_detail.dart

import 'package:flutter/material.dart';

class TradeDetail extends StatelessWidget {
  final Map<String, dynamic> lot;

  const TradeDetail({Key? key, required this.lot}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int lotId = lot['lot_id'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Детали лота'),
      ),
      body: Center(
        child: Text(
          'Lot ID: $lotId',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
