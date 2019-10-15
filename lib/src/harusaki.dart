import 'package:flutter/cupertino.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';

/// https://github.com/flutter/flutter/blob/stable/packages/flutter/lib/src/animation/animation_controller.dart#L39
const Tolerance _kSpringTolerance = Tolerance(
  velocity: double.infinity,
  distance: 1e-6,
);

/// Returns a [SpringDescription] with the default mass of 1
SpringDescription _desc(double stiffness, double damping) =>
    SpringDescription(mass: 1, stiffness: stiffness, damping: damping);

/// Returns a [SpringSimulation]
SpringSimulation _spring(
  SpringDescription description, {
  double from = 0.0,
  double to = 1.0,
  double velocity = 0.0,
  Tolerance tolerance = _kSpringTolerance,
}) =>
    SpringSimulation(description, from, to, velocity, tolerance: _kSpringTolerance);

/// Helpful [SpringDescription] and [SpringSimulation] helpers.
class Harusaki {
  /// Returns a [SpringSimulation]
  static SpringSimulation spring(
    SpringDescription description, {
    double from = 0.0,
    double to = 1.0,
    double velocity = 0.0,
    Tolerance tolerance = _kSpringTolerance,
  }) =>
      _spring(
        description,
        from: from,
        to: to,
        velocity: velocity,
        tolerance: tolerance,
      );

  // NB(shrugs) values from https://www.react-spring.io/docs/hooks/api
  // NB(shrugs) using `normal` because `default` is a reserved word.

  /// A normal spring.
  static SpringDescription normal = _desc(170, 26);

  /// A gentle spring.
  static SpringDescription gentle = _desc(120, 14);

  /// A wobbly spring.
  static SpringDescription wobbly = _desc(180, 12);

  /// A stiff spring.
  static SpringDescription stiff = _desc(210, 20);

  /// A slow spring.
  static SpringDescription slow = _desc(280, 60);

  // NB(shrugs) this is technically incorrect because molasses can be incredibly fast if you give it the chance.
  // see https://en.wikipedia.org/wiki/Great_Molasses_Flood for details
  /// A spring as slow as molasses.
  static SpringDescription molasses = _desc(280, 120);

  static HarusakiAnimationController controller(
    SpringDescription description, {
    double value,
    String debugLabel,
    double suggestedLowerBound = 0.0,
    double suggestedUpperBound = 1.0,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
    @required TickerProvider vsync,
  }) =>
      HarusakiAnimationController.withSpring(
        description,
        value: value,
        debugLabel: debugLabel,
        suggestedLowerBound: suggestedLowerBound,
        suggestedUpperBound: suggestedUpperBound,
        animationBehavior: animationBehavior,
        vsync: vsync,
      );
}

// NB(shrugs): perhaps this should be `implements` and we remove the clamping?
class HarusakiAnimationController extends AnimationController {
  // we store a custom spring description
  final SpringDescription description;

  // NB(shrugs) we want unbounded behavior (springs can go over their bounds!)
  // but we cant to use lower and upper bounds (conventionally 0.0 and 1.0 respectively)
  // in order to drive the spring itself.
  final double suggestedLowerBound;
  final double suggestedUpperBound;

  HarusakiAnimationController({
    @required this.description,
    double value,
    String debugLabel,
    this.suggestedLowerBound = 0.0,
    this.suggestedUpperBound = 1.0,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
    @required TickerProvider vsync,
  }) : super.unbounded(
          value: value,
          debugLabel: debugLabel,
          animationBehavior: animationBehavior,
          vsync: vsync,
        );

  factory HarusakiAnimationController.withSpring(
    SpringDescription description, {
    double value = 0.0,
    double suggestedLowerBound = 0.0,
    double suggestedUpperBound = 1.0,
    String debugLabel,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
    @required TickerProvider vsync,
  }) {
    return HarusakiAnimationController(
      description: description,
      value: value,
      debugLabel: debugLabel,
      suggestedLowerBound: suggestedLowerBound,
      suggestedUpperBound: suggestedUpperBound,
      animationBehavior: animationBehavior,
      vsync: vsync,
    );
  }

  /// overrides [AnimationController#forward] to use our [SpringDescription]
  @override
  TickerFuture forward({double from}) {
    return animateWith(
      Harusaki.spring(
        description,
        from: from ?? value,
        to: suggestedUpperBound,
        velocity: 0.0,
      ),
    );
  }

  /// overrides [AnimationController#reverse] to use our [SpringDescription]
  @override
  TickerFuture reverse({double from}) {
    return animateWith(
      Harusaki.spring(
        description,
        from: from ?? value,
        to: suggestedLowerBound,
        velocity: 0.0,
      ),
    );
  }

  /// overrides [AnimationController.fling] to use our [SpringDescription]
  /// https://github.com/flutter/flutter/blob/stable/packages/flutter/lib/src/animation/animation_controller.dart#L640
  @override
  TickerFuture fling({double velocity = 1.0, AnimationBehavior animationBehavior}) {
    // TODO(shrugs): decide if the particulars from AnimationController#fling are important
    // i.e. the `scale` parameter and the addition of `tolerance.distance`
    // The original intent seems to be to make sure that the fling animation _always_ gets to
    // at least the value lowerBound or upperBound. I don't think it's important since we set
    // our tolerance to 1e-6, which is pretty damn tiny.

    return flingTo(
      velocity.isNegative ? suggestedLowerBound : suggestedUpperBound,
      velocity: velocity,
    );
  }

  /// Flings the particle to a particular location with a specific velocity.
  /// This allows the user to fling in a direction that is not in the direction of the resting point.
  TickerFuture flingTo(double to, {double velocity = 0.0}) {
    return animateWith(
      Harusaki.spring(
        description,
        from: value,
        to: to,
        velocity: velocity,
      ),
    );
  }
}
