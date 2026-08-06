import 'package:flutter/material.dart';

Widget buildPetPaw({
  required BuildContext context, // لازمنـا الـ context باش نـعرفو حجم الـ écran
  required double size,
  required double topPercent,    //  0.0  1.0)
  required double leftPercent,   // 0.0  1.0
  Color? color,
}) {
  final double screenHeight = MediaQuery.of(context).size.height;
  final double screenWidth = MediaQuery.of(context).size.width;

 
  return Positioned(
    top: screenHeight * topPercent,
    left: screenWidth * leftPercent,
    child: Icon(
      Icons.pets,
      size: size,
      color: color,
    ),
  );
}
//buildPetPaw( context: context, size: 70, topPercent: 0.50, leftPercent: 0.70, color: AppColors.secondary,),