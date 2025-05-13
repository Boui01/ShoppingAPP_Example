import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/Model/product.dart';
import 'package:shopping_app/Model/product_type.dart';

class OrderSellerScreen extends StatefulWidget {
  const OrderSellerScreen({super.key});

  @override
  State<OrderSellerScreen> createState() => _OrderSellerScreenState();
}

class _OrderSellerScreenState extends State<OrderSellerScreen> {
  final auth = FirebaseAuth.instance;
  final productList = [];
  final productTypeList = [];
  final orderList = [];
  // ------------ รับข้อมูล จากฐานข้อมูล ----------------
  Future<List<Map<String, dynamic>>> _getOrder() async {
    try{
      final subOrderList = <Map<String, dynamic>>[];

      // ---------------- ดึงร้าน ----------------
      final storeDoc = await FirebaseFirestore.instance
          .collection("store")
          .where("seller_id", isEqualTo: auth.currentUser?.uid)
          .get();

      // ---------------- ดึงสินค้า ----------------
      for (var store in storeDoc.docs) {
        final storeId = store.data()["id_store"];

        // 2. ดึงสินค้าของร้านนั้น
        final productDoc = await FirebaseFirestore.instance
            .collection("product")
            .where("store_id", isEqualTo: storeId)
            .get();


        // ---------------- ดึงประเภทสินค้า ----------------
        for (var product in productDoc.docs) {
          final productId = product.data()["id_product"];

          // 3. ดึงประเภทสินค้าที่อิงกับสินค้า
          final productTypeDoc = await FirebaseFirestore.instance
              .collection("product_type")
              .where("product_id", isEqualTo: productId)
              .get();

          productList.add( Product.fromJson(product.data()) ); // เก็บข้อมูลเข้า Product list

          // ---------------- ดึง Suborder ----------------
          for (var productType in productTypeDoc.docs) {
            final productTypeId = productType.data()["id_product_type"];

            final suborderDoc = await FirebaseFirestore.instance
                .collection("suborder")
                .where("product_type_id", isEqualTo: productTypeId)
                .get();

            productTypeList.add( ProductType.fromJson(productType.data()) ); // เก็บข้อมูลเข้า ProductType list

            // ---------------- สร้างข้อมูล Buyer_user join  Suborder ----------------
            for (var suborder in suborderDoc.docs) {
              final suborderInfo = suborder.data();
              // ---------------- ดึง Buyer ----------------
              final sellerDoc = await FirebaseFirestore.instance
                .collection("buyer_user")
                .where("uid", isEqualTo: suborder.data()["buyer_id"])
                .get();
              
              
              // เปลี่ยน uid เป็น ชื่อ และนามสกุล
              suborderInfo["buyer_id"] = sellerDoc.docs.first.data()["thai_fname"] + " " + sellerDoc.docs.first.data()["thai_lname"];

              //  ------------- ส่งข้อมูลเข้า List -------------
              subOrderList.add( suborderInfo ); // เก็บข้อมูลเข้า list

            }
          }
      }
    }
    print( "subOrderList :  ${subOrderList.length} ");


    return subOrderList;

    }
    catch (e) {
      print('Error Order seller : ${e.toString()}');
      return [];
    }
  }
  // ---------------------------- Function ส่งสินค้าสำเร็จ ---------------------------
  Future<ScaffoldFeatureController<SnackBar, SnackBarClosedReason>> _sentOrderSuccess( indexID ) async {
    // ------- สร้าง SnackBar -------
    final snackBar = SnackBar(
      content: Text('ส่งสินค้าสําเร็จ'),
      action: SnackBarAction(
        label: 'ปิด',
        onPressed: () {},
      ),
    );
    
    // ---------- update position ของ suborder ----------
    final suborder = await FirebaseFirestore.instance
                    .collection("suborder")
                    .doc(indexID)
                    .get();

    suborder.reference.update({"position": "จุดเตรียมของขนส่ง"});

    setState(() {
      _getOrder();
    });

    return ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // ---------------------------- Function ยกเลิกการส่งสินค้า ---------------------------
  Future<ScaffoldFeatureController<SnackBar, SnackBarClosedReason>> _sentOrderCancel( indexID ) async {
    // ------- สร้าง SnackBar -------
    final snackBar = SnackBar(
      content: Text('ยกเลิกสินค้าเรียบร้อย'),
      action: SnackBarAction(
        label: 'ปิด',
        onPressed: () {},
      ),
    );

    // ---------- update position ของ suborder ----------
    final suborder = await FirebaseFirestore.instance
                    .collection("suborder")
                    .doc(indexID)
                    .get();

    suborder.reference.update({
      "cancel_suborder": true,
      "canceled_at": Timestamp.now()
    });

    setState(() {
      _getOrder();
    });

    return ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _getOrder(), 
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // กำลังโหลด
              return Center(child: CircularProgressIndicator());
            }
      
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              // ไม่มีข้อมูล
              return Center(child: Text('ไม่มีข้อมูล'));
            }
      
            if (snapshot.hasError) {
              // ถ้า error
              return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
            }
            return Column(
              children: [                           
                Text("กำลังรอการเตรียมส่ง" , style: TextStyle( fontSize: 18 , fontWeight: FontWeight.bold ),),
                
                ...snapshot.data!.map( (suborder) {
                      return 
                          // ------------------ กำลังรอส่งสินค้า ------------------
                          suborder["position"] == "จุดเตรียมของขนส่ง" || suborder["cancel_suborder"] 
                          ? Container() 
                          : Card(
                            elevation: 3,
                            child: ListTile(
                              title: Text(  "ชื่อสินค้า : ${ productList.where( (data) => suborder["product_id"] == data.id_product ).first.name } " +
                                            "\nชื่อผู้ส่ง : ${suborder['buyer_id']}" +
                                            "\n ประเภท : ${ productTypeList.where( (data) => suborder["product_type_id"] == data.id_product_type ).first.name } " + 
                                            "\n จำนวน : ${suborder['amount']}"
                                      ),
                              subtitle: 
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _sentOrderSuccess( suborder["id_suborder"] ), 
                                    child: Text("ส่งสินค้าเรียบร้อย")
                                  ),
                                  
                                  ElevatedButton(
                                    onPressed: () =>  _sentOrderCancel( suborder["id_suborder"] ), 
                                    child: Text("ยกเลิก") )
                                ],
                              ),
                              trailing: Image.network( productTypeList.where( (data) => suborder["product_type_id"] == data.id_product_type ).first.image_url ),
                            ),
                          );
              
                  } ).toList(),
                
                Divider(),
                
                Text("สินค้าถูกยกเลิก" , style: TextStyle( fontSize: 18 , fontWeight: FontWeight.bold ),) ,                   
                // ----------------------------- ส่งสินค้าไม่สําเร็จ -----------------------------
                
                ...snapshot.data!.map((suborder) {
                  return                 
                  suborder["cancel_suborder"] 
                  ? Card(
                    elevation: 3,
                    child: ListTile(
                      title: Text(  "ชื่อสินค้า : ${ productList.where( (data) => suborder["product_id"] == data.id_product ).first.name } " +
                                    "\nชื่อผู้ส่ง : ${suborder['buyer_id']}" 
                                    "\nประเภท : ${ productTypeList.where( (data) => suborder["product_type_id"] == data.id_product_type ).first.name } " + 
                                    "\nจำนวน : ${suborder['amount']}" 
                              ),
                      subtitle: Text("สินค้าถูกยกเลิกแล้ว"),
                      trailing: Image.network( productTypeList.where( (data) => suborder["product_type_id"] == data.id_product_type ).first.image_url ),
                    ),
                  )
                  :  Container();
      
                } ).toList(),
      
              ],
            );
          }),
    );
  }
}