import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/Model/order.dart';

class OrderBuyerScreen extends StatefulWidget {
  const OrderBuyerScreen({super.key});

  @override
  State<OrderBuyerScreen> createState() => _OrderBuyerScreenState();
}

class _OrderBuyerScreenState extends State<OrderBuyerScreen> {
  final auth = FirebaseAuth.instance;
  OrderModel order = OrderModel.defaultValue();
  List<OrderModel> orderList = [];


  Future<List<OrderModel>> _getOrder() async {
    // -------- รับข้อมูลจากฐานข้อมูล ---------
    final orderSnapshot = await FirebaseFirestore.instance
        .collection("order")
        .where("buyer_id", isEqualTo: auth.currentUser?.uid)
        .get();

     List<OrderModel> orderList = []; // สร้างใหม่ ไม่ใช้ตัวเก่า
     
    // ------- สร้างข้อมูลเข้า List ---------
    for (var doc in orderSnapshot.docs) {
      final docData = OrderModel.fromJson(doc.data());

      // แยก suborder แต่ล่ะ ID ออกมา
      List suborderIds = doc["suborder"];
      List productInfos = []; 

      // -------------- ดึงข้อมูล suborder จากฐานข้อมูล ----------
      for (var suborderId in suborderIds) {
        // ดึง suborder
        final suborderDoc = await FirebaseFirestore.instance
            .collection("suborder")
            .doc(suborderId)
            .get();

        if (suborderDoc.exists) {
          final suborderData = suborderDoc.data()!;

          // -------------- ดึงข้อมูล product จากฐานข้อมูล ----------
          // ดึง product 
          final productDoc = await FirebaseFirestore.instance
              .collection("product")
              .where("id_product", isEqualTo: suborderData["product_id"])
              .get();

          // ดึง product type 
          final productTypeDoc = await FirebaseFirestore.instance
                .collection("product_type")
                .where("id_product_type", isEqualTo: suborderData["product_type_id"])
                .get();
          
          print("suborderID :"+ suborderDoc.id + " number :" + suborderData["amount"].toString());
          // ------------ เช็คข้อมูล และ เพิ่มเข้าไปใน Model หรือ เรียกว่า join --------------
          if (productDoc.docs.isNotEmpty || productTypeDoc.docs.isNotEmpty) {
            final productInfo = "\n ชื่อสินค้า : " + productDoc.docs.first.data()["name"] + 
                                " ประเภท : " + productTypeDoc.docs.first.data()["name"] +
                                " จำนวน : " + suborderData["amount"].toString() +
                                "\n สถานะ : " + (suborderData["cancel_suborder"] ? "ถูกยกเลิก" : "ปกติ")+
                                "\n ตำแหน่ง : " + suborderData["position"] + 
                                ( productInfos.length == 0 ? "\n" : ",\n");
            final productImage = productTypeDoc.docs.first.data()["image"];
            productInfos.add({"id_suborder" : suborderId,  "info" : productInfo , "image" : productImage}); //เพิ่มชื่อเข้าไปใน List        
          }
        }
      }
      // ---- สร้างข้อมูลใหม่เอาไปแสดง ในรูปแบบ join  ----
      docData.id_order = doc.id;
      docData.suborder = productInfos;
      orderList.add(docData);
    }


    return orderList;
  }

  // -------------- function ยกเลิกสินค้า --------------  
  void _handleCancel( onOrder ){
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("ยกเลิกสินค้า"),
        content: Text("คุณต้องการยกเลิกสินค้าที่เลือกทั้งหมดใช่หรือไม่ ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("ยกเลิก"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("ตกลง"),
          ),
        ],
      ),
    ).then((confirm) {
      if (confirm) {
        // --------------- เปลี่ยนข้อมูล Order ----------------
        FirebaseFirestore.instance
            .collection('order')
            .doc(onOrder.id_order)
            .update({
          "cancel_order": true,
          "canceled_at": Timestamp.now()
        })
            .then((onValue) => setState(() {
          orderList.removeWhere( (order) => order.id_order == onOrder.id_order );
        }));

        // --------------- เปลี่ยนข้อมูล Suborder ----------------
        for ( var suborderId in onOrder.suborder ){
          FirebaseFirestore.instance
            .collection('suborder')
            .where("id_suborder", isEqualTo: suborderId["id_suborder"] )
            .get()
            .then((onValue) =>
             setState(() {
              for (var doc in onValue.docs) {
                doc.reference.update({
                  "cancel_suborder": true,
                  "canceled_at": Timestamp.now()
                });
                }
              }
            ));
        }
      }
    });

    


  }


  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("รายการสินค้า"),),
      body: 

      // ------------------------ ดึงข้อมูล Order ล่วงหน้า ---------------------------
      FutureBuilder<List<OrderModel>> (
        future: _getOrder(),
        initialData: null,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("ไม่มีข้อมูล"));
          }

          if (snapshot.hasError) {
            return Center(child: Text("เกิดข้อผิดพลาด: ${snapshot.error}"));
          }

          final pendingOrders = snapshot.data!.where((o) => !o.cancel_order).toList();
          final canceledOrders = snapshot.data!.where((o) => o.cancel_order).toList();

          return SingleChildScrollView(
            child:  Column(
                children: [

                  if (pendingOrders.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Text("รายการเตรียมส่ง", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  ...pendingOrders.map((data) => 
                        // --------------------------- รายการเตรียมส่ง ---------------------------
                        Container(
                          margin: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]),
                          child: 
                            !data.cancel_order ?
                            // ------------------- แสดงข้อมูลรายกาย Order -------------------
                            ListTile(
                              title: Text( "รหัสคําสั่งซื้อ : ${data.id_order.toString()}" +
                                          "\nรายละเอียด :"+"${data.description}" +
                                          "\nราคารวม : ${data.price} บาท" +
                                          "\nวันที่สั่งซื้อ : ${data.created_at.toDate().day}/${data.created_at.toDate().month}/${data.created_at.toDate().year}" +
                                          "\nสถานะยกเลิก : ${!data.cancel_order ? "ยังไม่ได้ยกเลิก" : "ถูกยกเลิก"}"
                              ),
                              // ------------------- แสดงข้อมูลสินค้า -------------------
                              subtitle: Column(
                                children: [
                                  Text("รายการสินค้า" , style: TextStyle(fontSize: 16 , fontWeight: FontWeight.bold),), 
                                  ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: data.suborder.length,
                                          itemBuilder: (context, index) {
                                          return Row(
                                            children: [                              
                                              Container(
                                                width: 50,
                                                height: 50,
                                                child: Image.network( data.suborder[index]["image"] )

                                              ),
                                              Text( "${data.suborder[index]["info"]}" )

                                            ],
                                          );
                                  }
                                ),
                                // ---------------- ปุ่มยกเลิกรายการ ----------------
                                  Container(
                                    width: 150,
                                    child: ElevatedButton(
                                      onPressed: () => _handleCancel(data), 
                                      child: Text("ยกเลิกรายการ")
                                    ),
                                  ),
                                ],
                              ),
                              trailing: null,
                            )
                            :
                            Container()
                            ,
                          
                        ),
                  ).toList(),
                  ],

                   if (canceledOrders.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text("รายการยกเลิก", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    ...canceledOrders.map((data) => 
                          // --------------------------- รายการยกเลิกส่งสินค้า ---------------------------
                          Container(
                            margin: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]),
                            child: 
                              data.cancel_order ?
                              // ------------------- แสดงข้อมูลรายกาย Order -------------------
                              ListTile(
                                title: Text( "รหัสคําสั่งซื้อ : ${data.id_order.toString()}" +
                                            "\nรายละเอียด :"+"${data.description}" +
                                            "\nราคารวม : ${data.price} บาท" +
                                            "\nวันที่สั่งซื้อ : ${data.created_at.toDate().day}/${data.created_at.toDate().month}/${data.created_at.toDate().year}" +
                                            "\nสถานะยกเลิก : ${!data.cancel_order ? "ยังไม่ได้ยกเลิก" : "ถูกยกเลิก"}"
                                ),
                                // ------------------- แสดงข้อมูลสินค้า -------------------
                                subtitle: Column(
                                  children: [
                                    Text("รายการสินค้า" , style: TextStyle(fontSize: 16 , fontWeight: FontWeight.bold),), 
                                    ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: data.suborder.length,
                                        itemBuilder: (context, index) {
                                        return Row(
                                          children: [                              
                                            Container(
                                              width: 50,
                                              height: 50,
                                              child: Image.network( data.suborder[index]["image"] )

                                            ),
                                            Text( "${data.suborder[index]["info"]}" )

                                          ],
                                        );
                                      }
                                    ),
                                  ]
                                ),
                                trailing: null,
                              )
                            : Container()
                            ,
                            )
                          ).toList(),
                        ],
                    
                ],    
            
            ),
          );
        },
      ),
      
    );
  }
}