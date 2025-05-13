import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/Model/seller_user.dart';
import 'package:shopping_app/Model/store.dart';

class Detailsstorescreen extends StatefulWidget {
  final int store_id; 
  const Detailsstorescreen({super.key , required this.store_id});

  @override
  State<Detailsstorescreen> createState() => _DetailsstorescreenState();
}

class _DetailsstorescreenState extends State<Detailsstorescreen> {

  Future<List> _getStore () async{
    final dataList = [];
    final storeDoc = await FirebaseFirestore.instance
        .collection("store")
        .where("id_store", isEqualTo: widget.store_id)
        .get();
    final storeScoreDoc = await FirebaseFirestore.instance
        .collection("product_score")
        .where("store_id", isEqualTo: widget.store_id)
        .where("is_like", isEqualTo: true)
        .get();

    if (storeDoc.docs.isNotEmpty) {
      final sellerDoc = await FirebaseFirestore.instance
          .collection("seller_user")
          .where("uid", isEqualTo: storeDoc.docs.first.data()["seller_id"])
          .get();
          
      final storeData = storeDoc.docs.first.data();

      if ( storeScoreDoc.docs.isNotEmpty ) {
        storeData["score"] = storeScoreDoc.docs.length;
      }
      else{
        storeData["score"] = 0;
      }

      if (sellerDoc.docs.isNotEmpty ) {
        dataList.add({ "store" : storeData , "user" : sellerDoc.docs.first.data() });
      }


    }
    return dataList;
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _getStore(), 
        builder: (context, snapshot) {
          if ( snapshot.connectionState == ConnectionState.waiting ) {
            return Center(child: CircularProgressIndicator());
          }
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('ไม่มีข้อมูล'));
          }

          Store store = Store.fromJson(snapshot.data![0]["store"]);
          Seller_user user = Seller_user.fromJson(snapshot.data![0]["user"]);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Text("ชื่อ :" , style: TextStyle(fontSize: 20),),
                    Text("${store.name} " , style: TextStyle(fontSize: 20),),
                  ],
                ),           
              ),
              Divider(),
              Container(
                padding: EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: Text("ชื่อเจ้าของ : ${user.thai_fname } ${user.thai_lname} " , style: TextStyle(fontSize: 20),),           
              ),
              Divider(),
              Container(
                padding: EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: Text("ประเภท : ${store.type} " , style: TextStyle(fontSize: 20),),           
              ),

              Divider(),
              Container(
                padding: EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: Text("รายละเอียด : ${store.description} " , style: TextStyle(fontSize: 20),),           
              ),

              Divider(),
              Container(
                padding: EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: Text("การตอบกลับข้อความ : ${store.reply_message} " , style: TextStyle(fontSize: 20),),           
              ),

              Divider(),
              Container(
                padding: EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: Text("คะแนน : ${store.score} " , style: TextStyle(fontSize: 20),),           
              ),

              Divider(),
              Container(
                padding: EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: Text("ตั้งแต่ : ${store.created_at.toDate().day}/${store.created_at.toDate().month}/${store.created_at.toDate().year} " , style: TextStyle(fontSize: 20),),           
              ),
            ],
          );
        }
      );
  }
}