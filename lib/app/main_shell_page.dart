import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key, required this.child});

  final Widget child;

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  double _dragDistance = 0.0;
  double _overscrollAccumulated = 0.0;
  bool _childScrolledHorizontally = false;
  bool _startedAtMin = false;
  bool _startedAtMax = false;

  static const double _swipeThreshold = 40.0;
  static const double _velocityThreshold = 200.0;

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location == '/') {
      return 0;
    }
    if (location.startsWith('/listas') || location.startsWith('/compras')) {
      return 1;
    }
    if (location.startsWith('/tarefas') || location.startsWith('/calendario')) {
      return 2;
    }
    if (location.startsWith('/contas')) {
      return 3;
    }
    if (location.startsWith('/despesas') || location.startsWith('/orcamento')) {
      return 4;
    }
    return 0;
  }

  void _navigateToIndex(int index, BuildContext context) {
    if (index < 0 || index > 4) return;

    final currentIndex = _calculateSelectedIndex(context);
    if (currentIndex == index) return;

    _dragDistance = 0.0;
    _overscrollAccumulated = 0.0;
    _childScrolledHorizontally = false;
    _startedAtMin = false;
    _startedAtMax = false;

    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        final current = GoRouterState.of(context).uri.toString();
        if (current.startsWith('/compras')) {
          context.go('/compras');
        } else if (_hasRoute(context, '/listas')) {
          context.go('/listas');
        } else {
          context.go('/compras');
        }
        break;
      case 2:
        context.go('/tarefas');
        break;
      case 3:
        context.go('/contas');
        break;
      case 4:
        context.go('/despesas');
        break;
    }
  }

  bool _hasRoute(BuildContext context, String path) {
    try {
      final routes = GoRouter.of(context).configuration.routes;
      return _containsPath(routes, path);
    } catch (_) {
      return false;
    }
  }

  bool _containsPath(List<RouteBase> routes, String path) {
    for (final route in routes) {
      if (route is GoRoute &&
          (route.path == path || route.path == path.replaceFirst('/', ''))) {
        return true;
      }
      if (route is ShellRoute) {
        if (_containsPath(route.routes, path)) return true;
      }
    }
    return false;
  }

  void _onSwipeLeft(BuildContext context) {
    final current = _calculateSelectedIndex(context);
    if (current < 4) {
      _navigateToIndex(current + 1, context);
    }
  }

  void _onSwipeRight(BuildContext context) {
    final current = _calculateSelectedIndex(context);
    if (current > 0) {
      _navigateToIndex(current - 1, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis != Axis.horizontal) {
            return false;
          }

          if (notification is ScrollStartNotification) {
            _childScrolledHorizontally = true;
            _overscrollAccumulated = 0.0;
            _startedAtMin = notification.metrics.extentBefore <= 0;
            _startedAtMax = notification.metrics.extentAfter <= 0;
          } else if (notification is OverscrollNotification) {
            if (_startedAtMin && notification.overscroll < 0) {
              _overscrollAccumulated += notification.overscroll;
            } else if (_startedAtMax && notification.overscroll > 0) {
              _overscrollAccumulated += notification.overscroll;
            }
          } else if (notification is ScrollUpdateNotification) {
            if (_startedAtMin &&
                notification.metrics.extentBefore <= 0 &&
                (notification.scrollDelta ?? 0) < 0) {
              _overscrollAccumulated += notification.scrollDelta!;
            } else if (_startedAtMax &&
                notification.metrics.extentAfter <= 0 &&
                (notification.scrollDelta ?? 0) > 0) {
              _overscrollAccumulated += notification.scrollDelta!;
            }
          } else if (notification is ScrollEndNotification) {
            if (_startedAtMin && _overscrollAccumulated <= -_swipeThreshold) {
              _onSwipeRight(context);
            } else if (_startedAtMax &&
                _overscrollAccumulated >= _swipeThreshold) {
              _onSwipeLeft(context);
            }
            _overscrollAccumulated = 0.0;
            _childScrolledHorizontally = false;
            _startedAtMin = false;
            _startedAtMax = false;
          }
          return false;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (details) {
            if (!_childScrolledHorizontally) {
              _dragDistance += details.primaryDelta ?? 0.0;
            }
          },
          onHorizontalDragEnd: (details) {
            if (_childScrolledHorizontally) {
              _dragDistance = 0.0;
              _childScrolledHorizontally = false;
              return;
            }
            final velocity = details.primaryVelocity ?? 0.0;
            if (_dragDistance <= -_swipeThreshold ||
                velocity <= -_velocityThreshold) {
              _onSwipeLeft(context);
            } else if (_dragDistance >= _swipeThreshold ||
                velocity >= _velocityThreshold) {
              _onSwipeRight(context);
            }
            _dragDistance = 0.0;
          },
          onHorizontalDragCancel: () {
            _dragDistance = 0.0;
            _childScrolledHorizontally = false;
          },
          child: widget.child,
        ),
      ),
      floatingActionButton: selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => context.push('/ocr'),
              tooltip: 'Escanear Nota Fiscal',
              child: const Icon(AppIcons.camera),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _navigateToIndex(index, context),
        destinations: const [
          NavigationDestination(icon: Icon(AppIcons.home), label: 'Início'),
          NavigationDestination(
            icon: Icon(AppIcons.shopping),
            label: 'Compras',
          ),
          NavigationDestination(icon: Icon(AppIcons.tasks), label: 'Tarefas'),
          NavigationDestination(icon: Icon(AppIcons.bill), label: 'Contas'),
          NavigationDestination(icon: Icon(AppIcons.budget), label: 'Despesas'),
        ],
      ),
    );
  }
}
