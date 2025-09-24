import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgIcon extends StatelessWidget {
  // instance data

  final String name;
  final double? size;
  final Color? color;

  // constructor

  const SvgIcon(this.name, {super.key, this.size, this.color});

  // override

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      name,
      width: size,
      height: size,
      color: color,
    );
  }
}
