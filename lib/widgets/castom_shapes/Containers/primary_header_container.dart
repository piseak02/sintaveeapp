import 'package:flutter/material.dart';
import 'package:sintaveeapp/widgets/castom_shapes/Containers/circluar_container.dart';
import 'package:sintaveeapp/widgets/castom_shapes/curved_edges/curved_edges_widget.dart';

class TPrimaryHeaderContainer extends StatelessWidget {
  const TPrimaryHeaderContainer({
    super.key,
    required this.child,
  });
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TCurvedEdgeWidget(
      child: Container(
        color: Colors.orange,
        padding: const EdgeInsets.all(0),
        child: SizedBox(
          height: 200,
          child: Stack(
            children: [
              Positioned(
                top: -150,
                right: -250,
                child: TCircularContainer(
                  backgroundColor: const Color.fromARGB(61, 253, 250, 250),
                ),
              ),
              Positioned(
                top: 100,
                right: -300,
                child: TCircularContainer(
                  backgroundColor: const Color.fromARGB(61, 253, 250, 250),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
