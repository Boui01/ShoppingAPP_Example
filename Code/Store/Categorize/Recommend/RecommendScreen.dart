import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/Model/product.dart';
import 'package:shopping_app/Model/product_type.dart';
import 'package:shopping_app/Screen/Product/ProductScreen.dart';

class RecommendScreen extends StatefulWidget {
  final int store_id;
  const RecommendScreen({super.key , required this.store_id});

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {

  Future<List> _getData() async {
    try {
      // -------- ดึงข้อมูล store -----------
      final newList = [];
      final storeDoc = await FirebaseFirestore.instance.collection("store").where("id_store", isEqualTo: widget.store_id).get();

      // -------- ดึงข้อมูล product -----------
      if ( storeDoc.docs.isNotEmpty ) {
        final productDoc = await FirebaseFirestore.instance.collection("product").where("store_id", isEqualTo: widget.store_id).get();
        // ------- ดึงข้อมูล productType --------
        for (var product in productDoc.docs) {
          final productTypeDoc = await FirebaseFirestore.instance.collection("product_type").where("product_id", isEqualTo: product.data()["id_product"]).get();
          final newData = {  "product" : Product.defaultValue() , "product_type" : ProductType.defaultValue() };

          // ---------- สร้างข้อมูล ------------
          newData["product"] = Product.fromJson(product.data());
          newData["product_type"] = ProductType.fromJson( productTypeDoc.docs.first.data());

          // ---------- เพิ่มข้อมูล --------------
          newList.add(newData);         
        }
      }

      // --------- เรียงข้อมูล จาก มาก - น้อย -----------
      newList.sort((a, b) => b["product"].score.compareTo(a["product"].score));

      return newList;
    }
    catch (e) {
      print('Error occurred: $e');
      return [];
    }
  }
  @override
  Widget build(BuildContext context) {
    return  FutureBuilder<List>(
          future: _getData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // กำลังโหลด
              return Center(child: CircularProgressIndicator());
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              // ไม่มีข้อมูล
              return Center(child: Text('ไม่มีข้อมูล'));
            }
                   
            return  Container(
                      margin: EdgeInsets.all(10),
                      child: GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 2, // 2 columns (Adjust as needed)
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.8, // Adjust based on item design
                        children: [
                          // ------- สร้าง card สําหรับแสดงข้อมูล -------
                          ...snapshot.data!.map((e) { 
                            final product = e["product"];
                            final productType = e["product_type"];
                            // ----- สร้างตัวกดสําหรับเข้าสู่ข้อมูล ------
                            return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => ProductScreen(
                                                  productID: product.id_product,
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
                                              productType.image_url != null &&
                                                  productType.image_url.isNotEmpty
                                                  ? Image.network(
                                                    productType.image_url,
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
                                                product.name ?? 'No Name',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              // ------ สร้างราคา -------
                                              Text(
                                                "ราคา: ${productType.price ?? 'No Price'}",
                                                style: const TextStyle(color: Colors.grey),
                                              ),
                                              Container(
                                                margin: EdgeInsets.all(5),
                                                child: Row(
                                                  children: [
                                                    // ------ สร้างประเภทสินค้า -------
                                                    Container(
                                                        width: 40,
                                                        padding: EdgeInsets.all(1),
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(5),
                                                          border: Border.all(width: 1 , color: Colors.grey),
                                                        ),
                                                        alignment: Alignment.center,
                                                        child: Text(
                                                          " ${product.type ?? 'No Type'}",
                                                          style: const TextStyle(color: Colors.grey , fontSize: 12),
                                                        ),
                                                      ),
                                                    // ------ สร้างคะแนน -------
                                                    Expanded(
                                                      child: Container(
                                                        alignment: Alignment.centerRight,
                                                        child: Text(
                                                          "คะแนน: ${product.score ?? 'No Score'}",
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
                                    ),
                                  );
                                }).toList(),
                        ]
            ));
          },
    );
  }
}