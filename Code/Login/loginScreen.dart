import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:shopping_app/Model/userLogin.dart';
import 'package:shopping_app/Screen/Register/registerScreen.dart';

class LoginScreen extends StatefulWidget {
  final String checkContext ;
  const LoginScreen({super.key , required this.checkContext});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formkey = GlobalKey<FormState>();
  final Future<FirebaseApp> firebase = Firebase.initializeApp();
  UserLogin user = UserLogin( email : "", password : "");


  void _register() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return RegisterScreen();
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: firebase,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text("Error")),
            body: Center(child: Text('${snapshot.error}')),
          );
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            backgroundColor: Colors.white,
            // -------------- Appbar -------------------
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: Container(
                padding: const EdgeInsets.only(top: 40),
                // Decoration
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),

                // Text
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // ----------- Back button -----------------
                      Container(
                        width: 60,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border( right:BorderSide( width: 1 , color: const Color.fromARGB(255, 173, 173, 173))),

                        ),
                        child: IconButton(
                          onPressed: () {
                            widget.checkContext == "navBar"  
                            ? Navigator.pushReplacementNamed(context, '/home')
                            : Navigator.pop(context);
                          },
                          icon: Icon(Icons.exit_to_app),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                            iconColor: const Color.fromARGB(255, 31, 109, 199),
                          ),
                        ),
                      ),
                       // Text
                      Text(
                        "เข้าสู่ระบบ",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 52, 107, 201),
                        ),
                      ),
                      SizedBox(width: 60),
                    ],
                  ),
                ),
              ),
              
            ),
            body: Container(
              margin: EdgeInsets.all(50),
              //------------- Form -----------------
              child: Form(
                key: formkey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      // ----------- Field ---------------
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("อีเมลล์", style: TextStyle(fontSize: 22 , color: const Color.fromARGB(255, 77, 77, 77),fontWeight: FontWeight.bold , ),),
                          TextFormField(
                            validator:
                                MultiValidator([
                                  RequiredValidator(
                                    errorText: "กรุณาป้อนอีเมลด้วยครับ",
                                  ),
                                  EmailValidator(
                                    errorText: "กรุณาใส่อีเมลให้ถูกต้อง",
                                  ),
                                ]).call,
                            keyboardType: TextInputType.emailAddress,
                            onSaved: (String? email) {
                              if (email != null) {
                                user.email = email;
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("รหัสผ่าน", style: TextStyle(fontSize: 20 , color: const Color.fromARGB(255, 77, 77, 77),fontWeight: FontWeight.bold , )),
                          TextFormField(
                            validator:
                                RequiredValidator(
                                  errorText: "กรุณาป้อนอีเมลด้วยครับ",
                                ).call, // validator ตัวเสริม
                            obscureText: true, // ปิดมองเห็นรหัสผ่าน
                            onSaved: (String? password) {
                              if (password != null) {
                                user.password = password;
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 30),

                      //--------------- Button -----------------


                    /*  // ------ Register button ---------
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            iconColor: Colors.grey,
                          ),
                          onPressed: _register,
                          child: Text(
                            "Register",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 2, 112, 255),
                            ),
                          ),
                        ),*/
                        GestureDetector(
                          onTap: _register,
                          child: Row(
                            children: [
                              Text(
                                "ต้องการสมัครสมาชิกใหม่ ? ",
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 75, 75, 75),
                                ),
                              ),
                              Text(
                                "สมัครสมาชิก",
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 2, 112, 255),
                                ),
                              ),
                            ],
                          )
                        ),
                      SizedBox(height: 20),
                      Container(
                        width: 120,
                        height: 40,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(122, 63, 63, 63),
                              spreadRadius: -4,
                              blurRadius: 8,
                              offset: Offset(3, 7)
                            ),
                          ],
                          border: Border(bottom: BorderSide(width: 4 , color: const Color.fromARGB(255, 90, 89, 89))),
                          borderRadius: BorderRadius.circular(25)
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formkey.currentState!.validate()) {
                              formkey.currentState?.save();

                              // เช็คข้อมูลก่อนอัพไป Firebase
                              try {
                                await FirebaseAuth.instance
                                    .signInWithEmailAndPassword(
                                      email: user.email,
                                      password: user.password,
                                    )
                                    .then((value) {
                                      // สร้างตัวแจ้งเตือน
                                      showToastWidget(
                                        Container(
                                          margin: EdgeInsets.all(5),
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(
                                              255,
                                              255,
                                              252,
                                              252,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),

                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color.fromARGB(
                                                  255,
                                                  7,
                                                  7,
                                                  7,
                                                ).withOpacity(0.3),
                                                blurRadius: 3,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            "เข้าสู่ระบบเรียบร้อย",
                                            style: TextStyle(
                                              color: const Color.fromARGB(
                                                255,
                                                21,
                                                117,
                                                196,
                                              ),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),

                                        context: context,
                                        position: StyledToastPosition.bottom,
                                      );
                                      formkey.currentState?.reset();
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/home',
                                      );
                                    });
                              } on FirebaseAuthException catch (e) {
                                print(" Error message : ${e.message}");
                                // สร้างตัวแจ้งเตือน
                                showToastWidget(
                                  Container(
                                    margin: EdgeInsets.all(5),
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                        255,
                                        255,
                                        252,
                                        252,
                                      ),
                                      borderRadius: BorderRadius.circular(20),

                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color.fromARGB(
                                            255,
                                            7,
                                            7,
                                            7,
                                          ).withOpacity(0.3),
                                          blurRadius: 3,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      e.message == "The supplied auth credential is incorrect, malformed or has expired." ?
                                       "กรุณาใส่อีเมลล์หรือรหัสผ่านให้ถูกต้อง" 
                                      : 
                                       "อีเมลไม่ถูกต้อง" ,
                                      style: TextStyle(
                                        color: const Color.fromARGB(
                                          255,
                                          21,
                                          117,
                                          196,
                                        ),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  context: context,
                                  position: StyledToastPosition.bottom,
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color.fromARGB(
                              255,
                              27,
                              142,
                              196,
                            ),
                          ),
                          child: Text(
                            "เข้าสู่ระบบ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 42, 134, 209),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}