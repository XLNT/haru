# 春先 Harusaki

A super simple SpringSimulation API for Flutter, providing conventional defaults.

## Usage

```dart
import 'package:harusaki/harusaki.dart';

final controller = AnimationController(/* ... */)

/// 1) just animate with the simulation...

controller.animateWith(
  Harusaki.spring(
    Harusaki.normal.
    from: 0.0,
    to: 1.0,
  ),
);

/// 2) or grab a velocity value to animate with:

onDragEnd: (details) {

  // assumes we're dragging something the size of the screen in a vertical direction
  final velocity = details.primaryVelocity / MediaQuery.of(context).size.height;

  controller.animateWith(
    Harusaki.spring(
      Harusaki.normal,
      from: controller.value,
      to: 1.0,
      velocity: velocity,
    )
  );
}
```

## API

We use the same defaults as `react-spring`, so you have the following spring simulations to choose from

- `SpringDescription Harusaki.normal([double velocity = 0])` ("default" in `react-spring`)
- `SpringDescription Harusaki.gentle([double velocity = 0])`
- `SpringDescription Harusaki.wobbly([double velocity = 0])`
- `SpringDescription Harusaki.stiff([double velocity = 0])`
- `SpringDescription Harusaki.slow([double velocity = 0])`
- `SpringDescription Harusaki.molasses([double velocity = 0])`

and you can create a conventional simulation with

- `SpringSimulation Harusaki.spring(double stiffness, double damping, [double velocity])`

and get the default tolerance with

- `Tolerance Harusaki.tolerance`

## Inspo

`harusaki` is inspired by [lukepighetti/sprung](https://github.com/lukepighetti/sprung) and [react-spring/react-spring](https://github.com/react-spring/react-spring).

The `haru` packagename was already taken, so we'll go with "the beginning of spring" as a motif ¯\\\_(ツ)_/¯

## Notes

As far as I can tell, `stiffness` and `tension` are the same concept and `damping` and `friction` are the same concept.

I've implemented a `HarusakiAnimationController` that replaces all of the normal linear animations with spring-based simulations. Since it conforms to `AnimationController`, it can be passed to any widgets that expect one. Then when those widgets call `.forward` or `.reverse` or `.fling`, it'll use the spring description you've provided to animate the value, rather than the default linear interpolation.

I haven't decided if this is useful or not yet.
