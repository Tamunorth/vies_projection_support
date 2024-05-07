import 'package:flutter/material.dart';

class MyRadioListTile<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final String title;
  final IconData? icon;
  final ValueChanged<T?> onChanged;

  const MyRadioListTile({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.title,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final title = this.icon;
    return InkWell(
      onTap: () => onChanged(value),
      child: _customRadioButton,
    );
  }

  Widget get _customRadioButton {
    final isSelected = value == groupValue;
    return Container(
      margin: EdgeInsets.all(5),
      padding: EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: isSelected ? Color(0xff141414) : null,
      ),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.music_note,
            color: isSelected ? Colors.white : Color(0xff878787),
            size: 24,
          ),
          SizedBox(
            width: 10,
          ),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Color(0xff878787),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
