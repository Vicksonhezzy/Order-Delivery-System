import 'dart:io';
import 'package:test_project/model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scoped_model/scoped_model.dart';

class HouseImageContainer extends StatefulWidget {
  final Function setImage;
  final Models model;

  HouseImageContainer({this.setImage, this.model});

  @override
  _HouseImageContainerState createState() => _HouseImageContainerState();
}

class _HouseImageContainerState extends State<HouseImageContainer> {
  errorMessage(Models model) {
    if (model.image == null) {
      return Center(child: Text('choose image'));
    } else {
      return Container();
    }
  }

  final picker = ImagePicker();

  // Future<void> retrieveLostData() async {
  //   final LostDataResponse response = await picker.retrieveLostData();
  //   if (response.isEmpty) {
  //     return null;
  //   }
  //   if (response.file != null) {
  //     if (response.type == RetrieveType.video) {
  //       return null;
  //     } else {
  //       setState(() {
  //         widget.model.setImage(File(response.file.path));
  //       });
  //     }
  //   } else {
  //     return null;
  //   }
  // }

  Future _pickImage(Models model, ImageSource source) async {
    XFile pickedFile = await picker.pickImage(source: source);
    setState(() {
      if (pickedFile != null) {
        final File image = File(pickedFile.path);
        model.setImage(image);
        widget.setImage(model, image);

        Navigator.pop(context);
      } else {
        print('No image found');
      }
    });
  }

  Widget imageContainerDisplay(Models model) {
    return imageContainer(model);
  }

  Container imageContainer(Models model) {
    return Container(
      child: Material(
        child: GestureDetector(
          onTap: () => _imagePicker(model),
          child: Container(
            decoration: model.image == null
                ? BoxDecoration(borderRadius: BorderRadius.circular(20))
                : BoxDecoration(borderRadius: BorderRadius.circular(1)),
            child: Material(
              child: model.image == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            size: 30,
                            color: Colors.grey,
                          ),
                          Text(
                            'Add image',
                            textAlign: TextAlign.center,
                          )
                        ],
                      ),
                    )
                  : Image.file(model.image),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<Models>(
        builder: (context, child, Models model) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            height: 400,
            alignment: Alignment.center,
            child: Material(
              elevation: 1,
              child: imageContainerDisplay(model),
            ),
          ),
          errorMessage(model),
          SizedBox(height: 10),
        ],
      );
    });
  }

  _imagePicker(Models model) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          final Color _color = Theme.of(context).accentColor;
          return Container(
              height: 150,
              padding: EdgeInsets.all(10),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Choose',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Divider(),
                    SizedBox(height: 10),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              _pickImage(model, ImageSource.camera);
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.camera,
                                  color: _color,
                                ),
                                Text('Camera')
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _pickImage(model, ImageSource.gallery);
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.image,
                                  color: _color,
                                ),
                                Text('Gallery')
                              ],
                            ),
                          )
                        ])
                  ],
                ),
              ));
        });
  }
}
