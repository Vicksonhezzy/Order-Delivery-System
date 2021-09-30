import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:test_project/model.dart';
import 'package:test_project/my_order_details.dart';

class PendingOrders extends StatefulWidget {
  final bool pending;
  final Models model;
  final String title;
  final bool dispatcher;
  final List content;

  PendingOrders(
      {this.pending,
      this.content,
      this.dispatcher,
      @required this.model,
      this.title});

  @override
  _PendingOrdersState createState() => _PendingOrdersState();
}

class _PendingOrdersState extends State<PendingOrders> {
  Stream<QuerySnapshot> confirmedStream;

  fetchPendingOrders() {
    if (widget.dispatcher != true && widget.pending == true) {
      widget.model.pendingOrders(true).then((value) {
        setState(() {
          confirmedStream = value;
        });
      });
    }
  }

  fetchConfirmedOrders() {
    if (widget.dispatcher != true && widget.pending != true) {
      widget.model.pendingOrders(false).then((value) {
        setState(() {
          confirmedStream = value;
        });
      });
    }
  }

  refreshPendingOrders() {
    if (widget.dispatcher == true) {
      widget.model.allPendingOrders();
    }
  }

  @override
  initState() {
    super.initState();
    fetchConfirmedOrders();
    fetchPendingOrders();
  }

  _listBuilder(
      {AsyncSnapshot<QuerySnapshot> snapshot, List content, Models model}) {
    if (widget.dispatcher == true) {
      widget.model.allPendingOrders();
    }
    return ListView.builder(
      itemCount: widget.dispatcher == true
          ? content.length
          : snapshot.data.docs.length,
      itemBuilder: (context, index) {
        return ListTile(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyOrderDetails(
                    models: model,
                    pending: widget.pending,
                    title: widget.title,
                    documentCollectionId: widget.dispatcher == true
                        ? content[index].documentCollectionId
                        : snapshot.data.docs[index]['documentCollectionId'],
                    orderId: widget.dispatcher == true
                        ? content[index].id
                        : snapshot.data.docs[index].id,
                    orderRef: widget.dispatcher == true
                        ? content[index].orderRef
                        : snapshot.data.docs[index]['orderRef']),
              )),
          leading: Text(
            '${index + 1}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          title: Text(
            widget.dispatcher == true
                ? content[index].orderRef
                : snapshot.data.docs[index]['orderRef'],
          ),
          subtitle: Text('Tap for more details'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<Models>(
      builder: (context, child, Models model) => StreamBuilder<QuerySnapshot>(
        stream: confirmedStream,
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) =>
            widget.dispatcher == true
                ? widget.content.isEmpty
                    ? Center(
                        child: Text(widget.title == 'Pending Orders'
                            ? 'No Pending Order'
                            : 'Empty'),
                      )
                    : _listBuilder(
                        snapshot: snapshot,
                        model: model,
                        content: widget.content)
                : snapshot.data == null
                    ? Center(
                        child: Text(widget.title == 'Pending Orders'
                            ? 'No Pending Order'
                            : 'Empty'),
                      )
                    : snapshot.data.size < 1
                        ? Center(
                            child: Text(widget.title == 'Pending Orders'
                                ? 'No Pending Order'
                                : 'Empty'),
                          )
                        : snapshot.hasData != true
                            ? Center(
                                child: Text(widget.title == 'Pending Orders'
                                    ? 'No Pending Order'
                                    : 'Empty'),
                              )
                            : _listBuilder(snapshot: snapshot, model: model),
      ),
    );
  }
}
