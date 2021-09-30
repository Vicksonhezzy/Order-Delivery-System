import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_project/model.dart';
import 'package:test_project/signUp_widget.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

class Login extends StatefulWidget {
  final bool signUp;

  Login({this.signUp});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final formKey = GlobalKey<FormState>();

  final Map<String, dynamic> _infoData = {
    'type': null,
    'number': null,
    'email': null,
    'password': null,
  };

  setType(String type) {
    setState(() {
      _infoData['type'] = type;
    });
  }

  setNumber(String number) {
    if (number.startsWith('+')) {
      setState(() {
        _infoData['number'] = number;
      });
    } else {
      setState(() {
        _infoData['number'] = '+234$number';
      });
    }
  }

  _signIn(Models model) async {
    if (formKey.currentState.validate()) {
      if (widget.signUp == true) {
        if (_infoData['type'] == null || _infoData['type'] == 'choose') {
          return null;
        } else {
          print(_infoData);
          await verifyNumber(model).then((value) {
            if (value != null) {
              if(successful == true){
                Navigator.pushNamed(context, 'login');
              }
              else {
                verificationFailed('Too many request. Try again later');
              }
            }
          });
        }
      } else {
        model.signIn(_infoData['email'], _infoData['password']).then((value) {
          if (value['success'] == true) {
            Navigator.pushReplacementNamed(context, 'homepage');
          } else {
            alertDialog(value);
          }
        });
      }
    }
  }

  String smsCode;
  String errorMessage;

  bool _isLoading = false;
  bool successful = false;

  Future<Map<String, dynamic>> verifyNumber(Models model) async {
    setState(() {
      _isLoading = true;
    });
    print(_infoData['number']);
    try {
      FirebaseAuth fireBaseAuth = FirebaseAuth.instance;
      await fireBaseAuth.verifyPhoneNumber(
        phoneNumber: _infoData['number'],
        timeout: Duration(milliseconds: 10000),
        verificationCompleted: (phoneAuthCredential) async {
          await fireBaseAuth.currentUser
              .linkWithCredential(phoneAuthCredential)
              .then((value) async {
            await model
                .signUp(
                    user: value.user,
                    number: _infoData['number'],
                    email: _infoData['email'],
                    password: _infoData['password'],
                    userType: _infoData['type'])
                .then((value) {
              alertDialog(value);
            });
          });
          setState(() {
            successful = true;
            _isLoading = false;
          });
          print('number verified');
        },
        verificationFailed: (error) {
          setState(() {
            _isLoading = false;
          });
          print('error = ${error.code}');
          if (error.code == 'invalid-phone-number') {
            verificationFailed('Invalid phone number');
          }
        },
        codeSent: (verificationId, forceResendingToken) {
          setState(() {
            _isLoading = false;
          });
          otpDialogBox(verificationId, model);
        },
        codeAutoRetrievalTimeout: (verificationId) {
          setState(() {
            successful = true;
            _isLoading = false;
          });
          print('Timed out $verificationId');
          // verificationFailed('Time out. Code has expired');
        },
      );
    } on FirebaseAuthException catch (e) {
      print('exceptionError = ${e.code}');
      if (e.code == 'too-many-requests') {
        setState(() {
          errorMessage = 'Too many request. Try again later';
          _isLoading = false;
        });
      }
      return {'successful': successful, 'message': errorMessage};
    }
  }

  verificationFailed(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ERROR'),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  otpDialogBox(String verificationId, Models model) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text('Enter your OTP'),
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                decoration: InputDecoration(
                  border: new OutlineInputBorder(
                    borderRadius: const BorderRadius.all(
                      const Radius.circular(30),
                    ),
                  ),
                ),
                onChanged: (value) {
                  smsCode = value;
                },
              ),
            ),
            contentPadding: EdgeInsets.all(10.0),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await signIn(
                      smsCode: smsCode, verificationId: verificationId, model: model);
                },
                child: Text(
                  'Submit',
                ),
              ),
            ],
          );
        });
  }

  Future<void> signIn(
      {String verificationId, String smsCode, Models model}) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId, smsCode: smsCode);
    await FirebaseAuth.instance.signInWithCredential(credential).then((value) {
      if (value.user.uid != null) {
        String number = _infoData['number'];
        String _number = number.replaceAll('+234', '');
        model.signUp(
            user: value.user,
            number: _number,
            email: _infoData['email'],
            password: _infoData['password'],
            userType: _infoData['type']).then((value) {
              alertDialog(value);
        });
        setState(() {
          successful = true;
        });
      }
    });
  }

  alertDialog(Map<String, dynamic> value) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        elevation: 2,
        title: Text('Message!'),
        content: Text(value['message']),
        actions: [
          Container(
            color: Colors.green,
            padding: EdgeInsets.all(2),
            child: TextButton(
              child: Text('OK'),
              onPressed: () {
                if (value['success'] == false) {
                  widget.signUp == true
                      ? Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Login(signUp: true),
                          ))
                      : Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, 'login');
                }
              },
            ),
          )
        ],
      ),
    );
  }

  TextEditingController controller = TextEditingController();
  bool secure = true;

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height / 2.5;

    return Scaffold(
      backgroundColor: Colors.grey,
      body: Stack(
        children: [
          Container(
            color: Theme.of(context).primaryColor,
            height: height,
            child: Center(
              child: Text(
                'Test Project',
                style: TextStyle(
                    fontSize: 30,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Material(
                  borderRadius: BorderRadius.circular(30),
                  elevation: 30,
                  child: Column(
                    children: [
                      Form(
                        key: formKey,
                        child: ScopedModelDescendant<Models>(
                          builder: (context, child, Models model) {
                            return Column(
                              children: [
                                SizedBox(height: 30),
                                widget.signUp == true
                                    ? SignUp(
                                        setType: setType,
                                        setNumber: setNumber,
                                      )
                                    : Container(),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 32),
                                  child: Material(
                                    elevation: 2,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(30)),
                                    child: TextFormField(
                                      controller: controller,
                                      onChanged: (value) {
                                        setState(() {
                                          _infoData['email'] = value;
                                        });
                                      },
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) => value.length == 0
                                          ? 'enter email'
                                          : null,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: widget.signUp != true
                                            ? 'Email/Phone number'
                                            : 'email',
                                        prefixIcon: Icon(
                                          Icons.email,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 25, vertical: 13),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 32),
                                  child: Material(
                                    elevation: 2,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(30)),
                                    child: TextFormField(
                                      onChanged: (value) {
                                        setState(() {
                                          _infoData['password'] = value;
                                        });
                                      },
                                      keyboardType: TextInputType.text,
                                      obscureText: secure,
                                      validator: (value) => value.length == 0
                                          ? 'enter password'
                                          : null,
                                      decoration: InputDecoration(
                                        suffixIcon: IconButton(
                                          icon: secure
                                              ? Icon(Icons.visibility)
                                              : Icon(Icons.visibility_off),
                                          onPressed: () {
                                            setState(() {
                                              secure = !secure;
                                            });
                                          },
                                        ),
                                        border: InputBorder.none,
                                        hintText: 'password',
                                        prefixIcon: Icon(
                                          Icons.lock,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 25, vertical: 13),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 25),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 32),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(100)),
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    child: model.isLoading == true || _isLoading
                                        ? Center(
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 5),
                                              child: CircularProgressIndicator(
                                                backgroundColor: Colors.white,
                                              ),
                                            ),
                                          )
                                        : TextButton(
                                            child: Text(
                                              widget.signUp == true
                                                  ? 'SignUp'
                                                  : 'Login',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 18),
                                            ),
                                            onPressed: () => _signIn(model)),
                                  ),
                                ),
                                SizedBox(height: 20),
                                widget.signUp == true
                                    ? Container()
                                    : Center(
                                        child: TextButton(
                                          child: Text(
                                            'FORGOT PASSWORD ?',
                                            style: TextStyle(
                                                color: Colors.redAccent,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700),
                                          ),
                                          onPressed: () {},
                                        ),
                                      ),
                                SizedBox(height: 30),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("Don't have an Account ?"),
                                    TextButton(
                                        child: Text(
                                            widget.signUp == true
                                                ? 'Sign In'
                                                : 'Sign Up',
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontWeight: FontWeight.w500,
                                                decoration:
                                                    TextDecoration.underline)),
                                        onPressed: () {
                                          Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    widget.signUp == true
                                                        ? Login()
                                                        : Login(
                                                            signUp: true,
                                                          ),
                                              ));
                                        }),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
