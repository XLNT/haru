# 春先 Harusaki

A super simple SpringSimulation API for Flutter, providing conventional defaults.

## Usage

```dart
import 'package:harusaki/harusaki.dart';

final controller = AnimationController(/* ... */)

/// 1) just animate with the simulation...

controller.animateWith(Harusaki.normal())

/// 2) or grab a velocity value to animate with:

onPanEnd: (details) {
  final pps = details.velocity.pixelsPerSecond;
  final size = MediaQuery.of(context).size;

  final ddx = pixelsPerSecond.dx / size.width;
  final ddy = pixelsPerSecond.dy / size.height;
  final velocity = Offset(ddx, ddy).distance;

  controller.animateWith(Harusaki.normal(velocity));
}
```

## API

We use the same defaults as `react-spring`, so you have the following spring simulations to choose from

- `Harusaki.normal([double velocity = 0])` ("default" in `react-spring`)
- `Harusaki.gentle([double velocity = 0])`
- `Harusaki.wobbly([double velocity = 0])`
- `Harusaki.stiff([double velocity = 0])`
- `Harusaki.slow([double velocity = 0])`
- `Harusaki.molasses([double velocity = 0])`

and you can create a conventional simulation with

- `Harusaki.spring(double stiffness, double damping, [double velocity])`

## Inspo

`harusaki` is inspired by [lukepighetti/sprung](https://github.com/lukepighetti/sprung) and [react-spring/react-spring](https://github.com/react-spring/react-spring).

The `haru` packagename was already taken, so we'll go with "the beginning of spring" as a motif ¯\\\_(ツ)_/¯

## Notes

As far as I can tell, `stiffness` and `tension` are the same concept and `damping` and `friction` are the same concept.
