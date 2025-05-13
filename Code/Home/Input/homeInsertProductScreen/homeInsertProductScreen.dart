import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:shopping_app/Model/product.dart';

import 'package:shopping_app/Screen/Home/Input/homeInsertProductScreenColor/homeInsertProductScreenColor.dart';


class HomeInsertProductScreen extends StatefulWidget {
  const HomeInsertProductScreen({super.key});
  @override
  State<HomeInsertProductScreen> createState() =>
      _HomeInsertProductScreenState();
}

class _HomeInsertProductScreenState extends State<HomeInsertProductScreen> {
  Product product = Product.defaultValue();
  var productColorCheckbox = false;

  final FormKey = GlobalKey<FormState>();
  final auth = FirebaseAuth.instance;



  void _saveForm() async {
    if (FormKey.currentState!.validate()) {
      FormKey.currentState!.save();

      try {
        
        /* ----------- รับข้อมูล id store ------------ */
        await FirebaseFirestore.instance
            .collection("store")
            .where("seller_id", isEqualTo: auth.currentUser!.uid)
            .get()
            .then((onValue) {
              if (onValue.docs.isNotEmpty) {
                product.store_id = onValue.docs.first["id_store"];
              }
            });

        /* ----------- รับไอดีข้อมูลจากฐานข้อมูล ------------*/
        var lastID = 0;
        await FirebaseFirestore.instance
            .collection("product")
            .orderBy("id_product", descending: true)
            .limit(1)
            .get()
            .then((querySnapshot) {
              if (querySnapshot.docs.isNotEmpty) {
                lastID = querySnapshot.docs.first["id_product"];
              }
            });
        product.id_product = lastID + 1;

        /* ----------- สร้างข้อมูล product ------------ */
        await FirebaseFirestore.instance
            .collection("product")
            .doc(product.id_product.toString())
            .set(product.toJson())
            .then((_) {
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
                    "บันทึกข้อมูลสําเร็จ",
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
            .then( (onValue) {
              productColorCheckbox 
              ? Navigator.push(context, MaterialPageRoute(builder: (context) => HomeInsertProductScreenColor( productID: product.id_product,)))
              : null
              ;
              
            });
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
              "บันทึกข้อมูลผิดพลาด ${e}",
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
      appBar: AppBar(title: const Text("สร้างสินค้า")),
      body: Container(
        margin: EdgeInsets.all(30),
        child: Form(
          key: FormKey,
          child: Column(
            children: [
              // -------------------- ชื่อสินค้า -------------------------------
              TextFormField(
                decoration: const InputDecoration(labelText: 'ชื่อสินค้า'),
                validator:
                    (value) => value!.isEmpty ? 'กรุณากรอกชื่อสินค้า' : null,
                onChanged: (value) => product.name = value,
                onSaved: (newValue) => product.name = newValue!,
              ),
              // -------------------- รายละเอียด -------------------------------
              TextFormField(
                decoration: const InputDecoration(labelText: 'รายละเอียด'),
                validator:
                    (value) => value!.isEmpty ? 'กรุณากรอกรายละเอียด' : null,
                onChanged: (value) => product.description = value,
                onSaved: (newValue) => product.description = newValue!,
              ),
              // -------------------- ประเภท -------------------------------
              TextFormField(
                decoration: const InputDecoration(labelText: 'ประเภท'),
                validator: (value) => value!.isEmpty ? 'กรุณากรอกประเภท' : null,
                onChanged: (value) => product.type = value,
                onSaved: (newValue) => product.type = newValue!,
              ),

              /*  TextFormField(
                decoration: const InputDecoration(labelText: 'ลิงก์รูปภาพ'),
                validator:
                    (value) => value!.isEmpty ? 'กรุณากรอลิงก์รูปภาพ' : null,
                onChanged: (value) => product.image = value,
                onSaved: (newValue) => product.image = newValue!,
              ),*/

              // ---------------------- ตัวเลือกสี --------------------------------
              CheckboxListTile(
                value: productColorCheckbox , 
                onChanged: (value) => setState(() => productColorCheckbox = value!), 
                title: const Text("ตัวเลือกสี")
              ),

              
              // ---------------------- บันทึก -------------------------
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll(Colors.green),
                ),
                onPressed: _saveForm,
                child: Text("บันทึก"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
