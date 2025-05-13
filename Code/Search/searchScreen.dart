import 'package:flutter/material.dart';
import 'package:shopping_app/Screen/Search/Field/searchScreenField.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all( 30),
      child: 
        SearchScreeenField(),
    );
  }
}