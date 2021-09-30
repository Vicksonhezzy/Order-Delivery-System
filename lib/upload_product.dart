import 'dart:io';

import 'package:test_project/image_container.dart';
import 'package:test_project/model.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

class UploadProduct extends StatefulWidget {
  @override
  _UploadProductState createState() => _UploadProductState();
}

class _UploadProductState extends State<UploadProduct> {
  final formKey = GlobalKey<FormState>();

  final Map<String, dynamic> _infoData = {
    'image': null,
    'title': null,
    'description': null,
    'price': null,
  };

  setImage(Models model, File image) {
    setState(() {
      model.setImage(image);
      _infoData['image'] = image;
    });
  }

  onSubmit(Models model) async {
    if (formKey.currentState.validate() && model.image != null) {
      formKey.currentState.save();
      model
          .updateSells(
        image: _infoData['image'],
        description: _infoData['description'],
        price: _infoData['price'],
        title: _infoData['title'],
      )
          .then((Map<String, dynamic> value) {
        return showDialog(
          context: context,
          builder: (context) => AlertDialog(
            elevation: 2,
            title: Text('FeedBack'),
            content: Text(value['success']),
            actions: [
              Container(
                color: Colors.green,
                padding: EdgeInsets.all(2),
                child: TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    // model.fetchMyPost();
                    setState(() {
                      model.setImage(null);
                    });
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                ),
              )
            ],
          ),
        );
      });
    }
  }

  Padding dropArrow() {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Icon(Icons.arrow_drop_down, color: Colors.black),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<Models>(
        builder: (context, child, Models model) {
      return WillPopScope(
        onWillPop: () async {
          model.setImage(null);
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'Upload Product',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                HouseImageContainer(
                  setImage: setImage,
                  model: model,
                ),
                SizedBox(height: 20),
                Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        margin:
                            EdgeInsets.symmetric(horizontal: 35, vertical: 10),
                        child: Material(
                          elevation: 2,
                          child: TextFormField(
                            textCapitalization: TextCapitalization.sentences,
                            validator: (value) {
                              if (value.length < 1) {
                                return 'enter title';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.edit),
                                hintText: 'Enter title'),
                            onChanged: (value) {
                              setState(() {
                                _infoData['title'] = value;
                              });
                            },
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        margin:
                            EdgeInsets.symmetric(horizontal: 35, vertical: 10),
                        child: Material(
                          elevation: 2,
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value.length < 1) {
                                return 'enter price';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.edit),
                                hintText: 'Enter price'),
                            onChanged: (newValue) {
                              setState(() {
                                _infoData['price'] =
                                    newValue.replaceAll(',', '');
                              });
                            },
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        margin:
                            EdgeInsets.symmetric(horizontal: 35, vertical: 10),
                        child: Material(
                          elevation: 2,
                          child: TextFormField(
                            textCapitalization: TextCapitalization.sentences,
                            validator: (value) {
                              if (value.length < 1) {
                                return 'enter description';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.edit),
                                hintText: 'Enter description'),
                            onChanged: (value) {
                              setState(() {
                                _infoData['description'] = value;
                              });
                            },
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        margin: EdgeInsets.all(10),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.all(Radius.circular(100)),
                            color: Color(0xffff3a5a),
                          ),
                          child: model.postUploading == true
                              ? Center(child: CircularProgressIndicator())
                              : TextButton(
                                  child: Text(
                                    'POST',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18),
                                  ),
                                  onPressed: () => onSubmit(model)),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      );
    });
  }
}
