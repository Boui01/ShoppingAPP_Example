import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/Model/store.dart';
import 'package:shopping_app/Screen/Login/loginScreen.dart';
import 'package:shopping_app/Screen/Store/Categorize/CategorizeScreen.dart';
import 'package:shopping_app/Screen/Store/EditStore/EditStroeScreen.dart';

class StoreScreen extends StatefulWidget {
  final int store_id;
  const StoreScreen({super.key , required this.store_id});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  Store store = Store.defaultValue();
  List user_follow = [];
  final user = FirebaseAuth.instance.currentUser ?? null;

  @override
  void initState() {
    super.initState();
    _loadStore(); // โหลด store แยก
  }

  void _loadStore() async {
    try {
      final storeDoc = await FirebaseFirestore.instance
          .collection("store")
          .where("id_store", isEqualTo: widget.store_id)
          .get();

      if (storeDoc.docs.isNotEmpty) {
        final storeData = storeDoc.docs.first.data();

        final storeScoreDoc = await FirebaseFirestore.instance
                              .collection("product_score")
                              .where("store_id", isEqualTo: widget.store_id)
                              .where("is_like", isEqualTo: true)
                              .get();  

        final followDoc = await FirebaseFirestore.instance
                          .collection("store_follow")
                          .where("store_id", isEqualTo: widget.store_id)
                          .get();

        // -------------------- เพิ่มข้อมูล follow ---------------------
        if ( followDoc.docs.isNotEmpty ) {
          storeData["follow"] = followDoc.docs.length;

          setState(() {
            user_follow = followDoc.docs.map((doc) => doc.data()).toList();
          });
        }

        // --------------------- เพิ่มข้อมูลคะแนน ---------------------
        if ( storeScoreDoc.docs.isNotEmpty ) {
          storeData["score"] = storeScoreDoc.docs.length;
        }
        else{
          storeData["score"] = 0;
        }
        
        // -------------------- อัพเดทข้อมูล store ---------------------
        setState(() {
          store = Store.fromJson(storeData); // ✔️ update ตัวแปร store ที่แสดงผลใน UI
        });


      }
    } catch (e) {
      print("Error loading store: $e");
    }
  }

  // -------------- โหลดข้อมูล follow ใหม่ ----------------
  void _loadFollow() async {
    var followData = [];

    // ------- ดึงข้อมูล follow -------
    try {
      final followDoc = await FirebaseFirestore.instance
          .collection("store_follow")
          .where("store_id", isEqualTo: widget.store_id)
          .get();

      if (followDoc.docs.isNotEmpty) {
        followData = followDoc.docs.map((doc) => doc.data()).toList();
      }
    } catch (e) {
      print("Error loading follow: $e");
    }

    // -------- อัพเดทข้อมูล follow  ** ไม่สามารถใส่ setState ใน try{} ได้ ** --------
    setState(() {
      user_follow = followData;
      store.follow = followData.length;
    });
  }


  // --------------- เพิ่มและลบ follow --------------------------
  void _handleFollow( ) async {
    try {
      // ------- ตรวจสอบ follow ในฐานข้อมูล -------
      final followDoc = await FirebaseFirestore.instance
          .collection("store_follow")
          .doc(user!.uid + "_" + store.id_store.toString())
          .get();

      //  -------- เพิ่ม follow --------
      if (!followDoc.exists) {
        await FirebaseFirestore.instance
            .collection("store_follow")
            .doc(user!.uid + "_" + store.id_store.toString())
            .set({
              "user_id": user!.uid,
              "store_id": store.id_store,
              "created_at": Timestamp.now(),
              "updated_at": Timestamp.now(),
            });

      }
      // -------- ลบ follow --------
      else{
        await FirebaseFirestore.instance
            .collection("store_follow")
            .doc(user!.uid + "_" + store.id_store.toString())
            .delete();

      }

      // ----- โหลดข้อมูล follow ใหม่ -----------
      _loadFollow();
    }
    catch (e) {
      print("Error loading store: $e");
    }
  }


  @override

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( 
                centerTitle: true  ,
                title: Row(
                  children: [
                    Text("ร้านค้า" , style: TextStyle( color: Colors.blueAccent , fontWeight: FontWeight.bold , fontSize: 24), ),
                    const Spacer(),
                    IconButton(
                      onPressed:() => Navigator.push(context, MaterialPageRoute(builder: (context) => EditStoreScreen( storeID: widget.store_id ))) ,
                      icon: Icon(Icons.edit , color: Colors.blueAccent , size: 20,)
                    )
                  ],
                ),
                backgroundColor: Colors.white, 
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(5),
                  child: Container(
                    decoration: BoxDecoration( 
                      border: Border(bottom: BorderSide(
                        width: 5, 
                        color: Color.fromARGB(255, 180, 180, 180))
                      )
                    ),
                  ), 
                ),
              ),
      body: SingleChildScrollView(
              child:  Column(
                  children: [
                      // ---------- store -------------
                    Container(
                      width: double.infinity,
                      height: 200,
                      child: store.image_url.isNotEmpty 
                      ? Image.network( store.image_url , fit: BoxFit.cover,)
                      : Icon(Icons.image_not_supported),
                    ),

                    // ----------- ตัวแบ่ง ---------------
                    Container(
                      width: double.infinity,
                      height: 80,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 255, 255, 255),
                        border: Border(
                          bottom: BorderSide(
                            width: 5,
                            color: Color.fromARGB(255, 180, 180, 180),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                child: store.image_url.isNotEmpty 
                                ? ClipOval(child: Image.network( store.image_url , fit: BoxFit.cover,))
                                : Icon(Icons.image_not_supported),
                              ),
                              // ------------- ชื่อร้าน ----------------
                              Text( " ${store.name} ",style: TextStyle(color: Colors.blueAccent),),

                              // ---------- follow button ----------------

                              Container(
                                  width: user_follow.where( (u) => u["user_id"] == user!.uid ).isNotEmpty ? 125 : 95,
                                  height: 30,
                                  margin: EdgeInsets.all(5),
                                  child: ElevatedButton(                            
                                    onPressed: () => user != null ? _handleFollow() : Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen( checkContext: "",))), 
                                    child: Text( user_follow.where( (u) => u["user_id"] == user!.uid ).isNotEmpty ? "ติดตามแล้ว" : "ติดตาม" )
                                  ),
                              ),                          
                              Container( 
                                width: 70, 
                                child: Text( " ${store.follow} ผู้ติดตาม ",style: TextStyle( color:  Colors.blueAccent , fontSize: 14) )
                              ),

                                            

                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 255, 255, 255),
                        border: Border(
                          bottom: BorderSide(
                            width: 1,
                            color: Color.fromARGB(255, 180, 180, 180),
                          ),
                        ),
                      ),
                      child: Container(
                        margin: EdgeInsets.all(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [

                              // ------------- คะแนน ----------------
                              Container(
                                padding: EdgeInsets.only(bottom: 2),
                                child: Text( "คะแนน : " ,style: TextStyle(color: Colors.blueAccent),)
                              ),
                              Container(
                                child: Row(
                                  children: [
                                    for (int index = 1 ; index <= 5 ; index++)
                                    index <= (store.score / 100).toInt()
                                    ? Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 15,
                                      )
                                    : Icon(
                                        Icons.star_border,
                                        color: const Color.fromARGB(255, 105, 105, 105),
                                        size: 15,
                                      )
                                    ,
                                  ]
                                ),
                              ),

                              // --------------- ข้อความตอบกลับ ----------------
                              Container(
                                margin: EdgeInsets.only(left: 10),
                                padding: EdgeInsets.only(bottom: 2),
                                child: Text( "ข้อความตอบกลับ : ${store.reply_message} " ,style: TextStyle(color: Colors.blueAccent),)
                               )
                            ]
                          ),
                      ),
                    ),  
                                                
                    CategorizeScreen(store_id: widget.store_id,),
                  ],
              ),
      ),
    );
  }
}