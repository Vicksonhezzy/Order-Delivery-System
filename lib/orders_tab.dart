import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:test_project/model.dart';
import 'package:test_project/pending_orders.dart';

class OrdersTab extends StatefulWidget {
  final Models models;
  final bool isDispatcher;

  const OrdersTab({this.models, this.isDispatcher});

  @override
  _OrdersTabState createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {

  fetchPendingOrders() {
    if (widget.isDispatcher == true) {
      widget.models.allPendingOrders();
    }
  }

  @override
  initState() {
    super.initState();
    setState(() {
      fetchPendingOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: ScopedModelDescendant<Models>(
          builder: (context, child, Models model) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Orders'),
            bottom: TabBar(
              isScrollable: true,
              tabs: [
                Tab(
                  icon: Icon(Icons.pending),
                  text: 'Pending Orders',
                ),
                Tab(
                  icon: Icon(Icons.check_box),
                  text: 'Confirmed Orders',
                ),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              PendingOrders(
                model: model,
                title: 'Pending Orders',
                pending: true,
                dispatcher: widget.isDispatcher,
                content: model.viewAllPendingOrders,
              ),
              PendingOrders(
                model: model,
                dispatcher: widget.isDispatcher,
                title: 'Confirmed Orders',
                pending: false,
                content: model.allConfirmedOrders,
              ),
            ],
          ),
        );
      }),
    );
  }
}
