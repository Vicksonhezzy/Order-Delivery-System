import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:test_project/model.dart';
import 'package:test_project/place_order_details.dart';

class RoomViewPage extends StatefulWidget {
  final String image;
  final String title;
  final String description;
  final bool isSearch;
  final String price;
  final String houseId;
  final String type;
  final bool isHouse;
  final String vendorId;
  final int noOfOrder;
  final String number;
  final String address;
  final String vendorName;
  final String vendorNumber;
  final bool isHotel;
  final double rating;
  final int noOFUsersRated;
  final List usersRatings;
  final int ratingSum;
  final String amount;

  const RoomViewPage({
    this.image,
    this.amount,
    this.isHotel,
    this.vendorId,
    @required this.isHouse,
    this.type,
    this.houseId,
    this.title,
    this.description,
    this.price,
    this.noOfOrder,
    this.number,
    this.address,
    this.vendorName,
    this.vendorNumber,
    this.isSearch,
    this.rating,
    this.noOFUsersRated,
    this.usersRatings,
    this.ratingSum,
  });

  @override
  _RoomViewPageState createState() => _RoomViewPageState();
}

class _RoomViewPageState extends State<RoomViewPage> {
  int amount;

  @override
  Widget build(BuildContext context) {
    var currency = utf8.decode([0xE2, 0x82, 0xA6]);
    String snapshotPrice =
        '$currency${NumberFormat.decimalPattern().format(int.tryParse('${widget.price}'))}';
    return ScopedModelDescendant<Models>(
        builder: (context, child, Models model) {
      return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 8,
                color: Theme.of(context).primaryColor,
              ),
              Stack(
                children: [
                  Container(
                    foregroundDecoration: BoxDecoration(color: Colors.black26),
                    height: 350,
                    width: double.infinity,
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: widget.image,
                        progressIndicatorBuilder: (context, url, progress) =>
                            Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: CircularProgressIndicator(
                                value: progress.progress),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            Center(child: Icon(Icons.error)),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 250),
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '${widget.title}\n',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                        Row(
                          children: [
                            SizedBox(width: 10),
                            Spacer(),
                            IconButton(
                              onPressed: () {},
                              icon: Icon(Icons.favorite_border),
                              color: Colors.black,
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 32, horizontal: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        snapshotPrice,
                                        style: TextStyle(
                                            color:
                                                Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Text(
                                'DESCRIPTION',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text('${widget.description}'),
                              SizedBox(
                                width: double.infinity,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(100)),
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  child: TextButton(
                                    child: Text(
                                      'PLACE ORDER',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        amount = int.tryParse(widget.amount);
                                      });
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => OrderDetails(
                                              productId: widget.houseId,
                                              amount: amount,
                                            ),
                                          ));
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        model.authentication.number == widget.vendorNumber &&
                                widget.isSearch == true
                            ? OrderInfo(
                                model: model,
                                vendorName: widget.vendorName,
                                vendorNumber: widget.vendorNumber,
                                address: widget.address,
                                noOfOrder: widget.noOfOrder == null
                                    ? 0
                                    : widget.noOfOrder,
                                amount: widget.amount,
                                price: widget.price,
                                isSearch: widget.isSearch,
                                number: widget.number,
                              )
                            : Container(),
                      ],
                    ),
                  ),
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    centerTitle: true,
                    title: Text(
                      'DETAILS',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

class OrderInfo extends StatelessWidget {
  final Models model;
  final String number;
  final String address;
  final int noOfOrder;
  final String vendorNumber;
  final String vendorName;
  final String amount;
  final bool isSearch;
  final String price;

  OrderInfo({
    this.model,
    this.number,
    this.address,
    this.noOfOrder,
    this.vendorNumber,
    this.vendorName,
    this.amount,
    this.isSearch,
    this.price,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Card(
              elevation: 15,
              shadowColor: Colors.blueGrey,
              child: Container(
                alignment: Alignment.topLeft,
                padding: EdgeInsets.all(15),
                child: Column(
                  children: [
                    Container(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'Order Details',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Divider(
                      color: Colors.black38,
                    ),
                    Container(
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            leading: Icon(Icons.confirmation_number_outlined),
                            title: Text('Quantity Of Order:'),
                            subtitle: Text('$noOfOrder'),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            leading: Icon(Icons.money),
                            title: Text('Amount:'),
                            subtitle: Text('$amount'),
                          ),
                          Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                leading: Icon(Icons.my_location),
                                title: Text('Recipient Address:'),
                                subtitle: address == null
                                    ? Text('')
                                    : SelectableText(
                                        address,
                                        toolbarOptions: ToolbarOptions(
                                          copy: true,
                                          selectAll: true,
                                          cut: false,
                                          paste: false,
                                        ),
                                      ),
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                leading: Icon(Icons.phone),
                                title: Text('Recipient Number:'),
                                subtitle: number == null
                                    ? Text('')
                                    : SelectableText(
                                        number,
                                        toolbarOptions: ToolbarOptions(
                                          copy: true,
                                          selectAll: true,
                                          cut: false,
                                          paste: false,
                                        ),
                                      ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
