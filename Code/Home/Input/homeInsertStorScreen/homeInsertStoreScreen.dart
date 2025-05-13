import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:shopping_app/Model/store.dart';

class HomeInsertStoreScreen extends StatefulWidget {
  const HomeInsertStoreScreen({super.key});

  @override
  State<HomeInsertStoreScreen> createState() => _HomeInsertStoreScreenState();
}

class _HomeInsertStoreScreenState extends State<HomeInsertStoreScreen> {
  final FormKey = GlobalKey<FormState>();
  final Store store = Store.defaultValue();
  final auth = FirebaseAuth.instance;

  void _Insert() async {
    if (FormKey.currentState!.validate()) {
      FormKey.currentState!.save();

      try {
        /* ----------- รับข้อมูล userID ------------*/
        /*DocumentSnapshot userID =
            await FirebaseFirestore.instance
                .collection("seller_user")
                .doc(auth.currentUser!.uid)
                .get();*/

        store.seller_id = auth.currentUser!.uid /*userID["id_card_seller"]*/;
        /* ----------- รับไอดีข้อมูลจากฐานข้อมูล ------------*/
        var lastID = 0;
        await FirebaseFirestore.instance
            .collection("store")
            .orderBy("id_store", descending: true)
            .limit(1)
            .get()
            .then((querySnapshot) {
              if (querySnapshot.docs.isNotEmpty) {
                lastID = querySnapshot.docs.first["id_store"];
              }
            });

        store.id_store = lastID + 1;
        /* ----------- เพิ่มไอดีข้อมูล ------------*/
        await FirebaseFirestore.instance
            .collection("store")
            .doc(store.id_store.toString())
            .set(store.toJson())
            .then((onValue) {             
              return showToastWidget(
                Container(
                  margin: EdgeInsets.all(5),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 252, 252),
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
                    "บันทึกข้อมูลเรียบร้อย",
                    style: TextStyle(
                      color: const Color.fromARGB(255, 21, 117, 196),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                context: context,
                position: StyledToastPosition.bottom,
              );
            })            
            .then((onValue) => Navigator.pop(context));
      } catch (e) {
        showToastWidget(
          Container(
            margin: EdgeInsets.all(5),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 252, 252),
              borderRadius: BorderRadius.circular(20),

              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 7, 7, 7).withOpacity(0.3),
                  blurRadius: 3,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              "ผิดพลาดการบันทึกข้อมูล ${e}",
              style: TextStyle(
                color: const Color.fromARGB(255, 21, 117, 196),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          context: context,
          position: StyledToastPosition.bottom,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("สร้างร้านค้า")),
      body: Container(
        margin: EdgeInsets.all(30),
        child: Form(
          key: FormKey,
          child: Column(
            children: [
              Text("ชื่อร้านค้า"),
              TextFormField(
                decoration: const InputDecoration(labelText: 'ชื่อร้านค้า'),
                validator:
                    (value) => value!.isEmpty ? 'กรุณากรอกชื่อร้านค้า' : null,
                onChanged: (value) => store.name = value,
                onSaved: (newValue) => store.name = newValue!,
              ),

              SizedBox(height: 20),
              Text("รายละเอียด"),
              TextFormField(
                decoration: const InputDecoration(labelText: 'รายละเอียด'),
                validator:
                    (value) => value!.isEmpty ? 'กรุณากรอกรายละเอียด' : null,
                onChanged: (value) => store.description = value,
                onSaved: (newValue) => store.description = newValue!,
              ),

              TextFormField(
                decoration: const InputDecoration(labelText: 'ประเภทผลิตภัณฑ์'),
                validator:
                    (value) =>
                        value!.isEmpty ? 'กรุณากรอกประเภทผลิตภัณฑ์' : null,
                onChanged: (value) => store.type = value,
                onSaved: (newValue) => store.type = newValue!,
              ),

              SizedBox(height: 20),
              ElevatedButton(onPressed: _Insert, child: const Text("บันทึก")),
            ],
          ),
        ),
      ),
    );
  }
}
