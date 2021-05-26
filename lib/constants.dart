import 'package:flutter/material.dart';

Widget colorSlider({colors, sliderPos, maxWidth, handle, currentColor}){

  colorChangeHandler(double position) {
    //handle out of bounds positions
    if (position > maxWidth) {
      position = maxWidth;
    }
    if (position < 0) {
      position = 0;
    }
   // print("New pos: $position");

    handle(position);
  }

  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onHorizontalDragStart: (DragStartDetails details) {
     // print("_-------------------------STARTED DRAG");
      colorChangeHandler(details.localPosition.dx);
    },
    onHorizontalDragUpdate: (DragUpdateDetails details) {
      colorChangeHandler(details.localPosition.dx);
    },
    onTapDown: (TapDownDetails details) {
      colorChangeHandler(details.localPosition.dx);
    },
    //This outside padding makes it much easier to grab the   slider because the gesture detector has
    // the extra padding to recognize gestures inside of
    child: Padding(
      padding: EdgeInsets.all(15),
      child: Container(
        width: double.infinity,
        height: 15,
        decoration: BoxDecoration(
          border: Border.all(width: 2, color: Colors.grey[800]),
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(colors: colors),
        ),
        child: CustomPaint(
          painter: _SliderIndicatorPainter(sliderPos, currentColor),
        ),
      ),
    ),
  );
}

class _SliderIndicatorPainter extends CustomPainter {
  final double position;
  final Color _color;
  _SliderIndicatorPainter(this.position, this._color);
  @override
  void paint(Canvas canvas, Size size) {
   // print(position);
    canvas.drawCircle(
        Offset(position, size.height / 2), 20, Paint()..color = _color);
  }
  @override
  bool shouldRepaint(_SliderIndicatorPainter old) {
    return true;
  }
}

Future<void> showMyDialog(context, controller, handler) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Lampi ID'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Enter your lampi ID'),
              TextField(
                controller: controller,
              )
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Ok'),
            onPressed: () {
              handler();
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}