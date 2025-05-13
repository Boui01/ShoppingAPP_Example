import 'package:flutter/material.dart';
import 'package:shopping_app/Screen/Store/Categorize/DetailsStore/DetailsStoreScreen.dart';
import 'package:shopping_app/Screen/Store/Categorize/Products/ProductsScreen.dart';
import 'package:shopping_app/Screen/Store/Categorize/Recommend/RecommendScreen.dart';

class CategorizeScreen extends StatefulWidget {
  final int store_id;
  const CategorizeScreen({super.key , required this.store_id });

  @override
  State<CategorizeScreen> createState() => _CategorizeScreenState();
}

class _CategorizeScreenState extends State<CategorizeScreen> {
    int select = 0;

    @override
    Widget build(BuildContext context) {
      return  Column(
                children: [
                  // ----------- Categorize -------------
                  Container(
                    width: double.infinity,
                    height: 60,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                    child: Row(
                      children: [
                        Container( 
                          child: TextButton( 
                            onPressed: () => setState(() { select = select == 0 ? 1 : 0; }) , 
                            child: Text( "แนะนำ" ,style: TextStyle(color: select == 0 ? Colors.blueAccent : const Color.fromARGB(255, 71, 71, 71) , fontSize: 18),))
                        ),
                        Container( 
                          child: TextButton( 
                            onPressed: () => setState(() { select = select == 1 ? 0 : 1; }) ,
                            child: Text( "สินค้า" ,style: TextStyle(color: select == 1 ? Colors.blueAccent : const Color.fromARGB(255, 71, 71, 71)  , fontSize: 18),))
                        ),
                        Container(
                          child: TextButton(onPressed: () => setState(() { select = select == 2 ? 0 : 2; }),
                           child: Text("รายละเอียด" ,style: TextStyle(color: select == 2 ? Colors.blueAccent : const Color.fromARGB(255, 71, 71, 71) , fontSize: 18),)),
                        )
                      ],
                    ),
                  ),
                  // ----------- แสดงข้อมูล หมวดหมู่ ------------
                  select == 0 
                  ? RecommendScreen(store_id:  widget.store_id)
                  : select == 1 
                    ? ProductsScreen(store_id: widget.store_id)
                    : select == 2
                    ? Detailsstorescreen( store_id: widget.store_id)
                    : Container()


                ]
            );
    }
}