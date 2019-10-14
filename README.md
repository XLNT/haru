# Haru — Flutter Spring Simulations

A super simple library for handling SpringSimulations in Flutter, providing conventional defaults and a clean API.

## Usage

```dart
import 'package:haru/haru.dart';

final controller = AnimationController(/* ... */)

/// 1) just animate with the simulation...

controller.animateWith(Haru.normal())

/// 2) or grab a velocity value to animate with

onPanEnd: (details) {
  final pps = details.velocity.pixelsPerSecond;
  final size = MediaQuery.of(context).size;

  final ddx = pixelsPerSecond.dx / size.width;
  final ddy = pixelsPerSecond.dy / size.height;
  final velocity = Offset(ddx, ddy).distance;

  controller.animateWith(Haru.normal(velocity));
}
```

## Inspo

`haru` is inspired by [lukepighetti/sprung](https://github.com/lukepighetti/sprung) and [react-spring/react-spring](https://github.com/react-spring/react-spring).
