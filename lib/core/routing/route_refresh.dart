import 'package:flutter/material.dart';

/// Watches the navigator so a screen can tell when it is uncovered.
///
/// Registered on the router's `observers`. Without it nothing in the app
/// knows that a screen it pushed has just been popped off the top of it.
///
/// Scoped to [PageRoute] rather than `ModalRoute`, which also covers sheets
/// and dialogs. A bottom sheet closing is not a return from anywhere — and
/// every confirmation in this app is a sheet, so the looser type meant
/// dismissing one re-read the database for nothing.
final RouteObserver<PageRoute<void>> appRouteObserver =
    RouteObserver<PageRoute<void>>();

/// Runs [onReturn] whenever the route this sits in becomes visible again
/// after something on top of it was popped.
///
/// Every screen in this app reads its data once, when its cubit is built.
/// That was invisible for as long as leaving a screen meant `go()`, which
/// throws the stack away and rebuilds whatever it lands on — so screens were
/// always accidentally fresh. The moment a screen is *returned* to rather
/// than rebuilt, the read never happens again and the screen shows a state
/// the database left behind minutes ago: finish a drill, come back, and the
/// technique page still says you have never tried it.
///
/// Popping is the correct navigation, so this is the missing half of it.
class RefreshOnReturn extends StatefulWidget {
  const RefreshOnReturn({
    super.key,
    required this.onReturn,
    required this.child,
  });

  final VoidCallback onReturn;
  final Widget child;

  @override
  State<RefreshOnReturn> createState() => _RefreshOnReturnState();
}

class _RefreshOnReturnState extends State<RefreshOnReturn> with RouteAware {
  PageRoute<void>? _subscribed;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Null off-router — a screen pumped straight into a MaterialApp in a
    // widget test has no page route, and silently not subscribing is the
    // right answer there rather than throwing.
    final route = ModalRoute.of(context);
    if (route is! PageRoute<void> || route == _subscribed) return;
    if (_subscribed != null) appRouteObserver.unsubscribe(this);
    _subscribed = route;
    appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    if (_subscribed != null) appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// The route above this one was popped, so this one is on top again.
  @override
  void didPopNext() => widget.onReturn();

  @override
  Widget build(BuildContext context) => widget.child;
}
