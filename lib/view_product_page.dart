import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_project/model.dart';
import 'package:test_project/place_order_details.dart';

class ViewProductPage extends StatefulWidget {
  final String productId;
  final Models model;
  final bool view;

  const ViewProductPage({this.productId, this.view, this.model});

  @override
  _ViewProductPageState createState() => _ViewProductPageState();
}

class _ViewProductPageState extends State<ViewProductPage> {
  Stream<DocumentSnapshot> stream;

  @override
  void initState() {
    super.initState();
    widget.model.getProduct(widget.productId).then((value) {
      setState(() {
        stream = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var currency = utf8.decode([0xE2, 0x82, 0xA6]);

    return Scaffold(
      appBar: AppBar(title: Text('Product details')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: stream,
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) => snapshot
                    .connectionState ==
                ConnectionState.waiting
            ? Center(
                child: CircularProgressIndicator(),
              )
            : snapshot.hasData != true
                ? Center(
                    child: Text('No product to view'),
                  )
                : Center(
                    child: SingleChildScrollView(
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 50),
                        child: Card(
                          margin: EdgeInsets.all(10),
                          shadowColor: Theme.of(context).accentColor,
                          elevation: 6,
                          child: Container(
                            padding: EdgeInsets.all(10),
                            child: Column(
                              children: [
                                Container(
                                  child: CachedNetworkImage(
                                    imageUrl: snapshot.data['image'],
                                    fit: BoxFit.fitHeight,
                                    height: MediaQuery.of(context).size.width,
                                    width: MediaQuery.of(context).size.width,
                                  ),
                                ),
                                ListTile(
                                  title: Text(
                                    snapshot.data['title'],
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20),
                                  ),
                                ),
                                Divider(),
                                ListTile(
                                  leading: Icon(Icons.info,
                                      color: Theme.of(context).accentColor),
                                  title: Text(
                                    'description:',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  subtitle: Text(
                                    snapshot.data['description'],
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ),
                                ListTile(
                                  leading: Icon(
                                    Icons.location_on,
                                    color: Theme.of(context).accentColor,
                                  ),
                                  title: Text(
                                    'Price:',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  subtitle: Text(
                                    '$currency${snapshot.data['price']}',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ),
                                widget.view == true
                                    ? Container()
                                    : Container(
                                        // padding: EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: TextButton(
                                          onPressed: () {
                                            int amount = int.tryParse(
                                                '${snapshot.data['price']}');
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      OrderDetails(
                                                    amount: amount,
                                                    productId: snapshot.data.id,
                                                  ),
                                                ));
                                          },
                                          child: Text(
                                            'PLACE ORDER',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
