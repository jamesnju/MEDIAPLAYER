import 'package:flutter/material.dart';

enum RepeatMode {
  off,
  one,
  all,
}

extension RepeatModeExtension on RepeatMode {
  String get displayName {
    switch (this) {
      case RepeatMode.off:
        return 'Off';
      case RepeatMode.one:
        return 'Repeat One';
      case RepeatMode.all:
        return 'Repeat All';
    }
  }

  IconData get icon {
    switch (this) {
      case RepeatMode.off:
        return Icons.repeat;
      case RepeatMode.one:
        return Icons.repeat_one;
      case RepeatMode.all:
        return Icons.repeat;
    }
  }

  RepeatMode get next {
    switch (this) {
      case RepeatMode.off:
        return RepeatMode.one;
      case RepeatMode.one:
        return RepeatMode.all;
      case RepeatMode.all:
        return RepeatMode.off;
    }
  }
}