import 'package:flutter/material.dart';

/// @Describe: State of the foundation.
///
/// @Author: LiWeNHuI
/// @Date: 2022/6/22

abstract class BaseState<T extends StatefulWidget> extends State<T> {
  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }
}
