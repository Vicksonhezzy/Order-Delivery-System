// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:test_project/model.dart';
//
// class ManagersOrderPage extends StatefulWidget {
//   final Models models;
//   final String myPendingOrder;
//
//   ManagersOrderPage({@required this.models, @required this.myPendingOrder});
//
//   @override
//   _ManagersOrderPageState createState() => _ManagersOrderPageState();
// }
//
// class _ManagersOrderPageState extends State<ManagersOrderPage> {
//   Stream<QuerySnapshot> stream;
//
//   String searchValue;
//
//   getStream(String search) {
//     if (widget.myPendingOrder == null) {
//       widget.models.searchOrder(search).then((value) {
//         setState(() {
//           stream = value;
//         });
//       });
//     } else {
//       widget.models.searchOrder(widget.myPendingOrder).then((value) {
//         setState(() {
//           stream = value;
//         });
//       });
//     }
//   }
//
//   _buildListTile(int index, QuerySnapshot data) {
//     return Container(
//       margin: EdgeInsets.all(5),
//       child: Column(
//         children: [
//           Text(
//             '${data.docs[index]['title']}',
//             style: TextStyle(fontWeight: FontWeight.bold),
//           ),
//           Text(
//             data.docs[index]['noOfOrder'] < 2
//                 ? '${data.docs[index]['noOfOrder']}' + ' order'
//                 : '${data.docs[index]['noOfOrder']}' + 'orders',
//             style: TextStyle(fontWeight: FontWeight.w400),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _addItemInfo(int index, QuerySnapshot data) {
//     return Column(
//       children: [
//         _buildListTile(index, data),
//         Divider(),
//       ],
//     );
//   }
//
//   _listBuilder() {
//     return StreamBuilder<QuerySnapshot>(
//         builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
//       return snapshot.data.docs.isEmpty
//           ? widget.myPendingOrder == null
//               ? Container(
//                   child: Center(
//                     child: Text('Enter a valid Order Code'),
//                   ),
//                 )
//               : Container(
//                   child: Center(
//                     child: Text('This order has been confirmed'),
//                   ),
//                 )
//           : Stack(
//               children: [
//                 Column(
//                   children: [
//                     Container(
//                       alignment: Alignment.topCenter,
//                       child: Text(
//                         snapshot.data.docs[0]['recipientName'],
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     Expanded(
//                       child: ListView.builder(
//                         physics: NeverScrollableScrollPhysics(),
//                         shrinkWrap: true,
//                         itemBuilder: (BuildContext context, index) {
//                           return _addItemInfo(index, snapshot.data);
//                         },
//                         itemCount: snapshot.data.docs.length,
//                       ),
//                     ),
//                   ],
//                 ),
//                 widget.myPendingOrder == null
//                     ? Container(
//                         alignment: Alignment.bottomCenter,
//                         child: SizedBox(
//                           width: double.infinity,
//                           child: Container(
//                             decoration: BoxDecoration(
//                               borderRadius:
//                                   BorderRadius.all(Radius.circular(100)),
//                               color: Theme.of(context).primaryColor,
//                             ),
//                             child: TextButton(
//                               child: Text(
//                                 'Confirm Order',
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.w700,
//                                   fontSize: 18,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                               onPressed: () {
//                                 widget.models.confirmPendingOrders(searchValue);
//                               },
//                             ),
//                           ),
//                         ),
//                       )
//                     : Container()
//               ],
//             );
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           widget.myPendingOrder == null ? 'Confirm Orders' : 'Pending Orders',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: Column(
//         children: [
//           widget.myPendingOrder == null
//               ? Container(
//                   padding: EdgeInsets.all(5),
//                   alignment: Alignment.topCenter,
//                   width: double.infinity,
//                   margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(30),
//                     color: Colors.white,
//                   ),
//                   child: TextField(
//                     onChanged: (value) {
//                       setState(() {
//                         searchValue = value;
//                       });
//                     },
//                     decoration: InputDecoration(
//                       hintText: 'Enter Order Reference Code...',
//                       hintStyle: TextStyle(color: Colors.grey),
//                       border: InputBorder.none,
//                       icon: IconButton(
//                         icon: Icon(Icons.search,
//                             color: Theme.of(context).primaryColor),
//                         onPressed: () => getStream(searchValue),
//                       ),
//                     ),
//                   ),
//                 )
//               : Container(
//                   alignment: Alignment.topCenter,
//                   margin: EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(10),
//                       color: Colors.grey,
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.info,
//                         color: Colors.blueGrey,
//                       ),
//                       Text('Order ref Code: '),
//                       SelectableText(
//                         '${widget.myPendingOrder}',
//                         toolbarOptions: ToolbarOptions(
//                           copy: true,
//                           cut: false,
//                           paste: false,
//                           selectAll: true,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//           widget.myPendingOrder == null ? SizedBox(height: 15) : Container(),
//           _listBuilder(),
//         ],
//       ),
//     );
//   }
// }
