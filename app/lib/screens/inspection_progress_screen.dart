import 'package:flutter/material.dart';

class InspectionProgressScreen extends StatelessWidget {
  const InspectionProgressScreen({super.key, required this.inspectionId});
  final String inspectionId;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('InspectionProgressScreen — TODO')),
    );
  }
}
