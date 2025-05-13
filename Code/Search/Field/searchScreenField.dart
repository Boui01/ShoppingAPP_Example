import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/Screen/Product/ProductScreen.dart';

class SearchScreeenField extends StatefulWidget {
  const SearchScreeenField({super.key });

  @override
  State<SearchScreeenField> createState() => _SearchScreeenFieldState();
}

class _SearchScreeenFieldState extends State<SearchScreeenField> {
  final formKey = GlobalKey<FormState>();
  final searchSent = TextEditingController();
  List searchInfo = [];


  Future<void> _handleSearch () async {
    // -------- รีเซ็ต Lits ก่อนใส่ข้อมูลใหม่ ----------
    setState(() {
      searchInfo = [];
    });
    // ------- ดึงข้อมูล Product จากฐานข้อมูล --------
    final getProduct = await FirebaseFirestore.instance
      .collection("product")
      .where("name", isEqualTo: searchSent.text)
      .get();

   // ------- loop เช็คข้อมูล Product ดึงมาหลายข้อมูล -------
   for (var doc in getProduct.docs) {

    // ------- ดึงข้อมูล Product Type จากฐานข้อมูล --------
     FirebaseFirestore.instance
     .collection("product_type")
     .where("product_id", isEqualTo: doc["id_product"])
     .get()
     .then((onValue) {
       setState(() {
          searchInfo.add({ 
            "id_product" : doc["id_product"], 
            "name" : doc["name"] , 
            "type" : doc["type"],
            "score" : doc["score"] ,
            "price" : onValue.docs.first["price"] ,
            "image" : onValue.docs.first["image"]});
       });
     });
   }


  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Form(
          key: formKey,
          child: Column(
            children: [
              TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Search',
                    ),
                    controller: searchSent,
                  ),
              Container(
                child: 
                  ElevatedButton(onPressed: _handleSearch, 
                    child: const Text("ค้นหา")
                  )
                ),
            ],
          ),
        ),
        searchInfo.isNotEmpty ? 
          ListView.builder(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemBuilder: (context, index) => 
            // -------------- แสดงข้อมูล -----------------

              // ------- กดเข้าสู่ข้อมูล -------
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ProductScreen(
                            productID: searchInfo[index]["id_product"],
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
                        searchInfo[index]['image'] != null &&
                            searchInfo[index]['image'].isNotEmpty
                            ? Image.network(
                              searchInfo[index]['image'],
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
                          searchInfo[index]['name'] ?? 'No Name',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        // ------ สร้างราคา -------
                        Text(
                          "ราคา: ${searchInfo[index]['price'] ?? 'No Price'}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        Container(
                          margin: EdgeInsets.all(5),
                          child: Row(
                            children: [
                              // ------ สร้างประเภทสินค้า -------
                              Container(
                                  padding: EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(width: 1 , color: Colors.grey),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    " ${searchInfo[index]['type'] ?? 'No Type'}",
                                    style: const TextStyle(color: Colors.grey , fontSize: 12),
                                  ),
                                ),
                              // ------ สร้างคะแนน -------
                              Expanded(
                                child: Container(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    "คะแนน: ${searchInfo[index]['socre'] ?? 'No Score'}",
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
            itemCount: searchInfo.length
          )             
          : Container()
      ],
    );
  }

}