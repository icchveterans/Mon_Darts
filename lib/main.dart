import 'package:flutter/material.dart';
import 'game_screen.dart'; // Бидний дэлгэцийн файлыг дуудаж байна

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: GameScreen(), // Апп асахдаа шууд дартсын дэлгэцийг нээнэ
  ));
}
