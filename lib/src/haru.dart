import 'package:flutter/physics.dart';

/// produces a [SpringDescription] with the default mass of 1
SpringDescription _desc(double stiffness, double damping) =>
    SpringDescription(mass: 1, stiffness: stiffness, damping: damping);

/// produces a [SpringSimulation] with the default [SpringDescription]
SpringSimulation _spring(double stiffness, double damping, [double velocity = 0]) =>
    SpringSimulation(_desc(stiffness, damping), 0.0, 1.0, velocity);

class Haru {
  /// Builds a [SpringSimulation] using the default [SpringDescription]
  static SpringSimulation spring(double stiffness, double damping, [double velocity = 0]) =>
      _spring(stiffness, damping, velocity);

  // NB(shrugs) values from https://www.react-spring.io/docs/hooks/api
  // NB(shrugs) using `normal` because `default` is a reserved word.

  /// A normal spring.
  static SpringSimulation normal([double velocity = 0]) => _spring(170, 26, velocity);

  /// A gentle spring.
  static SpringSimulation gentle([double velocity = 0]) => _spring(120, 14, velocity);

  /// A wobbly spring.
  static SpringSimulation wobbly([double velocity = 0]) => _spring(180, 12, velocity);

  /// A stiff spring.
  static SpringSimulation stiff([double velocity = 0]) => _spring(210, 20, velocity);

  /// A slow spring.
  static SpringSimulation slow([double velocity = 0]) => _spring(280, 60, velocity);

  // NB(shrugs) this is technically incorrect because molasses can be incredibly fast if you give it the chance.
  // See https://en.wikipedia.org/wiki/Great_Molasses_Flood for details
  /// A spring as slow as molasses.
  static SpringSimulation molasses([double velocity = 0]) => _spring(280, 120, velocity);
}
