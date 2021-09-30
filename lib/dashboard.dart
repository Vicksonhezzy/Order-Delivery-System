import 'package:test_project/model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:test_project/my_order_details.dart';
import 'package:test_project/orders_tab.dart';
import 'package:test_project/upload_product.dart';

class Dashboard extends StatefulWidget {
  final Models models;

  Dashboard({this.models});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  GestureDetector container(
      {Widget navigate,
      double height,
      Color color,
      String title,
      String subtitle,
      Icon icon}) {
    return GestureDetector(
      onTap: () => navigate != null
          ? Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => navigate,
              ))
          : () {},
      child: Container(
        height: height,
        margin: EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: color,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                title,
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              trailing: icon,
            ),
            Container(
                margin: EdgeInsets.only(left: 15),
                child: Text(
                  subtitle,
                  style: TextStyle(color: Colors.white, fontSize: 15),
                )),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<Models>(
      builder: (context, child, Models model) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Dashboard'),
          ),
          body: Center(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(15),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          model.authentication == null
                              ? Container()
                              : model.authentication.userType == 'Dispatcher'
                                  ? container(
                                      height: 150,
                                      color: Colors.amber,
                                      navigate: UploadProduct(),
                                      title: 'Upload Product',
                                      subtitle: 'Upload product to test',
                                      icon: Icon(
                                        Icons.add_a_photo,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Container(),
                          model.authentication.userType == 'Dispatcher'
                              ? container(
                                  height: 150,
                                  color: Colors.amber,
                                  navigate: MyOrderDetails(
                                    models: model,
                                    title: 'Search Order',
                                  ),
                                  title: 'Confirm Order',
                                  subtitle:
                                      'Tap to search and confirm and order',
                                  icon: Icon(
                                    Icons.reorder,
                                    color: Colors.white,
                                  ),
                                )
                              : Container(),
                          container(
                            height: 150,
                            color: Colors.amber,
                            navigate:
                                model.authentication.userType == 'Dispatcher'
                                    ? OrdersTab(
                                        models: model,
                                        isDispatcher: true,
                                      )
                                    : OrdersTab(
                                        models: model,
                                      ),
                            title: model.authentication.userType == 'Dispatcher'
                                ? 'Orders'
                                : 'My Orders',
                            subtitle:
                                model.authentication.userType == 'Dispatcher'
                                    ? 'View All Pending/Confirmed Orders'
                                    : 'View Pending/Confirmed Orders',
                            icon: Icon(
                              Icons.reorder,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
