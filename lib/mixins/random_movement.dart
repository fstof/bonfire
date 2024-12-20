import 'dart:math';

import 'package:bonfire/bonfire.dart';

class RandomMovementDirections {
  final List<Direction> values;

  int get length => values.length;

  const RandomMovementDirections({required this.values});

  static const RandomMovementDirections all = RandomMovementDirections(
    values: Direction.values,
  );

  static const RandomMovementDirections vertically = RandomMovementDirections(
    values: [Direction.up, Direction.down],
  );

  static const RandomMovementDirections horizontally = RandomMovementDirections(
    values: [Direction.left, Direction.right],
  );

  static const RandomMovementDirections withoutDiagonal =
      RandomMovementDirections(
    values: [
      Direction.left,
      Direction.right,
      Direction.up,
      Direction.down,
    ],
  );
}

/// Mixin responsible for adding random movement like enemy walking through the scene
mixin RandomMovement on Movement {
  // ignore: constant_identifier_names
  static const _KEY_INTERVAL_KEEP_STOPPED = 'INTERVAL_RANDOM_MOVEMENT';

  Function(Direction direction)? _onStartMove;
  Function()? _onStopMove;

  late Random _random;

  double? _distanceToArrived;
  Direction _currentDirection = Direction.left;
  Vector2 _originPosition = Vector2.zero();

  double _lastMinDistance = 0;
  double _travelledDistance = 0;

  // Area where the random movement will be made
  ShapeHitbox? randomMovementArea;

  /// Method that bo used in [update] method.
  void runRandomMovement(
    double dt, {
    double? speed,
    double maxDistance = 50,
    double minDistance = 25,

    /// milliseconds
    int timeKeepStopped = 2000,
    bool updateAngle = false,
    bool checkDirectionWithRayCast = false,
    RandomMovementDirections directions = RandomMovementDirections.all,
    Function(Direction direction)? onStartMove,
    Function()? onStopMove,
  }) {
    _lastMinDistance = minDistance;
    _onStartMove = onStartMove;
    _onStopMove = onStopMove;

    if (_distanceToArrived == null) {
      if (checkInterval(_KEY_INTERVAL_KEEP_STOPPED, timeKeepStopped, dt)) {
        _distanceToArrived = _getDistance(minDistance, maxDistance);
        _currentDirection = _getDirection(directions);
        _originPosition = absoluteCenter.clone();
        if (randomMovementArea != null) {
          final targetPosition = _getTargetPosition(
            _currentDirection,
            _distanceToArrived,
          );
          final insideArea = randomMovementArea!.containsLocalPoint(
            targetPosition,
          );
          if (!insideArea) {
            _stop();
            return;
          }
        }
        if (checkDirectionWithRayCast) {
          if (!canMove(_currentDirection, displacement: _distanceToArrived)) {
            _stop();
            return;
          }
        }
        _onStartMove?.call(_currentDirection);
      }
    } else {
      _travelledDistance = absoluteCenter.distanceTo(_originPosition);
      if (_travelledDistance >= _distanceToArrived!) {
        _stop();
        return;
      }
      moveFromDirection(_currentDirection, speed: speed);
      if (updateAngle) {
        angle = _currentDirection.toRadians();
      }
    }
  }

  @override
  void correctPositionFromCollision(Vector2 position) {
    super.correctPositionFromCollision(position);
    if (this is Jumper) {
      if ((this is BlockMovementCollision)) {
        final isV = (this as BlockMovementCollision)
                .lastCollisionData
                ?.direction
                .isVertical ==
            true;
        if (isV) {
          return;
        }
      }
    }
    _stop();
  }

  void _stop() {
    _onStopMove?.call();
    if (_travelledDistance < _lastMinDistance) {
      resetInterval(_KEY_INTERVAL_KEEP_STOPPED);
    }
    _onStopMove = null;
    _onStartMove = null;
    _distanceToArrived = null;
    _originPosition = Vector2.zero();
    stopMove();
  }

  @override
  void onMount() {
    _random = Random(Random().nextInt(1000));
    super.onMount();
  }

  double? _getDistance(double minDistance, double maxDistance) {
    final diffDistane = maxDistance - minDistance;
    return minDistance + _random.nextDouble() * diffDistane;
  }

  Direction _getDirection(RandomMovementDirections directions) {
    final randomInt = _random.nextInt(directions.length);
    return directions.values[randomInt];
  }

  Vector2 _getTargetPosition(
      Direction currentDirection, double? distanceToArrived) {
    return absoluteCenter + currentDirection.toVector2() * distanceToArrived!;
  }
}
