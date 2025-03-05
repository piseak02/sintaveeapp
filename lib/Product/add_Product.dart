import 'package:flutter/material.dart';
import 'package:sintaveeapp/widgets/castom_shapes/Containers/circluar_container.dart';
import 'package:sintaveeapp/widgets/castom_shapes/curved_edges/curved_edges.dart';

class Myaddproduct extends StatefulWidget {
  const Myaddproduct({super.key});

  @override
  State<Myaddproduct> createState() => _MyaddproductState();
}

class _MyaddproductState extends State<Myaddproduct> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ClipPath(
              clipper: TCustomCurvedEdges(),
              child: Container(
                color: Colors.orange,
                padding: const EdgeInsets.all(0),
                child: SizedBox(
                  height: 400,
                  child: Stack(
                    children: [
                      Positioned(
                        top: -150,
                        right: -250,
                        child: TCircularContainer(
                          backgroundColor:
                              const Color.fromARGB(61, 253, 250, 250),
                        ),
                      ),
                      Positioned(
                        top: 100,
                        right: -300,
                        child: TCircularContainer(
                          backgroundColor:
                              const Color.fromARGB(61, 253, 250, 250),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
