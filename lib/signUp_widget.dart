import 'package:test_project/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scoped_model/scoped_model.dart';

class SignUp extends StatefulWidget {
  final Function setType;
  final Function setNumber;

  SignUp({this.setType, this.setNumber});

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  String dropDownType = 'choose';

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<Models>(
        builder: (context, child, Models model) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.all(Radius.circular(30)),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: DropdownButton(
                  isExpanded: true,
                  iconEnabledColor: Colors.black87,
                  dropdownColor: Colors.white,
                  onChanged: (String value) {
                    setState(() {
                      dropDownType = value;
                    });
                    print(dropDownType);
                    widget.setType(value);
                  },
                  value: dropDownType,
                  elevation: 16,
                  items: <String>[
                    'choose',
                    'Dispatcher',
                    'Customer'
                  ].map<DropdownMenuItem<String>>((e) {
                    return DropdownMenuItem<String>(
                      value: e,
                      child: e == 'choose'
                          ? Text(
                              e,
                              style: TextStyle(color: Colors.grey),
                            )
                          : Text(
                              e,
                              style: TextStyle(color: Colors.black87),
                            ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          SizedBox(height: 25),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.all(Radius.circular(30)),
              child: TextFormField(
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  widget.setNumber(value);
                },
                validator: (value) {
                  if (value.length == 0) {
                    return 'enter phone number';
                  } else if (value.length < 11) {
                    return 'enter a valid number';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'number',
                  prefixIcon: Icon(
                    Icons.phone,
                    color: Theme.of(context).primaryColor,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 25, vertical: 13),
                ),
              ),
            ),
          ),
          SizedBox(height: 25),
        ],
      );
    });
  }
}
