import 'package:flutter/material.dart';

class DeleteIconButton extends StatefulWidget {
  final String label;
  final VoidCallback onDelete;

  const DeleteIconButton({
    super.key,
    required this.label,
    required this.onDelete,
  });

  @override
  State<DeleteIconButton> createState() => _DeleteIconButtonState();
}

class _DeleteIconButtonState extends State<DeleteIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: IconButton(
        tooltip: 'Delete',
        icon: Icon(
          Icons.delete,
          color: _isHovered ? Colors.red : Colors.grey[700],
        ),
        onPressed: () {
          // showDialog(
          //   context: context,
          //   builder: (context) => DialogDelete(
          //     label: widget.label,
          //     onDelete: widget.onDelete,
          //   ),
          // );
        },
      ),
    );
  }
}
