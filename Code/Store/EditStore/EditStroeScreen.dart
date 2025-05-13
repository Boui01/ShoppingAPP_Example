import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shopping_app/Model/store.dart';

class EditStoreScreen extends StatefulWidget {
  final int storeID;
  const EditStoreScreen({super.key , required this.storeID});

  @override
  State<EditStoreScreen> createState() => _EditStoreScreenState();
}

class _EditStoreScreenState extends State<EditStoreScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Store store = Store.defaultValue();
  File? currentImage;
  final ImagePicker _picker = ImagePicker();

  Future<List> _getData() async {
    final storeDoc = await FirebaseFirestore.instance
                           .collection("store")
                           .where("id_store" , isEqualTo: widget.storeID)
                           .get();
    return storeDoc.docs.map((doc) => doc.data()).toList();            
  }

  void _getStore() async {
    final storeDoc = await FirebaseFirestore.instance
                           .collection("store")
                           .where("id_store" , isEqualTo: widget.storeID)
                           .get();
    setState(() {
      store = Store.fromJson(storeDoc.docs.first.data());
    });
  }

  // ------------- ถ่ายรูป -------------------
  Future<void> _uploadImage(Function(void Function()) dialogSetState) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      //Uint8List imageBytes = await imageFile.readAsBytes(); // Convert to bytes

      // อัปเดต state ของ Dialog และของ widget หลัก
      dialogSetState(() {
        currentImage = imageFile;
      });

      // ถ้าอยากให้ widget หลักเปลี่ยนด้วย (เช่น profile page เปลี่ยน)
      setState(() {
        currentImage = imageFile;
      });
    }
  }

  // ---------------------------------- แก้ไขรูปภาพ Store ----------------------------------
  Future _changeImage( context , String image ) {
    // ---- reset image ----
    setState(() {
      currentImage = null;
    });

    // --------------- แสดง Dialog ----------------
    final ShowPopup = showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( 
          builder: (context, setDialog) =>
            AlertDialog(
            title: Text("รูปใหม่"),
            content: Column(
              children: [
                currentImage != null 
                ? Image.file(currentImage! , width: 200, height: 150,)
                : Image.network(image , width: 200, height: 150,),
                ElevatedButton(
                  onPressed: () => _uploadImage(setDialog) ,
                  child: Text("อัพโหลด"),              
                )
              ],
            ),
            actions: [
              TextButton(
                child: Text("ตกลง"),
                onPressed: () {
                  setState(() {
                    //store.image = image;
                  });
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text("ยกเลิก"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          )
        );
      }
    );
    
    return ShowPopup;
  }

  Future<bool> _updateStore() async {
    try{
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();

        final storeDoc = await FirebaseFirestore.instance.collection("store").doc(store.id_store.toString()).get();
        
        if (storeDoc.exists) {
          storeDoc.reference.update({
            "name": store.name,
            "description": store.description,
            "type" : store.type,
            "image": "", //store.image,
            "image_url": store.image_url,
            "updated_at": Timestamp.now(),
          });
        }

        return true;
      }

      return false;
    }
    catch(e){
      print("error Edite Store Screeen : $e");
      return false;
    }
  }


  @override
  void initState() {
    super.initState();
    _getStore();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("แก้ไขร้านค้า"),
      ),
      body: FutureBuilder<List>(
        future: _getData(), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่มีข้อมูล'));
          }

          return Form(
                  key: _formKey,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ------------------------ รูปภาพ ------------------------
                        store.image_url != null 
                        ? GestureDetector(
                            onTap: () => _changeImage(context , store.image_url!),
                            child: Container(
                                width: double.infinity,
                                height: 200,
                                child: Image.network(store.image_url!)
                              ),
                          ) 
                        : const Text("ไม่มีรูปภาพ"),
                    
                        // ------------------------ ข้อมูลร้านค้า ----------------------
                        TextFormField(
                          initialValue: store.name,
                          decoration: const InputDecoration(
                            labelText: 'ชื่อร้านค้า',
                          ),
                          validator: (value) => value!.isEmpty ? 'กรุณากรอกชื่อร้านค้า' : null,
                          onChanged: (value) => store.name = value,
                          onSaved: (value) => store.name = value!,
                        ),
                    
                        TextFormField(
                          initialValue: store.description,
                          decoration: const InputDecoration(
                            labelText: 'รายละเอียด',
                          ),
                          validator: (value) => value!.isEmpty ? 'กรุณากรอกรายละเอียด' : null,
                          onChanged: (value) => store.description = value,
                          onSaved: (value) => store.description = value!,
                        ),
                    
                        TextFormField(
                          initialValue: store.type,
                          decoration: const InputDecoration(
                            labelText: 'ประเภทร้านค้า',
                          ),
                          validator: (value) => value!.isEmpty ? 'กรุณากรอกประเภทร้านค้า' : null,
                          onChanged: (value) => store.type = value,
                          onSaved: (value) => store.type = value!,
                        ),

                        // ----------------------- ข้อความเวลา ----------------------------
                        Container(
                          margin: EdgeInsets.all(5),
                          child: Text("ตั้งแต่ : ${store.created_at.toDate().day}/${store.created_at.toDate().month}/${store.created_at.toDate().year}" , style: TextStyle(fontSize: 16),)
                        ),

                        Container(
                          margin: EdgeInsets.all(5),
                          child: Text("อัพเดตล่าสุด : ${store.updated_at.toDate().day}/${store.updated_at.toDate().month}/${store.updated_at.toDate().year}", style: TextStyle(fontSize: 16),)
                        ),

                        // ----------------------- ปุ่มบันทึก ----------------------------
                        Center(
                          child: ElevatedButton(
                            onPressed: () => _updateStore()
                                            .then( (onValue) {
                                              if (onValue) {
                                                final snackBar = SnackBar(content: Text("บันทึกสําเร็จ"));
                                                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                                return true;
                                              }
                                              else{
                                                final snackBar = SnackBar(content: Text("บันทึกไม่สําเร็จ"));
                                                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                                return false;
                                              }
                                            })
                                            .then( (onValue) => {
                                              if (onValue) {
                                                setState(() {
                                                  _getStore();
                                                })
                                              }
                                            })
                            , 
                            child: Text("บันทึก")
                          ),
                        )
                    
                      ]
                      ,
                    ),
                  ),
                );
        },
      ),
    );
  }
}