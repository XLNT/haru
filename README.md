# Haru — Flutter Spring Simulations

A super simple SpringSimulation API for Flutter, providing conventional defaults.

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

## API

We use the same defaults as `react-spring`, so you have the following spring simulations to choose from

- `Haru.normal([double velocity = 0])` ("default" in `react-spring`)
- `Haru.gentle([double velocity = 0])`
- `Haru.wobbly([double velocity = 0])`
- `Haru.stiff([double velocity = 0])`
- `Haru.slow([double velocity = 0])`
- `Haru.molasses([double velocity = 0])`

and you can create a conventional simulation with

- `Haru.spring(double stiffness, double damping, [double velocity])`

## Inspo

`haru` is inspired by [lukepighetti/sprung](https://github.com/lukepighetti/sprung) and [react-spring/react-spring](https://github.com/react-spring/react-spring).
