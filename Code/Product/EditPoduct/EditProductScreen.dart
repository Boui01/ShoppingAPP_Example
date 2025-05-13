import 'dart:io';
//import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shopping_app/Model/product.dart';
import 'package:shopping_app/Model/product_type.dart';

class EditProductScreen extends StatefulWidget {
  final int productID;
  const EditProductScreen({super.key , required this.productID});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Product productEdit = Product.defaultValue();
  List<ProductType> productTypeEdit = [];
  bool isChecked = false;
  Map<String , Object> EditErrorId = {"id" : 0  , "position" : ""};

  File? currentImage;
  final ImagePicker _picker = ImagePicker(); // Image picker instance


  @override
  void initState() {
    super.initState();
  }

  Future<List> _getData() async {
    try {
      final productList = [];
      final productDoc = await FirebaseFirestore.instance.collection("product").where("id_product", isEqualTo: widget.productID).get();


      for ( var product in productDoc.docs){
        final productTypeDoc = await FirebaseFirestore.instance.collection("product_type").where("product_id", isEqualTo: product.data()["id_product"]).get();
        final productTypeList = [];

        for ( var productType in productTypeDoc.docs){
          productTypeList.add( ProductType.fromJson( productType.data() ) ); 
        }

        productList.add({
          "product" : Product.fromJson(product.data()),
          "product_type" : productTypeList
        });
      }


      return productList;
    } 
    catch (e) {
      print("error Edite Product Screeen : $e");
      return [];
    }
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

  // ---------------------------------- แก้ไขรูปภาพ ProductType ----------------------------------
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
          builder: (context, setState) =>
            AlertDialog(
            title: Text("รูปใหม่"),
            content: Column(
              children: [
                currentImage != null 
                ? Image.file(currentImage! , width: 200, height: 150,)
                : Image.network(image , width: 200, height: 150,),
                ElevatedButton(
                  onPressed: () => _uploadImage(setState) ,
                  child: Text("อัพโหลด"),              
                )
              ],
            ),
            actions: [
              TextButton(
                child: Text("ตกลง"),
                onPressed: () {
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

// ---------------------------------------------------- Function Product  ----------------------------------------------------

  Future<bool> _updateProduct() async {
    if(_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try{
        final productDoc = await FirebaseFirestore.instance.collection("product").where("id_product", isEqualTo: widget.productID).get();

        if (productDoc.docs.isNotEmpty) {
        
          productDoc.docs.first.reference.update({
            "name": productEdit.name,
            "description": productEdit.description,
            "type" : productEdit.type,
            "updated_at": Timestamp.now(),
          });
          /*final showAlert = SnackBar(content: Text("แก้ไขสินค้าสําเร็จ"));


          return ScaffoldMessenger.of(context).showSnackBar(showAlert);*/
          return true;

        }
        else{
          return false;
        }
      }
      catch(e){
        print("error Edite Product Screeen : $e");
        return false;
      }
    }
    else{
      return false;
    }
  }




// -------------------------------------------------- Function Product Type ----------------------------------------------------

  // ----------------------- อัพเดต Product Type -------------------------
  Future<bool> _updateProductType( ProductType productType ) async {
    // ------------ ตรวจสอบข้อมูลที่กรอก ------------
    if ( productType.name.isEmpty) {
      setState(() {
        EditErrorId["id"] = productType.id_product_type;
        EditErrorId["position"] = "name";
      });
      return false;
    }
    else if ( productType.amount == 0  ) {
      setState(() {
        EditErrorId["id"] = productType.id_product_type;
        EditErrorId["position"] = "amount";
      });
      return false;
    }
    else if ( productType.price == 0 ) {
      setState(() {
        EditErrorId["id"] = productType.id_product_type;
        EditErrorId["position"] = "price";
      });
      return false;      
    }

    setState(() {
      EditErrorId["id"] = 0;
      EditErrorId["position"] = "";
    });
    


    try{
      var newData = {
        "id_product_type": productType.id_product_type,
        "product_id": productType.product_id ,
        "name": productType.name,
        "amount": productType.amount,
        "price": productType.price,
        "image": "https://beautytribe.com/cdn/shop/files/image-skincare-clear-cell-clarifying-salicylic-gel-cleanser-7.4ml_819984016521.jpg?v=1745408003&width=1500",
        "created_at": productType.created_at,
        "updated_at":  productType.updated_at,
      };
      await FirebaseFirestore.instance.collection("product_type").doc(productType.id_product_type.toString()).update(newData);

      return true;
    }
    catch(e){
      print("error Edite Product Screeen : $e");
      return false;
    }
  }

  // ----------------------- ลบ Product Type -------------------------  
  Future _handleDeleteProductType(ProductType productType) {
    void _deleteProductType() {
      FirebaseFirestore.instance.collection("product_type").doc(productType.id_product_type.toString()).delete();
    }

    final ShowDialog = showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("ลบสินค้า"), 
          content: Text("คุณต้องการลบสินค้านี้หรือไม่"),
          actions: [
            TextButton(
              child: Text("ตกลง"),
              onPressed: () {
                _deleteProductType();
                Navigator.of(context).pop();
                setState(() {
                    _getData();
                });
              },
            ),
            TextButton(
              child: Text("ยกเลิก"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ]
        );
      }
    );

    return ShowDialog;
  
  }

  // -------------------------- สร้าง Product Type ---------------------------
  Future<ScaffoldFeatureController<SnackBar, SnackBarClosedReason>> _createProductType(  ProductType productType ) async {
    try {
      final productTypeDoc = await FirebaseFirestore.instance.collection("product_type").orderBy("id_product_type", descending: true).limit(1).get();
      final productTypeID = productTypeDoc.docs.isNotEmpty ? productTypeDoc.docs.first.data()["id_product_type"] : 1;


      if (productTypeDoc.docs.isNotEmpty) {

        final productTypeId = productTypeID + 1;

        var newData = {
          "id_product_type": productTypeId,
          "product_id": widget.productID ,
          "name": productType.name,
          "amount": productType.amount,
          "price": productType.price,
          "image": "https://beautytribe.com/cdn/shop/files/image-skincare-clear-cell-clarifying-salicylic-gel-cleanser-7.4ml_819984016521.jpg?v=1745408003&width=1500",
          "created_at": productType.created_at,
          "updated_at":  productType.updated_at,
        };
        await FirebaseFirestore.instance.collection("product_type").doc(productTypeId.toString()).set(newData);

        final showAlert = SnackBar(content: Text("เพิ่มสินค้าสําเร็จ"));

        return ScaffoldMessenger.of(context).showSnackBar(showAlert);
      
      }
      else{
        final showAlert = SnackBar(content: Text("เพิ่มสินค้าไม่สําเร็จ"));
        return ScaffoldMessenger.of(context).showSnackBar(showAlert);
      }
    } 
    catch (e) {
      final showAlert = SnackBar(content: Text("เพิ่มสินค้าไม่สําเร็จ"));

      return ScaffoldMessenger.of(context).showSnackBar(showAlert);
    }
  }


  // ---------------------------- แสดง Dialog เพิ่ม ProductType  ----------------------------------
  Future _showDialogCreateProductType() {
    // ---- reset image ----
    setState(() {
      currentImage = null;
    });

    final ProductType productType = ProductType.defaultValue();
    // ---- แสดง Dialog ----
    final ShowDialog =  showDialog(
      context: context, 
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDiaglog) => AlertDialog(
            title: Text("เพิ่มสินค้า"),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------ Field -------------------
                Container(
                  margin: EdgeInsets.all(10),
                  child: TextFormField(
                    initialValue: productType.name,
                    decoration: const InputDecoration(labelText: 'ชื่อสินค้า'),
                    validator: (value) => value!.isEmpty ? 'กรุณากรอกชื่อสินค้า' : null,
                    onChanged: (value) => productType.name = value,
                    onSaved: (value) => productType.name = value!,
                  ),
                ),
          
                Container(
                  margin: EdgeInsets.all(10),
                  child: TextFormField(
                    initialValue: productType.amount.toString(),
                    decoration: const InputDecoration(labelText: 'จำนวนสินค้า'),
                    validator: (value) => value!.isEmpty ? 'กรุณากรอกจำนวนสินค้า' : null,
                    onChanged: (value) => productType.amount = value.isNotEmpty ? int.parse(value) : 0,
                    onSaved: (value) => productType.amount = value!.isNotEmpty ? int.parse(value) : 0,
                  ),
                ),
          
                Container(
                  margin: EdgeInsets.all(10),
                  child: TextFormField(
                    initialValue: productType.amount.toString(),
                    decoration: const InputDecoration(labelText: 'ราคาสินค้า'),
                    validator: (value) => value!.isEmpty ? 'กรุณากรอกราคาสินค้า' : null,
                    onChanged: (value) => productType.price = value.isNotEmpty ? int.parse(value) : 0,
                    onSaved: (value) => productType.price = value!.isNotEmpty ? int.parse(value) : 0,
                  ),
                ),

                Text("ตั้งแต่ : ${productType.created_at.toDate().day}/${productType.created_at.toDate().month}/${productType.created_at.toDate().year}"),
                Text("ล่าสุด : ${productType.updated_at.toDate().day}/${productType.updated_at.toDate().month}/${productType.updated_at.toDate().year}"),
          
                // ------------------ Image -------------------
                currentImage != null 
                ? Center(
                  child: Container(
                      margin: EdgeInsets.all(10),
                      width: 150,
                      height: 150,
                      child: Image.file( currentImage! )
                    ),
                )
                : Text("No image selected"),

                 // ------------------ Image button -------------------
                Center(
                  child: ElevatedButton(
                    onPressed: () => _uploadImage(setStateDiaglog), 
                    child: Text("อัพโหลดรูปภาพ")
                  ),
                )
                
            ]),
            actions: [
              TextButton(
                child: Text("ตกลง"),
                onPressed: () {
                  _createProductType(productType);
                  Navigator.of(context).pop();
                  setState( () { 
                    _getData(); 
                  });
                },
              ),
              TextButton(
                child: Text("ยกเลิก"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          ),
        );
      });

    return ShowDialog;
  }


  /// ---------------------------------------------------------------- แสดงหน้าหลัก -----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("แก้ไขสินค้า"),),
      body: SingleChildScrollView(
        child: FutureBuilder(
          future: _getData() ,
           builder: (context, snapshot) {
             if(snapshot.connectionState == ConnectionState.waiting) {
               return const Center(child: CircularProgressIndicator());
             } else if(snapshot.hasError) {
               return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
             } else if(!snapshot.hasData || snapshot.data!.isEmpty) {
               return const Center(child: Text('ไม่มีข้อมูล')); 
             }
            return Form(
              key: _formKey ,
              child: Column(
                children: [
                  ...snapshot.data!.map( (product)  {
                    final productData = product["product"];
                    final productTypeData = product["product_type"];

                    return  Column(
                      children: [
                        Container(
                          margin: EdgeInsets.all(10),
                          child: TextFormField(
                            initialValue: productData.name,
                            validator: (value) => value!.isEmpty ? 'กรุณากรอกชื่อสินค้า' : null,
                            onChanged: (value) => productEdit.name = value.isEmpty 
                            ? productData.name 
                            : value,
                            onSaved: (newValue) => productEdit.name = newValue!.isEmpty 
                            ? productData.name 
                            : newValue,
                            decoration: InputDecoration(
                              label: const Text("ชื่อสินค้า"),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),                      
                          ),
                        ),

                        Container(
                          margin: EdgeInsets.all(10),
                          child: TextFormField(
                            initialValue: productData.description,
                            validator: (value) => value!.isEmpty ? 'กรุณากรอกรายละเอียดสินค้า' : null,
                            onChanged: (value) => productEdit.description = value.isEmpty 
                            ? productEdit.description = productData.description 
                            : productEdit.description = value,
                            onSaved: (newValue) => productEdit.description = newValue!.isEmpty  
                            ? productData.description 
                            : newValue,
                            decoration: InputDecoration(
                              label: const Text("รายละเอียด"),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),

                        Container(
                          margin: EdgeInsets.all(10),
                          child: TextFormField(
                            initialValue: productData.type,
                            validator: (value) => value!.isEmpty ? 'กรุณากรอกประเภทสินค้า' : null,
                            onChanged: (value) => productEdit.type  = value.isEmpty   
                            ?  productData.type 
                            :  value,
                            onSaved: (newValue) => productEdit.type  = newValue!.isEmpty   
                            ? productData.type 
                            : newValue,
                            decoration: InputDecoration(
                              label: const Text("ประเภทสินค้า"),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),

                        Row(
                          children: [
                            Checkbox(value: isChecked, onChanged: (value) => setState(() { isChecked = value!;})),
                            Text("แก้ไขข้อมูลประเภทสินค้า"),
                          ],
                        ),



                        isChecked ? 
                        // ------------------------------------ Product Type --------------------------------------------
                           Container(
                            margin: EdgeInsets.all(5),
                            child: GridView(
                              shrinkWrap: true, // ✅ สำคัญมาก: ให้ GridView อยู่ใน scroll ได้
                              physics: NeverScrollableScrollPhysics(), // ✅ ปิด scroll ของ GridView
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // 2 columns (Adjust as needed)
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.45, // Adjust based on item design
                              ),
                              children: [    
                          
                              // ------------------------ แสดง Card ----------------------
                              ...productTypeData.map( (productType) {
                                
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Card(                                 
                                    child: Container(
                                      margin: EdgeInsets.all(10),
                                      child: Column(
                                        children: [

                                          productType.image_url != null
                                          ? GestureDetector(
                                              onTap: () {
                                                _changeImage(context, productType.image_url);
                                              },
                                              child: Image.network(productType.image_url, width: 100, height: 100, fit: BoxFit.cover)
                                            )
                                          : Icon(Icons.image_not_supported),
                                      
                                          Text("${productType.id_product_type}" , style: TextStyle( fontSize: 20)),
                                      
                                          Column(
                                            children: [
                                              Container(
                                                width: 150,
                                                margin: EdgeInsets.all(5),
                                                child: TextFormField(
                                                  initialValue: productType.name,
                                                  onChanged: (value) => productType.name = value,
                                                  onSaved: (newValue) => productType.name = newValue!,
                                                  decoration: InputDecoration(
                                                    label: const Text("ชื่อประเภทสินค้า"),
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // ----------- เช็ค Error -------------
                                              EditErrorId["id"] ==  productType.id_product_type && EditErrorId["position"] == "name" 
                                              ? Text("กรุณากรอกชื่อประเภทสินค้า"  , style: TextStyle(color: Colors.red , fontSize: 12),)
                                              : Container(),
                                            ],
                                            
                                          ),
                                      
                                          
                                          Focus(
                                            onFocusChange: (hasFocus) {
                                              if (!hasFocus) {
                                                // Reset the keyboard state when the focus is lost
                                                FocusScope.of(context).unfocus();
                                              }
                                            },
                                            child: Container(
                                              width: 150,
                                              margin: EdgeInsets.all(5),
                                              child: TextFormField(
                                                initialValue: productType.amount.toString(),
                                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                onChanged: (value) => productType.amount = value.isEmpty ? 0 : int.parse(value),
                                                onSaved: (newValue) => productType.amount = newValue!.isEmpty ? 0 : int.parse(newValue),
                                                decoration: InputDecoration(
                                                  label: const Text("จำนวนสินค้า"),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // ----------- เช็ค Error -------------
                                          EditErrorId["id"] ==  productType.id_product_type && EditErrorId["position"] == "amount" 
                                          ? Text("กรุณากรอกจำนวนสินค้า และ ไม่ใช่ 0"  , style: TextStyle(color: Colors.red , fontSize: 10),)
                                          : Container(),

                                                            
                                          Column(
                                            children: [
                                              Focus(
                                                onFocusChange: (hasFocus) {
                                                  if (!hasFocus) {
                                                    // Reset the keyboard state when the focus is lost
                                                    FocusScope.of(context).unfocus();
                                                  }
                                                },                                                
                                                child: Container(
                                                  width: 150,
                                                  margin: EdgeInsets.all(5),
                                                  child: TextFormField(
                                                    initialValue: productType.price.toString(),
                                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                    onChanged: (value) => productType.price = value.isEmpty ? 0 : int.parse(value),
                                                    onSaved: (newValue) => productType.price = newValue!.isEmpty ? 0 : int.parse(newValue),
                                                    decoration: InputDecoration(
                                                      label: const Text("ราคาสินค้า"),
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // ----------- เช็ค Error -------------
                                              EditErrorId["id"] ==  productType.id_product_type && EditErrorId["position"] == "price" 
                                              ? Text("กรุณากรอกราคาสินค้า ไม่ใช่ 0"  , style: TextStyle(color: Colors.red , fontSize: 12),)
                                              : Container(),
                                            ],
                                          ),
                                                            
                                          Row(
                                            children: [
                                              ElevatedButton(
                                                onPressed: () => 
                                                  _updateProductType(productType)
                                                  .then( (onValue){
                                                    if (onValue) {
                                                      SnackBar snackBar = SnackBar(content: Text("แก้ไขประเภทสินค้าสําเร็จ"));
                                                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                                      return true;
                                                    }
                                                    else {
                                                      SnackBar snackBar = SnackBar(content: Text("แก้ไขประเภทสินค้าไม่สําเร็จ"));
                                                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                                      return false;
                                                    }
                                                  })
                                                  .then( (onValue) => 
                                                    onValue 
                                                    ? setState(() {
                                                        _getData();
                                                      })
                                                    : null
                                                  )
                                                  , 
                                                child: Text("บันทึกสินค้า")
                                              ),
                                              IconButton(
                                                onPressed: () => _handleDeleteProductType(productType) ,
                                                icon: Icon(Icons.delete),
                                                color: Colors.red,
                                              )
                                            ],
                                          )
                                      
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ]
                           ),
                        )
                        : Container(),


                      ],
                    );
                  }),
                  // ------------------ ปุ่มบันทึก ------------------
                  !isChecked 
                  ? ElevatedButton(
                    onPressed: ()  async =>
                     _updateProduct()
                      // ---- เช็้คว่าบันทึกสินค้าสําเร็จหรือไม่ ----
                      .then( (onValue){
                        if (onValue) {
                          SnackBar snackBar = SnackBar(content: Text("แก้ไขสินค้าสําเร็จ"));
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                          return true;
                        }
                        else{
                          SnackBar snackBar = SnackBar(content: Text("แก้ไขสินค้าไม่สําเร็จ"));
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                          return false;
                        }
                      })
                      // ---- ถ้าบันทึกสินค้าสําเร็จจะโหลดข้อมูลใหม่ ----
                      .then((onValue) => 
                        onValue 
                        ? setState(() { _getData(); }) 
                        : null
                      ),

                    child: Text("บันทึก"),
                  )

                  // ------------------ ปุ่มเพิ่มประเภทสินค้า ------------------
                  : Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border( bottom: BorderSide( width: 5, color: Color.fromARGB(255, 180, 180, 180)) )
                    ),
                    child: IconButton(
                      onPressed: _showDialogCreateProductType ,
                      icon: Icon(Icons.add),
                    ),
                  ),
                ],
              ),
            );

           }             
        ),
      )
    );
  }
}