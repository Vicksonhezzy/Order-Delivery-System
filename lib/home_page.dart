import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:test_project/dashboard.dart';
import 'package:test_project/model.dart';
import 'package:test_project/view_product_page.dart';

class HomePage extends StatefulWidget {
  final Models model;
  final AndroidNotificationChannel channel;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  const HomePage(
      {this.model, this.channel, this.flutterLocalNotificationsPlugin});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Stream<QuerySnapshot> stream;
  var currency = utf8.decode([0xE2, 0x82, 0xA6]);

  @override
  void initState() {
    super.initState();
    widget.model.allPendingOrders();
    widget.model.fetchProducts().then((value) {
      setState(() {
        stream = value;
      });
    });

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage message) {
      if (message != null) {}
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification notification = message.notification;
      AndroidNotification android = message.notification.android;
      if (notification != null && android != null) {
        widget.flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                widget.channel.id,
                widget.channel.name,
                widget.channel.description,
                // TODO add a proper drawable resource to android, for now using
                //      one that already exists in example app.
                // icon: 'launch_background',
              ),
            ));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      // if (message.data['order'] == true) {
      //   alert();
      // } else {
      //   Navigator.pushNamed(context, 'message',
      //       arguments: MessageArguments(message, true));
      // }
    });
    // chatRoomId(widget.models);
  }

  Column drawer(Models model) {
    return Column(
      children: [
        AppBar(
          title: Text('Menu'),
          automaticallyImplyLeading: false,
        ),
        ListTile(
          leading: Icon(Icons.dashboard),
          title: Text('Dashboard'),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Dashboard(),
              )),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double deviceHeight = MediaQuery.of(context).size.height;
    final double _containerWidth =
        deviceWidth > 768.0 ? 500.0 : deviceWidth * 0.95;
    final double _containerHeight =
        deviceHeight > 768.0 ? 500.0 : deviceHeight * 0.95;
    final width = _containerWidth / 2;
    final height = _containerHeight / 3.5;
    return ScopedModelDescendant<Models>(
        builder: (context, child, Models model) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Home page'),
        ),
        drawer: Drawer(
          child: drawer(model),
        ),
        body: Container(
          child: StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                return snapshot.connectionState == ConnectionState.waiting
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : snapshot.data == null
                        ? Center(child: CircularProgressIndicator())
                        : snapshot.data.size < 1
                            ? Center(child: Text('No product yet'))
                            : snapshot.hasData != true
                                ? Center(child: Text('No product yet'))
                                : GridView.builder(
                                    itemCount: snapshot.data.docs.length,
                                    shrinkWrap: true,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2),
                                    itemBuilder: (context, index) {
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ViewProductPage(
                                                  model: model,
                                                  productId: snapshot
                                                      .data.docs[index].id,
                                                ),
                                              ));
                                        },
                                        child: _productBuilder(
                                            height: height,
                                            width: width,
                                            snapshot:
                                                snapshot.data.docs[index]),
                                      );
                                    },
                                  );
              }),
        ),
      );
    });
  }

  Widget _productBuilder(
      {double width, double height, QueryDocumentSnapshot<Object> snapshot}) {
    String snapshotPrice =
        '$currency${NumberFormat.decimalPattern().format(int.tryParse('${snapshot['price']}'))}';
    return Container(
      margin: EdgeInsets.only(left: 5, right: 5, bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Container(
          child: Material(
            elevation: 10,
            borderOnForeground: true,
            shadowColor: Colors.grey,
            borderRadius: BorderRadius.circular(5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                      height: height,
                      width: width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(
                            snapshot['image'],
                          ),
                          fit: BoxFit.cover,
                          scale: 6,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 5,
                      top: 8,
                      child: IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.favorite_border),
                        color: Colors.black,
                      ),
                    ),
                    Positioned(
                      left: 5,
                      bottom: 5,
                      child: Container(
                        color: Colors.white38,
                        child: Text(
                          snapshot['title'],
                          style: TextStyle(
                              color: Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 5,
                      bottom: 5,
                      child: Container(
                        padding: EdgeInsets.all(5),
                        color: Colors.white,
                        child: Text(
                          snapshotPrice,
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  // padding: EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    snapshot['description'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.blueGrey),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              color: Theme.of(context).primaryColor,
                              height: 35,
                              width: 35,
                              child: Center(
                                child: IconButton(
                                    iconSize: 20,
                                    icon: Icon(
                                      Icons.add_shopping_cart,
                                    ),
                                    onPressed: () {}),
                              ),
                            ),
                          ],
                        ),
//                              SizedBox(height: 5),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
