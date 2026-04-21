import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key, required this.onSearch});

  final ValueChanged<String> onSearch;

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 255.0,
      height: 50.0,
      child: TextField(
        style: const TextStyle(
          // Add this style property
          color: Colors.black, // Set the text color to black
          fontSize:
              16.0, // You can also adjust the font size of the input text here if needed
        ),
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search for something',
          hintStyle: const TextStyle(
            fontSize: 15.0,
            fontWeight: FontWeight.normal,
            color: Color(0xFF8BA3CB),
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 20.0,
            color: Color(0xFF718EBF),
          ),
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40.0),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (value) {
          widget.onSearch(value);
          // You can also clear the text field after submission if needed
          // _searchController.clear();
        },
      ),
    );
  }
}
