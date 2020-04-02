import 'package:flutter/material.dart';

class ElementComet extends StatelessWidget {

  final String name;

  ElementComet({this.name});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(100, 100),
      painter: CometPainter(name: name),
    );
  }
}

class CometPainter extends CustomPainter {

  final String name;

  CometPainter({this.name});

  @override
  void paint(Canvas canvas, Size size) {

    var paint = Paint();
    paint.color = Colors.black;

    canvas.drawLine(Offset(1.0, 100.0), Offset(20.0, 200.0), paint);


  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {



    // TODO: implement shouldRepaint
    return true;
  }
}
