import 'package:flutter/material.dart';

class TCircularContainer extends StatelessWidget {
  const TCircularContainer({
    super.key,
    this.child,
    this.width = 400,
    this.height = 400,
    this.radivs = 400,
    this.padding = 0,
    this.backgroundColor = Colors.orange,
  });

  final double? width;
  final double? height;
  final double radivs;
  final double padding;
  final Widget? child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radivs),
        color: backgroundColor,
      ),
    );
  }
}

class TcirilarContainer extends StatelessWidget {
  const TcirilarContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
