import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/Model/buyer_user.dart';
import 'package:shopping_app/Model/seller_user.dart';
import 'package:shopping_app/Screen/Product/ProductScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final auth = FirebaseAuth.instance;
  late Buyer_user buyer_user;
  late Seller_user seller_user;
  final List<String> items = List.generate(20, (index) => "Item $index");

  /*------ รับข้อมูลใน Store ทั้งหมด ------*/
  Future<List<Map<String, dynamic>>> _getAllData() async {
    try {
      CollectionReference collectionProduct =  FirebaseFirestore.instance
      .collection('product');

      QuerySnapshot querySnapshot = await collectionProduct.get();

      List docList = [];
      int check = 0;
      for (var doc in querySnapshot.docs) {
        if (check == 0 || check != doc["id_product"]) {
        await FirebaseFirestore.instance
            .collection("product_type")
            .where("product_id", isEqualTo: doc["id_product"])
            .get()
            .then((onValue) {
              if (onValue.docs.isNotEmpty) {
                check = doc["id_product"];
                docList.add( { 
                  "id_product" : doc["id_product"], 
                  "name" : doc["name"] , 
                  "type" : doc["type"] ,
                  "score" : doc["score"] ,
                  "price" : onValue.docs.first["price"] , 
                  "image" : onValue.docs.first["image"]
                });
              }
            });
        }
      }

      return docList. map((doc) => doc as Map<String, dynamic>).toList();
    }
    catch (e) {
      print("error : ${e}");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    /* ------------------ สร้างตัวใช้งานสําหรับการดึงข้อมูล -------------*/
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getAllData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No data found'));
        }

        final data = snapshot.data!;

        /* ----------- สร้าง GridView แบบกำหนดเอง ----------*/
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 columns (Adjust as needed)
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8, // Adjust based on item design
            ),
            itemCount: data.length,
            itemBuilder: (context, index) {
              // ------ สร้างตัวกดสําหรับเข้าสู่ข้อมูล ------
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ProductScreen(
                            productID: data[index]["id_product"],
                          ),
                    ),
                  );
                },
                // ------ สร้างข้อมูลแสดงโชว์ -------
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    border: Border(
                      bottom: BorderSide(
                        color: const Color.fromARGB(255, 192, 192, 192),
                        width: 5,
                      ),
                      right: BorderSide(
                        color:  const Color.fromARGB(255, 192, 192, 192),
                        width: 3,
                      )
                    ),
                    boxShadow: [BoxShadow(
                      color: const Color.fromARGB(255, 177, 177, 177).withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ------ สร้างรูปภาพ -------
                        data[index]['image'] != null &&
                            data[index]['image'].isNotEmpty
                            ? Image.network(
                              data[index]['image'],
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.broken_image, size: 80);
                              },
                            )
                            : Icon(Icons.image, size: 80),
                        // ------ สร้างชื่อโชว์ -------
                        Text(
                          data[index]['name'] ?? 'No Name',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        // ------ สร้างราคา -------
                        Text(
                          "ราคา: ${data[index]['price'] ?? 'No Price'}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        Container(
                          margin: EdgeInsets.all(5),
                          child: Row(
                            children: [
                              // ------ สร้างประเภทสินค้า -------
                              Container(
                                  width: 50,
                                  padding: EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(width: 1 , color: Colors.grey),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    " ${data[index]['type'] ?? 'No Type'}",
                                    style: const TextStyle(color: Colors.grey , fontSize: 12),
                                  ),
                                ),
                              // ------ สร้างคะแนน -------
                              Expanded(
                                child: Container(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    "คะแนน: ${data[index]['score'] ?? 'No Score'}",
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
