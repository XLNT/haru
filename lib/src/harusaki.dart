import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/scheduler.dart';

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

/// Helpful [SpringDescription] and [SpringSimulation] things.
class Harusaki {
  /// The default tolerance for Harusaki spring simulations
  static Tolerance get tolerance => _kSpringTolerance;

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
    double lowerBound = 0.0,
    double upperBound = 1.0,
    AnimationBehavior animationBehavior = AnimationBehavior.preserve,
    @required TickerProvider vsync,
  }) =>
      HarusakiAnimationController(
        description: description,
        value: value,
        debugLabel: debugLabel,
        lowerBound: lowerBound,
        upperBound: upperBound,
        animationBehavior: animationBehavior,
        vsync: vsync,
      );
}

/// The direction in which an animation is running.
enum _AnimationDirection {
  /// The animation is running from beginning to end.
  forward,

  /// The animation is running backwards, from end to beginning.
  reverse,
}

/// A controller for an animation.
///
/// See:
///
///  * [AnimationController], the original implementation
class HarusakiAnimationController extends Animation<double>
    with
        AnimationEagerListenerMixin,
        AnimationLocalListenersMixin,
        AnimationLocalStatusListenersMixin
    implements AnimationController {
  /// Creates an animation controller.
  ///
  /// * `value` is the initial value of the animation. If defaults to the lower
  ///   bound.
  ///
  /// * [debugLabel] is a string to help identify this animation during
  ///   debugging (used by [toString]).
  ///
  /// * [lowerBound] is the smallest value this animation can obtain and the
  ///   value at which this animation is deemed to be dismissed. It cannot be
  ///   null.
  ///
  /// * [upperBound] is the largest value this animation can obtain and the
  ///   value at which this animation is deemed to be completed. It cannot be
  ///   null.
  ///
  /// * `vsync` is the [TickerProvider] for the current context. It can be
  ///   changed by calling [resync]. It is required and must not be null. See
  ///   [TickerProvider] for advice on obtaining a ticker provider.
  HarusakiAnimationController({
    SpringDescription description,
    double value,
    this.debugLabel,
    this.lowerBound = 0.0,
    this.upperBound = 1.0,
    this.animationBehavior = AnimationBehavior.preserve,
    @required TickerProvider vsync,
  })  : assert(lowerBound != null),
        assert(upperBound != null),
        assert(upperBound >= lowerBound),
        assert(vsync != null),
        _direction = _AnimationDirection.forward,
        this.description = description ?? Harusaki.normal {
    _ticker = vsync.createTicker(_tick);
    _internalSetValue(value ?? lowerBound);
  }

  final SpringDescription description;

  /// The value at which this animation is deemed to be dismissed.
  final double lowerBound;

  /// The value at which this animation is deemed to be completed.
  final double upperBound;

  /// A label that is used in the [toString] output. Intended to aid with
  /// identifying animation controller instances in debug output.
  final String debugLabel;

  /// The behavior of the controller when [AccessibilityFeatures.disableAnimations]
  /// is true.
  ///
  /// Defaults to [AnimationBehavior.normal] for the [new AnimationController]
  /// constructor, and [AnimationBehavior.preserve] for the
  /// [new AnimationController.unbounded] constructor.
  final AnimationBehavior animationBehavior;

  /// Returns an [Animation<double>] for this animation controller, so that a
  /// pointer to this object can be passed around without allowing users of that
  /// pointer to mutate the [AnimationController] state.
  Animation<double> get view => this;

  // TODO(shrugs) - implement duration estimation?
  // https://github.com/koenbok/Framer/blob/master/framer/Animators/SpringCurveValueConverter.coffee#L23
  Duration duration;
  Duration reverseDuration;

  Ticker _ticker;

  /// Recreates the [Ticker] with the new [TickerProvider].
  void resync(TickerProvider vsync) {
    final Ticker oldTicker = _ticker;
    _ticker = vsync.createTicker(_tick);
    _ticker.absorbTicker(oldTicker);
  }

  Simulation _simulation;

  /// The current value of the animation.
  ///
  /// Setting this value notifies all the listeners that the value
  /// changed.
  ///
  /// Setting this value also stops the controller if it is currently
  /// running; if this happens, it also notifies all the status
  /// listeners.
  @override
  double get value => _value;
  double _value;

  /// Stops the animation controller and sets the current value of the
  /// animation.
  ///
  /// The new value is clamped to the range set by [lowerBound] and [upperBound].
  ///
  /// Value listeners are notified even if this does not change the value.
  /// Status listeners are notified if the animation was previously playing.
  ///
  /// The most recently returned [TickerFuture], if any, is marked as having been
  /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
  /// derivative future completes with a [TickerCanceled] error.
  ///
  /// See also:
  ///
  ///  * [reset], which is equivalent to setting [value] to [lowerBound].
  ///  * [stop], which aborts the animation without changing its value or status
  ///    and without dispatching any notifications other than completing or
  ///    canceling the [TickerFuture].
  ///  * [forward], [reverse], [animateTo], [animateWith], [fling], and [repeat],
  ///    which start the animation controller.
  set value(double newValue) {
    assert(newValue != null);
    stop();
    _internalSetValue(newValue);
    notifyListeners();
    _checkStatusChanged();
  }

  /// Sets the controller's value to [lowerBound], stopping the animation (if
  /// in progress), and resetting to its beginning point, or dismissed state.
  ///
  /// The most recently returned [TickerFuture], if any, is marked as having been
  /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
  /// derivative future completes with a [TickerCanceled] error.
  ///
  /// See also:
  ///
  ///  * [value], which can be explicitly set to a specific value as desired.
  ///  * [forward], which starts the animation in the forward direction.
  ///  * [stop], which aborts the animation without changing its value or status
  ///    and without dispatching any notifications other than completing or
  ///    canceling the [TickerFuture].
  void reset() {
    value = lowerBound;
  }

  /// The rate of change of [value] per second.
  ///
  /// If [isAnimating] is false, then [value] is not changing and the rate of
  /// change is zero.
  double get velocity {
    if (!isAnimating) return 0.0;
    return _simulation
        .dx(lastElapsedDuration.inMicroseconds.toDouble() / Duration.microsecondsPerSecond);
  }

  void _internalSetValue(double newValue) {
    _value = newValue;
    if (_value == lowerBound) {
      _status = AnimationStatus.dismissed;
    } else if (_value == upperBound) {
      _status = AnimationStatus.completed;
    } else {
      _status = (_direction == _AnimationDirection.forward)
          ? AnimationStatus.forward
          : AnimationStatus.reverse;
    }
  }

  /// The amount of time that has passed between the time the animation started
  /// and the most recent tick of the animation.
  ///
  /// If the controller is not animating, the last elapsed duration is null.
  Duration get lastElapsedDuration => _lastElapsedDuration;
  Duration _lastElapsedDuration;

  /// Whether this animation is currently animating in either the forward or reverse direction.
  ///
  /// This is separate from whether it is actively ticking. An animation
  /// controller's ticker might get muted, in which case the animation
  /// controller's callbacks will no longer fire even though time is continuing
  /// to pass. See [Ticker.muted] and [TickerMode].
  bool get isAnimating => _ticker != null && _ticker.isActive;

  _AnimationDirection _direction;

  @override
  AnimationStatus get status => _status;
  AnimationStatus _status;

  /// Starts running this animation forwards (towards the end).
  ///
  /// Returns a [TickerFuture] that completes when the animation is complete.
  ///
  /// The most recently returned [TickerFuture], if any, is marked as having been
  /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
  /// derivative future completes with a [TickerCanceled] error.
  ///
  /// During the animation, [status] is reported as [AnimationStatus.forward],
  /// which switches to [AnimationStatus.completed] when [upperBound] is
  /// reached at the end of the animation.
  TickerFuture forward({double from}) {
    assert(
        _ticker != null,
        'AnimationController.forward() called after AnimationController.dispose()\n'
        'AnimationController methods should not be used after calling dispose.');
    _direction = _AnimationDirection.forward;
    if (from != null) value = from;
    return _animateToInternal(upperBound);
  }

  /// Starts running this animation in reverse (towards the beginning).
  ///
  /// Returns a [TickerFuture] that completes when the animation is dismissed.
  ///
  /// The most recently returned [TickerFuture], if any, is marked as having been
  /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
  /// derivative future completes with a [TickerCanceled] error.
  ///
  /// During the animation, [status] is reported as [AnimationStatus.reverse],
  /// which switches to [AnimationStatus.dismissed] when [lowerBound] is
  /// reached at the end of the animation.
  TickerFuture reverse({double from}) {
    assert(
        _ticker != null,
        'AnimationController.reverse() called after AnimationController.dispose()\n'
        'AnimationController methods should not be used after calling dispose.');
    _direction = _AnimationDirection.reverse;
    if (from != null) value = from;
    return _animateToInternal(lowerBound);
  }

  /// Drives the animation from its current value to target.
  ///
  /// Returns a [TickerFuture] that completes when the animation is complete.
  ///
  /// The most recently returned [TickerFuture], if any, is marked as having been
  /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
  /// derivative future completes with a [TickerCanceled] error.
  ///
  /// During the animation, [status] is reported as [AnimationStatus.forward]
  /// regardless of whether `target` > [value] or not. At the end of the
  /// animation, when `target` is reached, [status] is reported as
  /// [AnimationStatus.completed].
  TickerFuture animateTo(double target, {Duration duration, Curve curve = Curves.linear}) {
    assert(
        _ticker != null,
        'AnimationController.animateTo() called after AnimationController.dispose()\n'
        'AnimationController methods should not be used after calling dispose.');
    _direction = _AnimationDirection.forward;
    return _animateToInternal(target);
  }

  /// Drives the animation from its current value to target.
  ///
  /// Returns a [TickerFuture] that completes when the animation is complete.
  ///
  /// The most recently returned [TickerFuture], if any, is marked as having been
  /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
  /// derivative future completes with a [TickerCanceled] error.
  ///
  /// During the animation, [status] is reported as [AnimationStatus.reverse]
  /// regardless of whether `target` < [value] or not. At the end of the
  /// animation, when `target` is reached, [status] is reported as
  /// [AnimationStatus.dismissed].
  TickerFuture animateBack(double target, {Duration duration, Curve curve = Curves.linear}) {
    assert(
        _ticker != null,
        'AnimationController.animateBack() called after AnimationController.dispose()\n'
        'AnimationController methods should not be used after calling dispose.');
    _direction = _AnimationDirection.reverse;
    return _animateToInternal(target);
  }

  TickerFuture _animateToInternal(double target) {
    return animateWith(
      Harusaki.spring(
        description,
        from: value,
        to: target,
      ),
    );
  }

  /// Starts running this animation in the forward direction, and
  /// restarts the animation when it completes.
  ///
  /// Defaults to repeating between the [lowerBound] and [upperBound] of the
  /// [AnimationController] when no explicit value is set for [min] and [max].
  ///
  /// With [reverse] set to true, instead of always starting over at [min]
  /// the value will alternate between [min] and [max] values on each repeat.
  ///
  /// Returns a [TickerFuture] that never completes. The [TickerFuture.orCancel] future
  /// completes with an error when the animation is stopped (e.g. with [stop]).
  ///
  /// The most recently returned [TickerFuture], if any, is marked as having been
  /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
  /// derivative future completes with a [TickerCanceled] error.
  TickerFuture repeat({double min, double max, bool reverse = false, Duration period}) {
    return null;
    // min ??= lowerBound;
    // max ??= upperBound;
    // // period ??= duration;
    // assert(() {
    //   if (period == null) {
    //     throw FlutterError(
    //         'AnimationController.repeat() called without an explicit period and with no default Duration.\n'
    //         'Either the "period" argument to the repeat() method should be provided, or the '
    //         '"duration" property should be set, either in the constructor or later, before '
    //         'calling the repeat() function.');
    //   }
    //   return true;
    // }());
    // assert(max >= min);
    // assert(max <= upperBound && min >= lowerBound);
    // assert(reverse != null);
    // return animateWith(_RepeatingSimulation(_value, min, max, reverse, period));
  }

  /// overrides [AnimationController.fling] to use our [SpringDescription]
  /// https://github.com/flutter/flutter/blob/stable/packages/flutter/lib/src/animation/animation_controller.dart#L640
  @override
  TickerFuture fling({double velocity = 1.0, AnimationBehavior animationBehavior}) {
    return flingTo(
      velocity.isNegative
          ? lowerBound - _kSpringTolerance.distance
          : upperBound + _kSpringTolerance.distance,
      velocity: velocity,
    );
  }

  /// Flings the particle to a particular location with a specific velocity.
  /// This allows the user to fling in a direction that is not in the direction of the resting point.
  TickerFuture flingTo(double to, {double velocity = 0.0}) {
    _direction = to < value ? _AnimationDirection.reverse : _AnimationDirection.forward;

    double scale = 1.0;
    final AnimationBehavior behavior = animationBehavior ?? this.animationBehavior;
    if (SemanticsBinding.instance.disableAnimations) {
      switch (behavior) {
        case AnimationBehavior.normal:
          // TODO(jonahwilliams): determine a better process for setting velocity.
          // the value below was arbitrarily chosen because it worked for the drawer widget.
          scale = 200.0;
          break;
        case AnimationBehavior.preserve:
          break;
      }
    }

    return animateWith(
      Harusaki.spring(
        description,
        from: value,
        to: to,
        velocity: velocity * scale,
      ),
    );
  }

  /// Drives the animation according to the given simulation.
  ///
  /// Returns a [TickerFuture] that completes when the animation is complete.
  ///
  /// The most recently returned [TickerFuture], if any, is marked as having been
  /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
  /// derivative future completes with a [TickerCanceled] error.
  TickerFuture animateWith(Simulation simulation) {
    assert(
        _ticker != null,
        'AnimationController.animateWith() called after AnimationController.dispose()\n'
        'AnimationController methods should not be used after calling dispose.');
    stop();
    return _startSimulation(simulation);
  }

  TickerFuture _startSimulation(Simulation simulation) {
    assert(simulation != null);
    assert(!isAnimating);
    _simulation = simulation;
    _lastElapsedDuration = Duration.zero;
    _value = simulation.x(0.0);
    final TickerFuture result = _ticker.start();
    _status = (_direction == _AnimationDirection.forward)
        ? AnimationStatus.forward
        : AnimationStatus.reverse;
    _checkStatusChanged();
    return result;
  }

  /// Stops running this animation.
  ///
  /// This does not trigger any notifications. The animation stops in its
  /// current state.
  ///
  /// By default, the most recently returned [TickerFuture] is marked as having
  /// been canceled, meaning the future never completes and its
  /// [TickerFuture.orCancel] derivative future completes with a [TickerCanceled]
  /// error. By passing the `canceled` argument with the value false, this is
  /// reversed, and the futures complete successfully.
  ///
  /// See also:
  ///
  ///  * [reset], which stops the animation and resets it to the [lowerBound],
  ///    and which does send notifications.
  ///  * [forward], [reverse], [animateTo], [animateWith], [fling], and [repeat],
  ///    which restart the animation controller.
  void stop({bool canceled = true}) {
    assert(
        _ticker != null,
        'AnimationController.stop() called after AnimationController.dispose()\n'
        'AnimationController methods should not be used after calling dispose.');
    _simulation = null;
    _lastElapsedDuration = null;
    _ticker.stop(canceled: canceled);
  }

  /// Release the resources used by this object. The object is no longer usable
  /// after this method is called.
  ///
  /// The most recently returned [TickerFuture], if any, is marked as having been
  /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
  /// derivative future completes with a [TickerCanceled] error.
  @override
  void dispose() {
    assert(() {
      if (_ticker == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('AnimationController.dispose() called more than once.'),
          ErrorDescription('A given $runtimeType cannot be disposed more than once.\n'),
          DiagnosticsProperty<AnimationController>(
            'The following $runtimeType object was disposed multiple times',
            this,
            style: DiagnosticsTreeStyle.errorProperty,
          ),
        ]);
      }
      return true;
    }());
    _ticker.dispose();
    _ticker = null;
    super.dispose();
  }

  AnimationStatus _lastReportedStatus = AnimationStatus.dismissed;
  void _checkStatusChanged() {
    final AnimationStatus newStatus = status;
    if (_lastReportedStatus != newStatus) {
      _lastReportedStatus = newStatus;
      notifyStatusListeners(newStatus);
    }
  }

  void _tick(Duration elapsed) {
    _lastElapsedDuration = elapsed;
    final double elapsedInSeconds =
        elapsed.inMicroseconds.toDouble() / Duration.microsecondsPerSecond;
    assert(elapsedInSeconds >= 0.0);
    _value = _simulation.x(elapsedInSeconds);
    if (_simulation.isDone(elapsedInSeconds)) {
      _status = (_direction == _AnimationDirection.forward)
          ? AnimationStatus.completed
          : AnimationStatus.dismissed;
      stop(canceled: false);
    }
    notifyListeners();
    _checkStatusChanged();
  }

  @override
  String toStringDetails() {
    final String paused = isAnimating ? '' : '; paused';
    final String ticker = _ticker == null ? '; DISPOSED' : (_ticker.muted ? '; silenced' : '');
    final String label = debugLabel == null ? '' : '; for $debugLabel';
    final String more = '${super.toStringDetails()} ${value.toStringAsFixed(3)}';
    return '$more$paused$ticker$label';
  }
}
