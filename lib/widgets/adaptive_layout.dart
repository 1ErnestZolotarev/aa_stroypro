import 'package:flutter/material.dart';

class AdaptiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget tabletBody;

  const AdaptiveLayout({
    required this.mobileBody,
    required this.tabletBody,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 768) {
      return tabletBody;
    } else {
      return mobileBody;
    }
  }
}
