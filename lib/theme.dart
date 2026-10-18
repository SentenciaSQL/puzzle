import 'package:flutter/material.dart';

const ink = Color(0xFF2A1754);
const cream = Color(0xFFFFF6E8);
const creamDim = Color(0xFFE7D3B8);
const gold = Color(0xFFFFC44D);
const goldDeep = Color(0xFFE0941D);
const goldInk = Color(0xFF6A3D0C);
const night = Color(0xFF1A1448);
const nightDeep = Color(0xFF120C30);
const plum = Color(0xFF4A2A78);
const line = Color(0x52FFE2BA);

const gemPalette = <Color>[
  Color(0xFFFFC44D),
  Color(0xFFFF6B9D),
  Color(0xFF2EC9AE),
  Color(0xFFB388FF),
  Color(0xFF5EB6FF),
  Color(0xFFFF7A45),
];

TextStyle display(double size, {Color color = cream, double height = 0.95}) {
  return TextStyle(
    fontFamily: 'Fredoka',
    fontSize: size,
    height: height,
    color: color,
    fontWeight: FontWeight.w700,
    fontVariations: const [FontVariation.weight(700)],
  );
}

TextStyle body(
  double size, {
  Color color = cream,
  FontWeight weight = FontWeight.w700,
}) {
  return TextStyle(
    fontFamily: 'Nunito',
    fontSize: size,
    height: 1.25,
    color: color,
    fontWeight: weight,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
  );
}
