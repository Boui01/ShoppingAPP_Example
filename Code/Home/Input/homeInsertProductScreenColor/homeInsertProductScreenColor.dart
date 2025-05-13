import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shopping_app/Model/product_type.dart';

class HomeInsertProductScreenColor extends StatefulWidget {
  final int productID;
  const HomeInsertProductScreenColor({super.key , required this.productID});

  @override
  State<HomeInsertProductScreenColor> createState() => _HomeInsertProductScreenColorState();
}

class _HomeInsertProductScreenColorState extends State<HomeInsertProductScreenColor> {
  ProductType productType = ProductType.defaultValue();
  List productTypeList = [];
  bool productMoreCheckbox = false;

  File? _image;
  // ignore: unused_field
  late Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker(); // Image picker instance

  final Formkey = GlobalKey<FormState>();

  final productID = 0 ;
  @override
  void initState() {
    super.initState();
    productTypeList = [];

  }
  
  //------------- เลือก image จาก gallery -----------------
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        Uint8List imageBytes = await imageFile.readAsBytes(); // Convert to bytes

       setState(() {
        _image = imageFile;
        productType.image = imageFile ;
        _imageBytes = imageBytes; // Store image bytes
      });

    }
  }

  //---------------  เลือกรูปภาพจากการถ่าย --------------------
  void _captureImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      Uint8List imageBytes = await imageFile.readAsBytes(); // Convert to bytes
      setState(() {
        _image = imageFile;
        productType.image = _image!;
        _imageBytes = imageBytes;
      });

    }
  }


// ------------------ ส่งข้อมูลไปยังฐานข้อมูล ----------------
  Future<void> _submit() async {
    // สร้างข้อมูลปัจจูบันเข้าไปใน list
    productTypeList.add(productType);

    // รับค่าเช็ค id ปัจจุบัน และ ตั้งค่าให้เป็น id ปัจจุบัน
    final querySnapshot = await FirebaseFirestore.instance.collection("product_type").orderBy("id_product_type", descending: true).limit(1).get();
    final productTypeID = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first.data()["id_product_type"] : 1;


    //---------------- loop ส่งข้อมูล List ------------------
    for (int i = 0; i < productTypeList.length; i++) {
      // สร้าง product data
      productTypeList[i].id_product_type = productTypeID + i; // สร้างเลข id เพิ่มขึ้นทีล่ะ 1 ตามจำนวน List
      productTypeList[i].product_id = widget.productID;// สร้าง id product

      // เปลีี่ยนข้อมูลสำหรับส่งไปยัง firebase
      var newData = {
        "id_product_type": productTypeList[i].id_product_type,
        "product_id": productTypeList[i].product_id ,
        "name": productTypeList[i].name,
        "amount": productTypeList[i].amount,
        "price": productTypeList[i].price,
        "image": "https://beautytribe.com/cdn/shop/files/image-skincare-clear-cell-clarifying-salicylic-gel-cleanser-7.4ml_819984016521.jpg?v=1745408003&width=1500",//productTypeList[i].image.toString(),
        "created_at": productTypeList[i].created_at,
        "updated_at":  productTypeList[i].updated_at,
      };
      try {
        await FirebaseFirestore.instance.collection("product_type").get()
            .then((querySnapshot) {
              productTypeList[i].id_product_type = querySnapshot.docs.length + 1;
            })
            .then((value) {
              FirebaseFirestore.instance.collection("product_type")
                .doc(productTypeList[i].id_product_type.toString())
                .set(newData);
            });
      } catch (e) {
        print('Error occurred: $e');
      }
    }

    Navigator.pushReplacementNamed(context, "/");
  }

  // ------------------ ทำข้อมูลใหม่ใส่ List ----------------
  void _handleColor(){
    if (Formkey.currentState!.validate()) {
      // เก็บค่าข้อมูลจากอีกไฟล์ที่อยู่ใน form
      Formkey.currentState!.save();
      
      setState(() {
        // สร้างข้อมูลปัจจูบันเข้าไปใน list
        productTypeList.add(productType);
        productType = ProductType.defaultValue();
        _image = null;
        productMoreCheckbox = false;
      });

      Formkey.currentState!.reset();
    }


  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Insert Product Color"),
      ),
      body: Container(
        child: Column(
          children: [              

              Form(
                key: Formkey,
                child: Column(
                  children: [
                    // -------------------- ชื่อสี -------------------------------
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'ชื่อสี'),
                      validator: (value) => value!.isEmpty ? 'กรุณากรอกชื่อสี' : null,
                      onChanged: (value) =>  productType.name = value,
                      onSaved: (newValue) => productType.name = newValue!,
                    ),



                    // ใช้ Focus แก้บัคลบข้อมูลหมดแล้ว error
                    Focus(
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) {
                          // Reset the keyboard state when the focus is lost
                          FocusScope.of(context).unfocus();
                        }
                      },
                      // -------------------- ราคา -------------------------------
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'ราคา'),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) => value!.isEmpty ? 'กรุณากรอกราคา' : null,
                        onChanged: (value) => productType.price = value.isNotEmpty ? int.parse(value) : 0 ,
                        onSaved: (newValue) => productType.price = newValue!.isNotEmpty ? int.parse(newValue) : 0,
                      ),
                    ),
                    



                    // ใช้ Focus แก้บัคลบข้อมูลหมดแล้ว error
                    Focus(
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) {
                          // Reset the keyboard state when the focus is lost
                          FocusScope.of(context).unfocus();
                        }
                      },
                      // -------------------- จำนวนสี -------------------------------
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'จำนวนสินค้า'),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) => value!.isEmpty ? 'กรุณากรอกจำนวนสินค้า' : null,
                        onChanged: (value) => productType.amount = value.isNotEmpty ? int.parse(value) : 0,
                        onSaved: (newValue) => productType.amount = newValue!.isNotEmpty ? int.parse(newValue) : 0,
                      ),
                    ),
                 

                    // ---------------------- รูปภาพ --------------------------------
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _image != null
                            ? Image.file(_image!, height: 200) // Show selected image
                            : Text('No image selected'),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              icon: Icon(Icons.photo_library),
                              label: Text("Pick from Gallery"),
                              onPressed: _pickImage,
                            ),
                            SizedBox(width: 10),
                            ElevatedButton.icon(
                              icon: Icon(Icons.camera_alt),
                              label: Text("Take Photo"),
                              onPressed: _captureImage,
                            ),
                          ],
                        ),
                      ],
                    ),  
                                        
                    // ---------------------- ตัวเลือกเพิ่มสี --------------------------------
                    CheckboxListTile(
                      value: productMoreCheckbox , 
                      onChanged: (value) => setState(() => productMoreCheckbox = value!), 
                      title: const Text("เพิ่มสี")
                    ),
                                        
                  ],
                ),
              ),



              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: productTypeList.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text("สี : ${productTypeList[index].name}"),
                      subtitle: Text("ราคา : ${productTypeList[index].price} จำนวน : ${productTypeList[index].amount}"),
                      leading: productTypeList[index].image != null
                        ? Image.file(productTypeList[index].image!, width: 50, height: 50)
                        : const Text("ไม่มีรูปภาพ"),
                    ),
                  );
                },
              ),
              // ---------------------- ส่งข้อมูล --------------------------------
              ElevatedButton(
                onPressed: 
                      () => {
                        productMoreCheckbox == true 
                          ? 
                            _handleColor()
                          : _submit()
                      },
                child: const Text("บันทึกข้อมูล"),
              ),

          ],
        ),
      ),
    );
  }
}