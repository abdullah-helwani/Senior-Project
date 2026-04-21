import 'package:flutter/material.dart';

class SearchBarWithButton extends StatefulWidget {
  const SearchBarWithButton({super.key, required this.onSearch});

  final ValueChanged<String> onSearch;

  @override
  State<SearchBarWithButton> createState() => _SearchBarWithButtonState();
}

class _SearchBarWithButtonState extends State<SearchBarWithButton> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
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
              hintText: 'Search for a student\'s name',
              hintStyle: const TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.normal,
                color: Color(0xFF8BA3CB),
              ),
              // prefixIcon: const Icon(
              //   Icons.search,
              //   size: 20.0,
              //   color: Color(0xFF718EBF),
              // ),
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
          ),
        ),
        const SizedBox(width: 8.0), // Add some spacing
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            widget.onSearch(_searchController.text);
            // Optionally clear the text field
            _searchController.clear();
          },
        ),
      ],
    );
  }
}
