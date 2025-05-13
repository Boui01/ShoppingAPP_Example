import 'dart:io';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/Model/product.dart';
import 'package:shopping_app/Model/product_type.dart';
import 'package:shopping_app/Model/store.dart';
import 'package:shopping_app/Screen/Comment/commentScreen.dart';
import 'package:shopping_app/Screen/Login/loginScreen.dart';
import 'package:shopping_app/Screen/Payment/paymentScreen.dart';
import 'package:shopping_app/Screen/Product/EditPoduct/EditProductScreen.dart';
import 'package:shopping_app/Screen/Store/StoreScreen.dart';

class ProductScreen extends StatefulWidget {
  final int productID;
  const ProductScreen({super.key, required this.productID});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late Product _product = Product.defaultValue();
  late bool _productScore = false;
  late Store _store = Store.defaultValue();
  final List _productType = [];
  final auth = FirebaseAuth.instance.currentUser ?? null;
  var userInformation = {"amount": 0 , "type" : 0}; // ข้อมูลผู้ซื้อ

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    // ---------------- รับข้อมูล -----------------------
    final docProduct = await FirebaseFirestore.instance
        .collection("product")
        .doc(widget.productID.toString())
        .get();
    final docProductScoreUser = await FirebaseFirestore.instance
        .collection("product_score")
        .where("product_id", isEqualTo: widget.productID)
        .where("buyer_id", isEqualTo: auth!.uid)
        .get();
    final docProductType = await FirebaseFirestore.instance
        .collection("product_type")
        .where("product_id", isEqualTo: widget.productID)
        .get();

    // --------- แปลงข้อมูลเข้าไปในตัวแปร ----------------
    if (docProduct.exists && docProductType.docs.isNotEmpty) {

      final docStore = await FirebaseFirestore.instance
        .collection("store")
        .where("id_store", isEqualTo: docProduct.data()!["store_id"])
        .get();
      
      final docProductScore = await FirebaseFirestore.instance
          .collection("product_score")
          .where("product_id", isEqualTo: widget.productID)
          .where("is_like", isEqualTo: true)
          .get();

      final docStoreScore = await FirebaseFirestore.instance
          .collection("product_score")
          .where("store_id", isEqualTo: docProduct.data()!["store_id"])
          .where("is_like", isEqualTo: true)
          .get();        


      setState(() {
        var dataProduct = docProduct.data() as Map<String, dynamic>;
        var dataProductType = docProductType.docs.map((doc) => doc.data()).toList();
        
        _product = Product.fromJson(dataProduct);
        // ------ ต้อง loop ข้อมูลในการใส่ product_type เพราะมีหลายข้อมูล -----
        for (var i = 0; i < dataProductType.length; i++) {
          final _productTypeCurrent = ProductType(
              id_product_type: dataProductType[i]["id_product_type"],
              product_id: dataProductType[i]["product_id"],
              name: dataProductType[i]["name"],
              amount: dataProductType[i]["amount"],
              price: dataProductType[i]["price"],
              image: File(''),
              image_url: dataProductType[i]["image"],
              created_at: dataProductType[i]["created_at"],
              updated_at: dataProductType[i]["updated_at"],
          );

          // ----------- เพิ่มข้อมูลเข้าไปใน list -----------
          _productType.add(_productTypeCurrent);
          
        }

         // -------------- แปลงข้อมูลร้านค้า -------------
        if (docStore.docs.isNotEmpty ) {
          _store = Store.fromJson({
            ...docStore.docs.first.data(),
            // -------- เปลี่ยน score ให้เป็นจํานวนคนที่คะแนนสินค้า --------
            "score":  docStoreScore.docs.isNotEmpty 
                      ? docStoreScore.docs.length 
                      : 0
          });
        }

        // --------- Product Score ---------
        if (docProductScore.docs.isNotEmpty) {
          _product.score = docProductScore.docs.length;
        }

        // --------- ตรวจสอบสมาชิกว่ามีกดคะแนนสินค้า -----------
        if (docProductScoreUser.docs.isNotEmpty && docProductScoreUser.docs.first.data()["is_like"] == true) {
          _productScore = true;
        }



      });
    }

  }
  // ----------------------------------- ให้คะแนนสินค้า ---------------------------------------------
  Future<bool> _handleRating( int productId ) async {
    try{
      final productScoreGetDoc = await FirebaseFirestore.instance.collection("product_score")
                                .where("product_id", isEqualTo: productId)
                                .where("buyer_id", isEqualTo: auth!.uid)
                                .get();

      if (productScoreGetDoc.docs.isNotEmpty){
        final data = {
          "is_like" : !productScoreGetDoc.docs.first.data()["is_like"],
          "updated_at": Timestamp.now(),
        };

        productScoreGetDoc.docs.first.reference.update(data); 

        return true;
      }
      else{
        final productScoreDoc = FirebaseFirestore.instance.collection("product_score").doc(productId.toString());
        final data = {
          "id_product_score": productScoreDoc.id,
          "product_id": productId ,
          "store_id": _product.store_id,
          "buyer_id": auth != null ? auth!.uid : "",
          "is_like" : true,
          "created_at": Timestamp.now(),
          "updated_at": Timestamp.now(),
        };

        productScoreDoc.set(data);

        return true;
      }
    }
    catch(e){
      print("error update score : $e");
      return false;
    }
  }

  // ------------------------------ แสดงตัวเลือก ประเภทสินค้า ---------------------------------------------
  void _handleDialog( bool onCheck ) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        // ใช้ StatefulBuilder สร้างให้ประมวณผล Text ตาม state ปัจจุบัน
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              title: const Text('เลือกประเภทสินค้า'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --------------- แสดงข้อมูลดึงมาจาก ประเภทสินค้า -------------------------
                  ..._productType.map((productType) => ListTile(
                    title: Text(
                            "${productType.name} (${productType.amount}) ชิ้น" , 
                            style: TextStyle(color: userInformation["type"] == productType.id_product_type ? Colors.red :  const Color.fromARGB(255, 52, 107, 201)),
                    ),
                    onTap: () => setState(() {
                      userInformation["type"] = productType.id_product_type;
                      userInformation["amount"] = 0;
                    }),
                  )),
                  Column(
                    children: [
                      userInformation["type"] != 0 
                      ? Row(
                        children: [
                          // --------------- จำนวนสินค้า -------------------------
                          Container(
                            child: Text(
                              _productType.isNotEmpty 
                                ? _productType.firstWhere( (productType) => productType.id_product_type == userInformation["type"] ).amount > userInformation["amount"] 
                                  ? "จํานวนสินค้า ${userInformation["amount"]}/${_productType.firstWhere( (productType) => productType.id_product_type == userInformation["type"] ).amount } "
                                  : "สินค้าหมด"
                                : ""
                              ,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 52, 107, 201),
                              ),
                            )
                          ),
                          
                          // ---------------- ปุ่มเพิ่มจำนวนสินค้า -------------------------
                          Container(
                            width: 100,
                            height: 50,
                            child: Row(
                              children: [
                                IconButton(onPressed: (){ 
                                  setState(() {
                                    if ((userInformation["amount"] as int) > 0)  {
                                      userInformation["amount"] = (userInformation["amount"] as int) - 1;
                                    }
                                  });
                                }, icon: Icon(Icons.remove),),
                                IconButton(onPressed: (){
                                  setState(() {
                                    if ((userInformation["amount"] as int) < _productType.map((e) => e.amount).reduce((value, element) => value + element)) {
                                      userInformation["amount"] = (userInformation["amount"] as int) + 1;
                                    }
                                  });
                                }, icon: Icon(Icons.add),),
                              ],
                            ),
                          ),
                        ],
                      ) : const Text(""),
                      // ---------------- ราคาสินค้า -------------------------
                      Row(
                        children: [
                          ..._productType.map((productType) => 
                            Text(
                              userInformation["type"] == productType.id_product_type ? "${productType.name} ราคา ${productType.price * userInformation["amount"]} บาท" :''
                            ),
                          ),
                      ]),


                      // ----------------- ปุ่มยืนยัน และ ยกเลิก --------------------------
                      Row(
                        children: [
                          TextButton(
                            onPressed: () async {
                              // ------------------------------- ปุ่มยืนยัน -------------------------------
                              // --- สร้างข้อมูลจากบันทึกเสร็จแล้ว ---
                              Map<String, Object> suborder = {
                                "suborder": userInformation,
                                "product": _product,
                                "productType": _productType.firstWhere( (productType) => productType.id_product_type == userInformation["type"] ),
                              };   

                              // --- ตรวจสอบเส้นทาางส่งข้อมูลไป --- 
                              onCheck 
                              ? Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => 
                                    PaymentScreen(
                                      suborder: [suborder],
                                      addSuborder: true
                                    ),
                                ),
                              )
                              : _makeFavorite( context , [suborder] );
                            },
                            child: const Text('ตกลง'),
                          ),
                          // ----------------------------------- ปุ่มยกเลิก -------------------------------
                          TextButton(
                            onPressed: () {
                              setState(() {
                                userInformation["type"] = 0;
                              });
                              Navigator.pop(context);
                            }, 
                            child: const Text('ยกเลิก'),
                          ),
                        ],
                      ),
                    ],

                  ),
                ],
              ),
            );
          },
        );
      },
    );

  }
  

  // ----------------------------- สร้าง favorite ----------------------------
  void _makeFavorite( BuildContext context1 , List favorite ) async {
    final favoriteDoc = FirebaseFirestore.instance.collection("favorite").doc(); // สร้าง doc พร้อม id
    // ----- สร้าง favorite -------
    await favoriteDoc.set({
      "id_suborder": favoriteDoc.id, // ใช้ id ที่สร้าง
      "product_id": favorite[0]['product'].id_product,
      "buyer_id": auth?.uid,
      "product_type_id": favorite[0]['productType'].id_product_type,
      "amount": favorite[0]['suborder']['amount'],
      "created_at": DateTime.now(),
      "updated_at": DateTime.now(),
    });

    // ----- สร้าง Dialog ------
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('สำเร็จ'),
        content: const Text('เพิ่มสินค้าลงในรายการโปรดแล้ว'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context1);
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Row(
        children: [
          // ----------- แสดงข้อมูล Product ------------
          Text("Product"),
          const Spacer(),
          // ----------- แก้ไขข้อมูล Product ------------
          auth != null ? 
            auth!.uid == _store.seller_id
            ? IconButton(
                icon: const Icon(Icons.edit_note),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProductScreen( productID: widget.productID ),
                    ),
                  );
                },
              )
            : const Text("")
          : const Text(""),
       
          
        ],
      )),
      body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                        children: [
                          // ---------------- รูปภาพ ---------------------
                          _productType.isNotEmpty
                          ? SizedBox(
                              height: 200.0,
                              child: PageView.builder(
                                itemCount: _productType.length,
                                itemBuilder: (context, index) {
                                  return _productType[index].image_url != null
                                      ? Image.network(_productType[index].image_url)
                                      : Text("Image not available");
                                },
                              ),
                            )
                          : Text("Image not available"),
              
                          // ---------------- ข้อมูล ---------------------
                          Container(
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 255, 255, 255),
                              border: Border(
                                bottom: BorderSide(
                                  width: 5,
                                  color: Color.fromARGB(255, 180, 180, 180),
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromARGB(189, 204, 204, 204),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(10),
                            alignment: Alignment.centerLeft,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [

                                    // ---------------- ชื่อ ---------------------                                    
                                    Text(
                                      _product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),

                                    const Spacer(),

                                    // ---------------- ถูกใจ ---------------------
                                    !_productScore 
                                      ? Container(
                                          width: 50,
                                          height: 50,
                                          child: IconButton(
                                                    onPressed: () {
                                                      _handleRating(_product.id_product)
                                                      .then( (value) => 
                                                        value 
                                                        ? setState(() {
                                                            _productScore = true;
                                                          })
                                                        : setState(() {
                                                          _productScore = false;
                                                        })
                                                      );
                                                    },
                                                    icon: Icon(Icons.favorite_border_outlined)  , color: Colors.redAccent , 
                                                  ),
                                        )
                                      : Container(
                                          width: 50,
                                          height: 50,
                                          child: IconButton(
                                                    onPressed: () {
                                                      _handleRating(_product.id_product)
                                                      .then( (value) => 
                                                        value 
                                                        ? setState(() {
                                                          _productScore = false;
                                                          })
                                                        : setState(() {
                                                          _productScore = true;
                                                        })
                                                      );
                                                    },
                                                    icon: Icon(Icons.favorite)  , color: Colors.redAccent , 
                                                  ),
                                        )
                                  ],
                                ),

              
                                // ---------------- ราคา ---------------------
                                Row(
                                  children: [                                   
                                    Icon(Icons.money),
                                    SizedBox(width: 10),
                                    Text(_productType.isNotEmpty
                                        ? _productType.map((e) => e.price).reduce((curr, next) => curr > next ? curr : next) != _productType.map((e) => e.price).reduce((curr, next) => curr < next ? curr : next) 
                                          ? " ${_productType.map((e) => e.price).reduce((curr, next) => curr < next ? curr : next)} - ${_productType.map((e) => e.price).reduce((curr, next) => curr > next ? curr : next)} บาท"
                                          : " ${_productType.first.price} บาท"
                                        : "")
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // ---------------- คะแนนสินค้า ---------------------
                          Container(
                            padding: EdgeInsets.all(10),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Text("คะแนนสินค้า : ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),),
                                for (var i = 1; i <= 5; i++)
                                  i <= (_product.score / 10).toInt()
                                    ? Icon(Icons.star, color: Colors.yellow ,size: 15,)
                                    : Icon(Icons.star_border,color: const Color.fromARGB(255, 105, 105, 105),size: 15,)
                                  ,
                              ],
                            )
                          ),
              
                          // ---------------- รายละเอียด ---------------------
                          Container(
                            margin: EdgeInsets.all(10),
                            padding: EdgeInsets.all(10),
                            alignment: Alignment.centerLeft,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "รายละเอียดข้อมูล",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                                Text(
                                  _product.description,
                                  style: const TextStyle(
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),


                          // ---------------------------------- แสดงร้านค้า -----------------------------------
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 255, 255),
                              border: Border(
                                bottom: BorderSide(
                                  width: 5,
                                  color: const Color.fromARGB(255, 180, 180, 180),
                                )
                              )),
                            child: Row(
                              children: [
                                // ---------------- รูปภาพ ---------------------
                                _store.image_url.isEmpty 
                                ? Text("Image not available") 
                                : GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StoreScreen( store_id: _store.id_store,))),
                                    child: Container(
                                        width: 50 , height: 50,
                                        margin: EdgeInsets.all(15),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(255, 255, 255, 255),
                                          borderRadius: BorderRadius.all( Radius.circular(50)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color.fromARGB(189, 204, 204, 204),
                                              spreadRadius: 2,
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(child: Image.network( _store.image_url , fit: BoxFit.cover, ))
                                      ),
                                  ),
                                // ---------------- ชื่อ และ คะแนน ร้านค้า---------------------
                                Text( "${_store.name} | ติดตาม :  ${_store.follow} |  คะแนน : " ),
                                for (var i = 1; i <= 5; i++) 
                                  i <= (_store.score / 100) 
                                  ? Icon(Icons.star , color: Colors.yellow, size: 15,) 
                                  : Icon(Icons.star_border , color: const Color.fromARGB(255, 116, 116, 116), size: 15,) ,
                            ]),
                          ),


                          // ---------------- แสดงคอมเมนต์ ---------------------
                          Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 255, 255),
                              border: Border(
                                bottom: BorderSide(
                                  width: 3,
                                  color: const Color.fromARGB(255, 180, 180, 180),
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(189, 204, 204, 204),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: CommentScreen( product_id: widget.productID ),
                          ),

                          SizedBox(height: 50,)
                          
                        ],
              ),
            ),
            // ---------------------- Bottom ----------------------------
            bottomSheet: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [

                  // ---------------- ปุ่มใส่ตระกร้า -------------------------
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      border: Border(
                        left: BorderSide(
                          width: 1,
                          color: const Color.fromARGB(255, 180, 180, 180),
                        ),
                        right: BorderSide(
                          width: 1,
                          color: const Color.fromARGB(255, 180, 180, 180),
                        ),
                        bottom: BorderSide(
                          width: 3,
                          color: const Color.fromARGB(255, 180, 180, 180),
                        ),
                      ),
                    ),
                    child: IconButton(
                      onPressed: () => auth == null 
                      ?  Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen( checkContext: "",))) 
                      : _handleDialog( false ),
                      icon: const Icon(Icons.add_shopping_cart, size: 20),
                    ),
                  ),

                  // ---------------- ปุ่มซื้อ -------------------------
                  Container(
                    width: 60,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      border: Border(
                        left: BorderSide(
                          width: 1,
                          color: const Color.fromARGB(255, 180, 180, 180),
                        ),
                        right: BorderSide(
                          width: 1,
                          color: const Color.fromARGB(255, 180, 180, 180),
                        ),
                        bottom: BorderSide(
                          width: 3,
                          color: const Color.fromARGB(255, 180, 180, 180),
                        ),
                      ),
                    ),
                    child: IconButton(
                      onPressed: () => 
                      auth == null
                      ? Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen( checkContext: "",)))
                      : _handleDialog( true ),
                      icon: const Icon(Icons.price_change, size: 20),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
