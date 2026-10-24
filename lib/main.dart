import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ═════════════ APP ENTRY, THEME, HOME & GAME SCREENS ═════════════

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  AdService.instance.init(); // not awaited: don't block app start
  runApp(const SpillOrDareApp());
}

class C {
  static const bg = Color(0xFF0B0614);
  static const surface = Color(0xFF160B2B);
  static const purple = Color(0xFFB026FF);
  static const pink = Color(0xFFFF2E93);
  static const cyan = Color(0xFF00E5FF);
}

Color op(Color c, double o) => c.withAlpha((o * 255).round());

extension GameModeX on GameMode {
  bool get isLocked => this == GameMode.spicy || this == GameMode.afterHours;

  String get title => switch (this) {
        GameMode.classic => 'Classic / Chill',
        GameMode.wild => 'Wild Party',
        GameMode.spicy => 'Spicy / Dirty 18+',
        GameMode.afterHours => 'After Hours / Extreme',
        GameMode.couples => 'Couples / Chemistry',
        GameMode.exposed => 'Exposed / Tea Time',
      };

  String get subtitle => switch (this) {
        GameMode.classic => 'Easy vibes for any crowd',
        GameMode.wild => 'Chaos, dares & bad decisions',
        GameMode.spicy => 'Flirty, risky, adults only',
        GameMode.afterHours => 'No limits, maximum regret 💀',
        GameMode.couples => 'Sparks, secrets & soft tension 💘',
        GameMode.exposed => 'Spill the tea or suffer ☕',
      };

  String get emoji => switch (this) {
        GameMode.classic => '😎',
        GameMode.wild => '🎉',
        GameMode.spicy => '🌶️',
        GameMode.afterHours => '💀',
        GameMode.couples => '💘',
        GameMode.exposed => '☕',
      };

  List<Color> get colors => switch (this) {
        GameMode.classic => const [C.cyan, Color(0xFF3D5AFE)],
        GameMode.wild => const [C.purple, C.pink],
        GameMode.spicy => const [C.pink, Color(0xFFFF1744)],
        GameMode.afterHours => const [Color(0xFF7C4DFF), Color(0xFF12001F)],
        GameMode.couples => const [Color(0xFFFF5F9E), Color(0xFFFF9A8B)],
        GameMode.exposed => const [Color(0xFFFFAB00), Color(0xFFFF6D00)],
      };
}

class SpillOrDareApp extends StatelessWidget {
  const SpillOrDareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spill or Dare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: C.bg,
        colorScheme: const ColorScheme.dark(
          primary: C.purple,
          secondary: C.pink,
          surface: C.surface,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ───────────────────────── HOME ─────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _ads = AdService.instance;

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: C.surface,
      ));
  }

  Future<void> _open(GameMode mode) async {
    if (!_ads.isUnlocked(mode)) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => _UnlockDialog(mode: mode),
      );
      if (ok != true || !mounted) return;

      if (!_ads.rewardedReady) {
        _ads.loadRewarded();
        _toast('Ad is still loading. Try again in a few seconds.');
        return;
      }
      final earned = await _ads.showRewarded(mode);
      if (!mounted) return;
      if (!earned) {
        _toast('Watch the full ad to unlock ${mode.title}.');
        return;
      }
      setState(() {});
      _toast('${mode.emoji} ${mode.title} unlocked for 1 hour!');
    }

    await Navigator.of(context)
        .push(fadeSlideRoute(SpinBottleScreen(mode: mode)));
    if (mounted) setState(() {}); // refresh unlock timer label
  }

  String _badge(GameMode m) {
    if (!m.isLocked) return 'FREE';
    return _ads.isUnlocked(m)
        ? '🔓 ${_ads.minutesLeft(m)}m left'
        : '🔒 WATCH AD';
  }

  Widget _modeCard(GameMode m) {
    final locked = !_ads.isUnlocked(m);
    return GestureDetector(
      onTap: () => _open(m),
      child: Opacity(
        opacity: locked ? 0.85 : 1,
        child: Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              colors: [op(m.colors[0], .9), op(m.colors[1], .9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                  color: op(m.colors[0], .35), blurRadius: 22, spreadRadius: 1),
            ],
          ),
          child: Row(
            children: [
              Text(m.emoji, style: const TextStyle(fontSize: 44)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.title,
                        style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(m.subtitle,
                        style: TextStyle(
                            fontSize: 13, color: op(Colors.white, .85))),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: op(Colors.black, .35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_badge(m),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          children: [
            const NeonTitle(),
            const SizedBox(height: 8),
            Text('Pick a vibe. Pass the phone. No mercy. 🔥',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: op(Colors.white, .7))),
            const SizedBox(height: 28),
            for (final m in GameMode.values) _modeCard(m),
          ],
        ),
      ),
      bottomNavigationBar: const SafeArea(child: BannerAdWidget()),
    );

    return MidnightBackground(child: scaffold);
  }
}

// ───────────────────────── SHARED NEON UI ─────────────────────────

/// Page transition used for Home -> Spin -> Game.
Route<T> fadeSlideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) => FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: child,
      ),
    ),
  );
}

/// Midnight Neon background: deep midnight -> dark violet gradient with soft
/// neon glow orbs behind the content for depth.
class MidnightBackground extends StatelessWidget {
  final Widget child;
  const MidnightBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF080312),
            Color(0xFF18092B),
            Color(0xFF0F021F),
            Color(0xFF080312),
          ],
          stops: [0.0, 0.38, 0.72, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -140, right: -120, child: _glow(C.purple, 380, .30)),
          Positioned(top: 260, left: -180, child: _glow(C.cyan, 340, .10)),
          Positioned(bottom: -60, right: -140, child: _glow(C.pink, 360, .20)),
          child,
        ],
      ),
    );
  }
}

/// The TRUTH / OR DARE neon logo. Each word has its own opacity so the splash
/// screen can flicker them on one by one like a real neon sign powering up.
class NeonTitle extends StatelessWidget {
  final double truthOpacity;
  final double orOpacity;
  final double dareOpacity;
  const NeonTitle({
    super.key,
    this.truthOpacity = 1,
    this.orOpacity = 1,
    this.dareOpacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Line 1: 😇 (left) TRUTH
        Opacity(
          opacity: truthOpacity,
          child: _titleLine(
            left: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(
                  angle: -0.2,
                  child: const Text('😇',
                      style: TextStyle(fontSize: 30, height: 1.05)),
                ),
                const SizedBox(width: 10),
              ],
            ),
            center: _neonText('TRUTH', const Color(0xFF00E5FF)),
          ),
        ),
        // Line 2: OR (left) DARE 😈 (right)
        _titleLine(
          left: Opacity(
            opacity: orOpacity,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _neonOutline('OR', const Color(0xFF00FF88)),
                const SizedBox(width: 10),
              ],
            ),
          ),
          center: Opacity(
            opacity: dareOpacity,
            child: _neonText('DARE', const Color(0xFFFF2E93)),
          ),
          right: Opacity(
            opacity: dareOpacity,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 10),
                Transform.rotate(
                  angle: 0.2,
                  child: const Text('😈',
                      style: TextStyle(fontSize: 30, height: 1.05)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// One title line where [center] stays in the exact horizontal middle of the
/// screen; [left] hugs it from the left and [right] from the right.
Widget _titleLine({Widget? left, required Widget center, Widget? right}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: left == null
                ? const SizedBox.shrink()
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: left,
                  ),
          ),
        ),
        center,
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: right == null
                ? const SizedBox.shrink()
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: right,
                  ),
          ),
        ),
      ],
    ),
  );
}

/// Solid neon text: w900, razor-sharp fill with two tight glow shadows.
Widget _neonText(String text, Color color, {double fontSize = 50}) {
  return Text(
    text.toUpperCase(),
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: fontSize,
      height: 1.05,
      fontWeight: FontWeight.w900,
      letterSpacing: 3,
      color: color,
      shadows: [
        Shadow(color: color, blurRadius: 4.0),
        Shadow(color: op(color, .5), blurRadius: 16.0),
      ],
    ),
  );
}

/// Hollow neon-tube text: a crisp 1.8px outline (no fill) on top of a soft
/// blurred outline of the same colour that acts as the glow.
Widget _neonOutline(String text, Color color, {double fontSize = 34}) {
  TextStyle style(Paint paint) => TextStyle(
        fontSize: fontSize,
        height: 1.05,
        fontWeight: FontWeight.w800,
        letterSpacing: 3,
        foreground: paint,
      );
  final upper = text.toUpperCase();
  final glow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..color = op(color, .8)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  final tube = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..strokeJoin = StrokeJoin.round
    ..color = color;
  return Stack(
    children: [
      Text(upper, style: style(glow)),
      Text(upper, style: style(tube)),
    ],
  );
}

/// Soft radial glow orb used purely as background decoration.
Widget _glow(Color color, double size, double strength) {
  return IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [op(color, strength), op(color, 0)],
        ),
      ),
    ),
  );
}

// ───────────────────────── SPLASH ─────────────────────────

/// 3-second "Pick Your Poison" neon splash: a half-angel / half-devil neon tube
/// icon and sign text flicker on during the first 0.8s, then fade into Home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3));

  // 1 = tube lit, ~0 = dark. Irregular pattern = flicker.
  static const List<double> _pattern = [1, 0, 1, 0, .55, 1, 0, 1, .25, 1, 0, 1];
  static const double _flickerEnd = 0.8 / 3; // first 0.8s of the 3s

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) _goHome();
    });
    _c.forward();
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (_, __, ___) => const HomeScreen(),
      transitionsBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeInOut);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.03), end: Offset.zero)
                .animate(curved),
            child: child,
          ),
        );
      },
    ));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Opacity at time [t] (0..1): faintly dark before [start], flickering until
  /// [end], then steady on.
  double _flick(double t, double start, double end) {
    const off = 0.07; // an unlit tube is still faintly visible
    if (t < start) return off;
    if (t >= end) return 1;
    final p = (t - start) / (end - start);
    if (p > 0.86) return 1;
    final v =
        _pattern[(p * _pattern.length).floor().clamp(0, _pattern.length - 1)];
    return off + (1 - off) * v;
  }

  @override
  Widget build(BuildContext context) {
    return MidnightBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              final t = _c.value;
              final iconOp = _flick(t, 0.0, _flickerEnd);
              final textOp = _flick(t, 0.03, _flickerEnd);
              final tagline = ((t - 0.78) / 0.18).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: iconOp,
                      child: const SizedBox(
                        width: 180,
                        height: 180,
                        child: CustomPaint(painter: AngelDevilPainter()),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Opacity(
                      opacity: textOp,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'PICK YOUR',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              color: const Color(0xFFFFD000),
                              shadows: [
                                const Shadow(
                                    color: Color(0xFFFFD000), blurRadius: 4),
                                Shadow(
                                    color: op(const Color(0xFFFFB300), .6),
                                    blurRadius: 18),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'POISON',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 44,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 5,
                              color: const Color(0xFFFF2E93),
                              shadows: [
                                const Shadow(
                                    color: Color(0xFFFF2E93), blurRadius: 4),
                                Shadow(
                                    color: op(const Color(0xFFFF2E93), .7),
                                    blurRadius: 16),
                                Shadow(
                                    color: op(const Color(0xFFBD00FF), .6),
                                    blurRadius: 30),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    Opacity(
                      opacity: tagline,
                      child: Text('PICK A VIBE. PASS THE PHONE. NO MERCY.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                              color: op(Colors.white, .65))),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Half-angel (gold, halo) / half-devil (pink-violet, horn, wink) face drawn
/// as a glowing neon glass tube sign: layered blur + crisp tube + white core.
class AngelDevilPainter extends CustomPainter {
  const AngelDevilPainter();

  static const Color gold = Color(0xFFFFD000);
  static const Color pink = Color(0xFFFF2E93);
  static const Color violet = Color(0xFFBD00FF);

  void _tube(Canvas canvas, Path path, Color color, Color halo, double w) {
    Paint stroke(double width, Color c, [double blur = 0]) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = c;
      if (blur > 0) p.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
      return p;
    }

    canvas.drawPath(path, stroke(w * 3.4, op(halo, .55), 14)); // ambient glow
    canvas.drawPath(path, stroke(w * 1.9, op(color, .85), 5)); // aura
    canvas.drawPath(path, stroke(w, color)); // crisp tube
    canvas.drawPath(path, stroke(w * .35, op(Colors.white, .85))); // hot core
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w * .32;
    final cx = w / 2;
    final cy = h * .62;
    final face = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    const sw = 3.2;

    // Face halves (left = angel, right = devil)
    _tube(canvas, Path()..addArc(face, pi / 2, pi), gold, gold, sw);
    _tube(canvas, Path()..addArc(face, -pi / 2, pi), pink, violet, sw);

    // Centre seam
    _tube(
      canvas,
      Path()
        ..moveTo(cx, cy - r)
        ..lineTo(cx, cy + r),
      const Color(0xFFFFE9A8),
      pink,
      sw * .55,
    );

    // Halo (floating above the left half, slightly tilted)
    canvas.save();
    canvas.translate(cx - r * .32, cy - r * 1.22);
    canvas.rotate(-0.2);
    _tube(
      canvas,
      Path()
        ..addOval(Rect.fromCenter(
            center: Offset.zero, width: r * 1.0, height: r * .3)),
      gold,
      gold,
      sw * .9,
    );
    canvas.restore();

    // Pointed horn on the right half
    _tube(
      canvas,
      Path()
        ..moveTo(cx + r * .25, cy - r * .96)
        ..quadraticBezierTo(
            cx + r * .5, cy - r * 1.5, cx + r * .95, cy - r * 1.7)
        ..quadraticBezierTo(
            cx + r * .9, cy - r * 1.15, cx + r * .86, cy - r * .52),
      pink,
      violet,
      sw,
    );

    // Left eye (open) + right eye (wink)
    _tube(
      canvas,
      Path()
        ..addOval(Rect.fromCircle(
            center: Offset(cx - r * .4, cy - r * .12), radius: r * .11)),
      gold,
      gold,
      sw * .8,
    );
    _tube(
      canvas,
      Path()
        ..moveTo(cx + r * .2, cy - r * .08)
        ..quadraticBezierTo(
            cx + r * .4, cy - r * .3, cx + r * .62, cy - r * .08),
      pink,
      violet,
      sw * .8,
    );

    // Smile: gold on the angel side, pink smirk on the devil side
    _tube(
      canvas,
      Path()
        ..moveTo(cx - r * .52, cy + r * .3)
        ..quadraticBezierTo(cx - r * .3, cy + r * .62, cx, cy + r * .62),
      gold,
      gold,
      sw * .8,
    );
    _tube(
      canvas,
      Path()
        ..moveTo(cx, cy + r * .62)
        ..quadraticBezierTo(
            cx + r * .4, cy + r * .62, cx + r * .58, cy + r * .24),
      pink,
      violet,
      sw * .8,
    );
  }

  @override
  bool shouldRepaint(AngelDevilPainter old) => false;
}

// ───────────────────────── SPIN THE BOTTLE ─────────────────────────

class SpinBottleScreen extends StatefulWidget {
  final GameMode mode;
  const SpinBottleScreen({super.key, required this.mode});

  @override
  State<SpinBottleScreen> createState() => _SpinBottleScreenState();
}

class _SpinBottleScreenState extends State<SpinBottleScreen>
    with SingleTickerProviderStateMixin {
  final _rng = Random();
  late final AnimationController _ctl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3600));
  late final Animation<double> _curve =
      CurvedAnimation(parent: _ctl, curve: Curves.easeOutCubic);

  double _from = 0;
  double _to = 0;
  bool _spinning = false;
  bool _spun = false;
  String _result = '';

  static const List<String> _results = [
    'The bottle has spoken! 🍾',
    'Fate points that way... 👀',
    'No escape now. 😈',
    "Somebody's in trouble! 🔥",
    'The neck never lies. 😏',
  ];

  @override
  void initState() {
    super.initState();
    _ctl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _onSpinEnd();
    });
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  /// Spins with a smooth easeOutCubic deceleration and a random stop angle.
  /// [speed] (px/s from a flick) adds extra turns.
  void _spin([double speed = 0]) {
    if (_spinning) return;
    HapticFeedback.mediumImpact();
    final double turns =
        3 + _rng.nextDouble() * 3 + (speed / 2500).clamp(0.0, 3.0).toDouble();
    _from = _from % (2 * pi);
    _to = _from + turns * 2 * pi; // random fractional turn = random stop angle
    _ctl.duration = Duration(milliseconds: (2600 + turns * 280).round());
    setState(() => _spinning = true);
    _ctl
      ..reset()
      ..forward();
  }

  void _onSpinEnd() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _from = _to % (2 * pi);
      _to = _from;
      _spinning = false;
      _spun = true;
      _result = _results[_rng.nextInt(_results.length)];
    });
  }

  void _drawCard() {
    Navigator.of(context)
        .pushReplacement(fadeSlideRoute(GameScreen(mode: widget.mode)));
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mode;
    final c1 = m.colors[0];
    final c2 = m.colors[1];

    return MidnightBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('${m.emoji} ${m.title}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _spin,
                    onPanEnd: (d) => _spin(d.velocity.pixelsPerSecond.distance),
                    child: SizedBox(
                      width: 300,
                      height: 380,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _glow(c1, 300, _spinning ? .45 : .3),
                          AnimatedBuilder(
                            animation: _curve,
                            builder: (_, child) => Transform.rotate(
                              angle: _from + (_to - _from) * _curve.value,
                              child: child,
                            ),
                            child: CustomPaint(
                              size: const Size(110, 300),
                              painter: BottlePainter(c1, c2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                _spinning
                    ? 'Spinning...'
                    : _spun
                        ? _result
                        : 'Tap or flick the bottle to spin',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: op(Colors.white, _spun ? .95 : .7)),
              ),
              const SizedBox(height: 4),
              Text(
                _spun
                    ? 'The neck points at the chosen one'
                    : 'Spin to pick who goes first',
                style: TextStyle(fontSize: 12, color: op(Colors.white, .5)),
              ),
              const SizedBox(height: 18),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _spinning ? .4 : (_spun ? 1 : .75),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(colors: [c1, c2]),
                    boxShadow: [
                      BoxShadow(
                        color: op(c1, _spun ? .65 : .25),
                        blurRadius: _spun ? 26 : 10,
                        spreadRadius: _spun ? 1 : 0,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _spinning ? null : _drawCard,
                      child: const Center(
                        child: Text('Draw Card ➔',
                            style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const SafeArea(child: BannerAdWidget()),
      ),
    );
  }
}

/// Glowing glass neon bottle with cylinder shading and a specular highlight.
class BottlePainter extends CustomPainter {
  final Color c1;
  final Color c2;
  const BottlePainter(this.c1, this.c2);

  Path _bottle(Size s) {
    final w = s.width;
    final h = s.height;
    return Path()
      ..moveTo(w * .40, h * .02)
      ..lineTo(w * .60, h * .02)
      ..lineTo(w * .60, h * .30)
      ..cubicTo(w * .60, h * .40, w * .92, h * .40, w * .92, h * .52)
      ..lineTo(w * .92, h * .92)
      ..quadraticBezierTo(w * .92, h * .98, w * .80, h * .98)
      ..lineTo(w * .20, h * .98)
      ..quadraticBezierTo(w * .08, h * .98, w * .08, h * .92)
      ..lineTo(w * .08, h * .52)
      ..cubicTo(w * .08, h * .40, w * .40, h * .40, w * .40, h * .30)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    final path = _bottle(size);

    // Outer neon glow
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = op(c1, .75)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Glass body: horizontal cylinder shading
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [op(c2, .10), op(c1, .55), op(c2, .12)],
          stops: const [0, .42, 1],
        ).createShader(rect),
    );

    // Inner depth + label band (clipped to the bottle)
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, op(Colors.black, .35)],
        ).createShader(rect),
    );
    final band = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .08, h * .60, w * .84, h * .20),
      const Radius.circular(6),
    );
    canvas.drawRRect(band, Paint()..color = op(Colors.white, .08));
    canvas.drawRRect(
      band,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = op(c2, .9),
    );
    canvas.restore();

    // Crisp neon tube outline
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..color = c1,
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = op(Colors.white, .7),
    );

    // Cap ring on the neck (the pointer end)
    canvas.drawLine(
      Offset(w * .37, h * .075),
      Offset(w * .63, h * .075),
      Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = c2,
    );

    // Specular highlights
    final hi = Paint()
      ..strokeCap = StrokeCap.round
      ..color = op(Colors.white, .45);
    canvas.drawLine(Offset(w * .22, h * .56), Offset(w * .22, h * .90),
        hi..strokeWidth = 4);
    canvas.drawLine(Offset(w * .46, h * .10), Offset(w * .46, h * .28),
        hi..strokeWidth = 2.5);

    // Pivot dot
    final center = Offset(w / 2, h / 2);
    canvas.drawCircle(
      center,
      9,
      Paint()
        ..color = op(c2, .9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(center, 4.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(BottlePainter old) => old.c1 != c1 || old.c2 != c2;
}

class _UnlockDialog extends StatelessWidget {
  final GameMode mode;
  const _UnlockDialog({required this.mode});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: C.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: mode.colors[0], width: 1.5),
      ),
      title: Text('${mode.emoji} ${mode.title}',
          style: const TextStyle(fontWeight: FontWeight.w900)),
      content: const Text(
        'This mode is for adults only (18+). Confirm your age and watch a short '
        'video ad to unlock it for 1 hour.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Not now'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: mode.colors[0]),
          onPressed: () => Navigator.pop(context, true),
          child: const Text("I'm 18+ · Watch ad"),
        ),
      ],
    );
  }
}

// ───────────────────────── GAME ─────────────────────────

enum TurnPhase { choose, flipping, revealed }

class GameScreen extends StatefulWidget {
  final GameMode mode;
  const GameScreen({super.key, required this.mode});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  static const Color _green = Color(0xFF00FF88);
  static const Color _red = Color(0xFFFF3B6B);
  static const double _swipeDistance = 110;

  late final AnimationController _flip = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 750));
  late final AnimationController _move = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 280));

  TurnPhase _phase = TurnPhase.choose;
  PromptType _type = PromptType.truth;
  String _text = '';
  double _dx = 0; // horizontal drag offset of the revealed card
  double _fromDx = 0;
  double _toDx = 0;
  bool? _finishDone; // non-null while the card is flying out (true = done)
  int _doneCount = 0;
  int _passCount = 0;

  @override
  void initState() {
    super.initState();
    _move.addListener(() {
      final v = Curves.easeOutCubic.transform(_move.value);
      setState(() => _dx = _fromDx + (_toDx - _fromDx) * v);
    });
    _move.addStatusListener((s) {
      if (s == AnimationStatus.completed && _finishDone != null) {
        _nextTurn(_finishDone!);
      }
    });
  }

  @override
  void dispose() {
    _flip.dispose();
    _move.dispose();
    super.dispose();
  }

  bool get _canSwipe => _phase == TurnPhase.revealed && _finishDone == null;

  /// Player taps TRUTH or DARE: draw a prompt and flip the card to reveal it.
  Future<void> _choose(PromptType t) async {
    if (_phase != TurnPhase.choose) return;
    HapticFeedback.lightImpact();
    setState(() {
      _type = t;
      _text = DeckManager.draw(widget.mode, t);
      _phase = TurnPhase.flipping;
      _dx = 0;
    });
    await _flip.forward(from: 0);
    if (!mounted) return;
    setState(() => _phase = TurnPhase.revealed);
  }

  void _animateDx(double target, {bool? finish}) {
    _fromDx = _dx;
    _toDx = target;
    _finishDone = finish;
    _move.duration = Duration(milliseconds: finish == null ? 220 : 280);
    _move.forward(from: 0);
  }

  /// Fling the card away: right = done, left = pass.
  void _dismiss(bool done) {
    if (!_canSwipe) return;
    HapticFeedback.mediumImpact();
    final w = MediaQuery.of(context).size.width;
    _animateDx(done ? w * 1.3 : -w * 1.3, finish: done);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_canSwipe) return;
    if (_move.isAnimating) _move.stop();
    setState(() => _dx += d.delta.dx);
  }

  void _onPanEnd(DragEndDetails d) {
    if (!_canSwipe) return;
    final v = d.velocity.pixelsPerSecond.dx;
    if (_dx > _swipeDistance || (v > 800 && _dx > 20)) {
      _dismiss(true);
    } else if (_dx < -_swipeDistance || (v < -800 && _dx < -20)) {
      _dismiss(false);
    } else {
      _animateDx(0); // snap back
    }
  }

  void _nextTurn(bool done) {
    if (!mounted) return;
    AdService.instance.onPromptShown(); // interstitial every 6th prompt
    setState(() {
      if (done) {
        _doneCount++;
      } else {
        _passCount++;
      }
      _finishDone = null;
      _dx = 0;
      _flip.value = 0;
      _phase = TurnPhase.choose;
    });
  }

  void _backToSpin() {
    Navigator.of(context)
        .pushReplacement(fadeSlideRoute(SpinBottleScreen(mode: widget.mode)));
  }

  Color _accent(PromptType t) => t == PromptType.truth ? C.cyan : C.pink;

  /// Glowing "😇 TRUTH" / "😈 DARE" card (front of the flip card).
  Widget _choiceCard(PromptType t, double height) {
    final truth = t == PromptType.truth;
    final color = _accent(t);
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [op(color, .22), C.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: color, width: 2.5),
        boxShadow: [
          BoxShadow(color: op(color, .55), blurRadius: 26, spreadRadius: 1),
          BoxShadow(color: op(color, .25), blurRadius: 60),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(truth ? '😇' : '😈', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              truth ? 'TRUTH' : 'DARE',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: color,
                shadows: [
                  Shadow(color: color, blurRadius: 4),
                  Shadow(color: op(color, .5), blurRadius: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('tap to flip',
              style: TextStyle(fontSize: 12, color: op(Colors.white, .6))),
        ],
      ),
    );
  }

  Widget _stamp(String label, Color color, double opacity, double angle) {
    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: op(Colors.black, .35),
            border: Border.all(color: color, width: 3),
            boxShadow: [BoxShadow(color: op(color, .8), blurRadius: 16)],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: color,
              shadows: [Shadow(color: color, blurRadius: 8)],
            ),
          ),
        ),
      ),
    );
  }

  /// Back of the flip card: the prompt, with neon swipe indicators.
  Widget _promptCard(double height) {
    final truth = _type == PromptType.truth;
    final colors = truth ? const [C.cyan, C.purple] : const [C.pink, C.purple];
    final strength = (_dx.abs() / _swipeDistance).clamp(0.0, 1.0).toDouble();
    final glow = _dx >= 0 ? _green : _red;
    final edge = Color.lerp(op(Colors.white, .15), glow, strength)!;
    final shadow = Color.lerp(op(colors[0], .45), op(glow, .85), strength)!;
    return Stack(
      children: [
        Container(
          height: height,
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: edge, width: 2 + 2 * strength),
            boxShadow: [
              BoxShadow(
                  color: shadow,
                  blurRadius: 30 + 20 * strength,
                  spreadRadius: 2),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: op(Colors.black, .3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(truth ? '😇 TRUTH' : '😈 DARE',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontSize: 13)),
              ),
              const SizedBox(height: 22),
              Text(_text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 24,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 22),
              Text('swipe right ✅ done  ·  swipe left ❌ pass',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: op(Colors.white, .65))),
            ],
          ),
        ),
        Positioned(
          top: 18,
          left: 18,
          child: _stamp('DONE ✅', _green,
              (_dx / _swipeDistance).clamp(0.0, 1.0).toDouble(), -0.2),
        ),
        Positioned(
          top: 18,
          right: 18,
          child: _stamp('PASS ❌', _red,
              (-_dx / _swipeDistance).clamp(0.0, 1.0).toDouble(), 0.2),
        ),
      ],
    );
  }

  Widget _stage(double h) {
    if (_phase == TurnPhase.choose) {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _choose(PromptType.truth),
              child: _choiceCard(PromptType.truth, h),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: GestureDetector(
              onTap: () => _choose(PromptType.dare),
              child: _choiceCard(PromptType.dare, h),
            ),
          ),
        ],
      );
    }

    final w = MediaQuery.of(context).size.width;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: Offset(_dx, 0),
        child: Transform.rotate(
          angle: (_dx / w) * 0.4,
          child: AnimatedBuilder(
            animation: _flip,
            builder: (_, __) {
              final angle = Curves.easeInOutCubic.transform(_flip.value) * pi;
              final showFront = angle < pi / 2;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: showFront
                    ? _choiceCard(_type, h)
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(pi),
                        child: _promptCard(h),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback? onTap) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : .35,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: op(color, .14),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color, width: 2),
            boxShadow: enabled
                ? [BoxShadow(color: op(color, .45), blurRadius: 16)]
                : const [],
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: color)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hint = switch (_phase) {
      TurnPhase.choose => 'Choose your fate',
      TurnPhase.flipping => '...',
      TurnPhase.revealed => 'Swipe the card or use the buttons',
    };
    return MidnightBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            tooltip: 'Exit game',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(widget.mode.title,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.rotate_right_rounded),
              tooltip: 'Spin the bottle',
              onPressed: (_phase == TurnPhase.choose) ? _backToSpin : null,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('✅ $_doneCount  ❌ $_passCount',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: op(Colors.white, .7))),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            children: [
              Text(hint,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: op(Colors.white, .7))),
              Expanded(
                child: LayoutBuilder(
                  builder: (_, c) {
                    final h = c.maxHeight.clamp(200.0, 380.0).toDouble();
                    return Center(child: _stage(h));
                  },
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _actionButton('❌  PASS', _red,
                        _canSwipe ? () => _dismiss(false) : null),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _actionButton('DONE  ✅', _green,
                        _canSwipe ? () => _dismiss(true) : null),
                  ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: const SafeArea(child: BannerAdWidget()),
      ),
    );
  }
}

// ═════════════ ADMOB SERVICE & BANNER WIDGET ═════════════

/// Google's official TEST ad unit IDs. Replace with your real IDs before release.
class AdIds {
  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  static String get banner => _isAndroid
      ? 'ca-app-pub-5971667510366314/4693603565'
      : 'ca-app-pub-3940256099942544/2934735716';
  static String get interstitial => _isAndroid
      ? 'ca-app-pub-5971667510366314/2067440224'
      : 'ca-app-pub-3940256099942544/4411468910';
  static String get rewarded => _isAndroid
      ? 'ca-app-pub-5971667510366314/4829334933'
      : 'ca-app-pub-3940256099942544/1712485313';
}

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  static const int interstitialEvery = 6; // every 6th prompt
  static const Duration minGap = Duration(seconds: 60); // frequency cap
  static const Duration unlockDuration = Duration(hours: 1);

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _loadingInterstitial = false;
  bool _loadingRewarded = false;
  int _promptCount = 0;
  DateTime? _lastInterstitial;
  final Map<GameMode, DateTime> _unlockedUntil = {};

  // On web there are no AdMob ads, so the rewarded flow is simulated for testing.
  bool get rewardedReady => kIsWeb || _rewarded != null;

  /// Locked modes (Spicy, After Hours) unlock independently for 1 hour each.
  bool isUnlocked(GameMode mode) {
    if (!mode.isLocked) return true;
    final until = _unlockedUntil[mode];
    return until != null && DateTime.now().isBefore(until);
  }

  int minutesLeft(GameMode mode) =>
      isUnlocked(mode) && _unlockedUntil[mode] != null
          ? _unlockedUntil[mode]!.difference(DateTime.now()).inMinutes + 1
          : 0;

  Future<void> init() async {
    if (kIsWeb) return; // google_mobile_ads doesn't support web
    await MobileAds.instance.initialize();
    loadInterstitial();
    loadRewarded();
  }

  void loadInterstitial() {
    if (kIsWeb) return;
    if (_interstitial != null || _loadingInterstitial) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (e) {
          _loadingInterstitial = false;
          debugPrint('Interstitial failed: $e');
        },
      ),
    );
  }

  void loadRewarded() {
    if (kIsWeb) return;
    if (_rewarded != null || _loadingRewarded) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _loadingRewarded = false;
        },
        onAdFailedToLoad: (e) {
          _loadingRewarded = false;
          debugPrint('Rewarded failed: $e');
        },
      ),
    );
  }

  /// Call every time a new prompt is shown. Shows an interstitial on every
  /// 6th prompt, as long as the frequency cap allows it.
  void onPromptShown() {
    if (kIsWeb) return;
    _promptCount++;
    if (_promptCount % interstitialEvery != 0) return;
    final now = DateTime.now();
    if (_lastInterstitial != null &&
        now.difference(_lastInterstitial!) < minGap) {
      return;
    }
    final ad = _interstitial;
    if (ad == null) {
      loadInterstitial();
      return;
    }
    _interstitial = null;
    _lastInterstitial = now;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        loadInterstitial();
      },
    );
    ad.show();
  }

  /// Shows the rewarded ad. Completes with true only if the reward was earned.
  Future<bool> showRewarded(GameMode mode) {
    if (kIsWeb) {
      // Web preview: simulate a completed rewarded ad so unlock flow can be tested.
      _unlockedUntil[mode] = DateTime.now().add(unlockDuration);
      return Future.value(true);
    }
    final ad = _rewarded;
    if (ad == null) {
      loadRewarded();
      return Future.value(false);
    }
    _rewarded = null;
    final done = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        loadRewarded();
        if (!done.isCompleted) done.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        loadRewarded();
        if (!done.isCompleted) done.complete(false);
      },
    );
    ad.show(onUserEarnedReward: (_, __) {
      earned = true;
      _unlockedUntil[mode] = DateTime.now().add(unlockDuration);
    });
    return done.future;
  }
}

/// Sticky 320x50 banner. Collapses to an empty box if the ad fails to load.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return; // no banner ads on web
    _ad = BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, e) {
          ad.dispose();
          _ad = null;
          debugPrint('Banner failed: $e');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Container(
        height: 50,
        width: double.infinity,
        alignment: Alignment.center,
        color: op(Colors.white, .06),
        child: Text('Banner ad placeholder (web preview)',
            style: TextStyle(fontSize: 11, color: op(Colors.white, .5))),
      );
    }
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: (_loaded && _ad != null)
          ? Center(
              child:
                  SizedBox(width: 320, height: 50, child: AdWidget(ad: _ad!)))
          : null,
    );
  }
}

// ═════════════ SHUFFLED DECKS (NO REPEATS UNTIL A DECK IS EXHAUSTED) ═════════════

/// Keeps one shuffled deck per mode + prompt type for the whole app run, so
/// nothing repeats (even after leaving and re-entering a mode) until every
/// prompt in that deck has been played. Then it reshuffles.
class DeckManager {
  static final Random _rng = Random();
  static final Map<String, List<String>> _decks = {};
  static final Map<String, int> _pos = {};
  static final Map<String, String> _last = {};

  static String draw(GameMode mode, PromptType type) {
    final key = '${mode.name}_${type.name}';
    var deck = _decks[key];
    var i = _pos[key] ?? 0;
    if (deck == null || i >= deck.length) {
      deck = List<String>.of(kPrompts[mode]![type]!)..shuffle(_rng);
      final last = _last[key];
      if (last != null && deck.length > 1 && deck.first == last) {
        final j = 1 + _rng.nextInt(deck.length - 1);
        final tmp = deck[0];
        deck[0] = deck[j];
        deck[j] = tmp;
      }
      _decks[key] = deck;
      i = 0;
    }
    _pos[key] = i + 1;
    final prompt = deck[i];
    _last[key] = prompt;
    return prompt;
  }
}

// ═════════════ OFFLINE PROMPT DATABASE ═════════════

enum GameMode { classic, wild, spicy, afterHours, couples, exposed }

enum PromptType { truth, dare }

/// Fully offline prompt database: 25 Truths + 25 Dares per mode.
const Map<GameMode, Map<PromptType, List<String>>> kPrompts = {
  GameMode.classic: {
    PromptType.truth: [
      "What's the most embarrassing thing you've done on a night out?",
      "Which celebrity would you swap lives with for a week?",
      "What's the worst lie you've ever told your parents?",
      "What's your most irrational fear?",
      "Have you ever stalked an ex on Instagram at 2am?",
      "What's the last thing you Googled that you'd hate us to see?",
      "Who in this room would survive longest in a zombie apocalypse?",
      "What's the cringiest song in your Spotify Wrapped?",
      "Have you ever pretended to love a gift you absolutely hated?",
      "What's the most childish thing you still do?",
      "What's your biggest ick?",
      "Have you ever ghosted someone? Why?",
      "What's the worst fashion choice you've ever made?",
      "What's a secret talent nobody here knows about?",
      "Have you ever sent a text to the wrong person? What did it say?",
      "What's the pettiest reason you've stopped talking to someone?",
      "Which group chat are you most tempted to mute right now?",
      "What's the most money you've wasted on something dumb?",
      "If your search history went public, what would the headline be?",
      "Who was your first celebrity crush, and do you cringe about it now?",
      "What's the worst date you've ever been on?",
      "Have you ever laughed at the worst possible moment, like a funeral or a meeting?",
      "What's your guilty-pleasure reality show: Love Island, Jersey Shore, or something worse?",
      "What's the nicest thing someone has done for you that you never thanked them for?",
      "What's the most useless thing you're weirdly proud of?",
    ],
    PromptType.dare: [
      "Do your best Gordon Ramsay or Simon Cowell impression until your next turn.",
      "Speak in a British accent (or American if you're British) for the next three rounds.",
      "Show the group the last five photos in your camera roll.",
      "Do 15 jumping jacks while singing your national anthem.",
      "Text your mum or dad: 'I love you more than pizza.'",
      "Do your best TikTok dance for 20 seconds.",
      "Speak only in rhyme for the next two turns.",
      "Let the person on your left restyle your hair however they like.",
      "Balance a spoon on your nose for 10 seconds.",
      "Sing the chorus of the last song you played, as loud as you can.",
      "Walk across the room in dramatic slow motion like it's a movie trailer.",
      "Eat a spoonful of a condiment chosen by the group.",
      "Hold a plank until the next player finishes their turn.",
      "Swap an item of clothing with the person on your right.",
      "Act out a famous movie scene without speaking. The group must guess it.",
      "Narrate your morning routine like a David Attenborough documentary.",
      "Call a friend and sing Happy Birthday, even if it isn't their birthday.",
      "Strut to the kitchen and back like you're on a Paris runway.",
      "Try to lick your own elbow. Everyone gets three tries to judge you.",
      "Do your best villain laugh for 10 seconds without cracking up.",
      "Read your most recent Notes app entry out loud.",
      "Be a news reporter and give a live report on what's happening in this room.",
      "Do ten squats while saying something nice about each player.",
      "Make up a 15-second rap about the person on your left.",
      "Eat a snack without using your hands.",
    ],
  },
  GameMode.wild: {
    PromptType.truth: [
      "What's the drunkest you've ever been?",
      "What's the worst thing you've done at a house party?",
      "Who here would you most like to see on Love Island?",
      "Have you ever been sick in an Uber, a taxi, or on the night bus?",
      "What's the wildest place you've ever woken up after a night out?",
      "What's the most embarrassing thing you've done while tipsy?",
      "Have you ever crashed a party you weren't invited to?",
      "What's the worst message you've sent while drunk?",
      "Who here would you trust least with a secret?",
      "Have you ever been kicked out of a bar or club?",
      "What's the most scandalous thing you've seen at a wedding?",
      "Who here would get lost first on a trip to Vegas or Magaluf?",
      "What's the biggest rule you broke at uni or college?",
      "Have you ever fake-cried to get out of trouble?",
      "What's the sneakiest thing you've done to get free food or drinks?",
      "Have you ever been caught sneaking in or out of somewhere?",
      "What's the most you've ever spent in a single night out?",
      "Who here has the best worst-decision story?",
      "What's the biggest white lie you've told at work or school?",
      "Have you ever talked trash about someone in this room? Who?",
      "What's the most regrettable tattoo, haircut, or purchase you've made after a night out?",
      "What's the weirdest thing you've ever done for money?",
      "Have you ever pretended to be someone else online?",
      "What's the most chaotic thing that's ever happened at a family gathering?",
      "If you could swap lives with someone in this room for a day, who would it be and why?",
    ],
    PromptType.dare: [
      "Take a shot of water like it's tequila and pull the full dramatic face.",
      "Down a drink of the group's choosing in 10 seconds. Water counts, drink responsibly!",
      "Do a body-roll across the room.",
      "Let the player on your right send one text from your phone. The group approves it first.",
      "Challenge someone to a 30-second dance battle.",
      "Perform karaoke to whatever song the group picks.",
      "Call a random contact and tell them they've won a prize.",
      "Accept a new nickname chosen by the group and answer to it all night.",
      "Take a selfie with the ugliest face you can make and set it as your lock screen for 10 minutes.",
      "Attempt a handstand or a cartwheel.",
      "Eat a snack mix the group invents from the kitchen. Nothing harmful!",
      "Speak only in questions until your next turn.",
      "Give a dramatic 'I'm here for the right reasons' Love Island speech.",
      "Piggyback another player across the room.",
      "Act like a chicken until your next turn.",
      "Let someone draw on your face with a washable marker.",
      "Lead the group in a conga line around the house.",
      "Do an impression of every player in the room, one by one.",
      "Post an embarrassing childhood photo to your story.",
      "Phone a friend and speak only in song lyrics for 30 seconds.",
      "Do the floss, the worm, or the Macarena. The group chooses.",
      "Swap seats with someone and impersonate them until your next turn.",
      "Perform an interpretive dance to a song of the group's choice.",
      "Do a 30-second stand-up comedy set about this party.",
      "Give a heartfelt toast to a random object in the room like it's your best friend.",
    ],
  },
  GameMode.spicy: {
    PromptType.truth: [
      "What's the most embarrassing thing that's happened to you on a date?",
      "Who in this room would you most like to be stuck in a lift with?",
      "What's the flirtiest message you've ever sent?",
      "Have you ever had a crush on a friend's partner?",
      "What's your most awkward walk-of-shame story?",
      "What's the biggest turn-off you can't ignore?",
      "Have you ever sent a flirty text to the wrong person?",
      "What's the most daring place you've ever kissed someone?",
      "What's the longest you've gone without a kiss, and how did it feel?",
      "Who here do you think is the best kisser?",
      "What small thing instantly makes someone more attractive to you?",
      "Have you ever stayed in a situationship way too long?",
      "What's the worst pick-up line that ever actually worked on you?",
      "Have you ever pretended to be busy to dodge a date?",
      "What's the most regrettable crush you've ever had?",
      "Have you ever been friend-zoned, or friend-zoned someone?",
      "What's the most scandalous rumour you've heard about yourself?",
      "Have you ever dated two people at once?",
      "What's the first thing you notice about someone you fancy?",
      "Have you ever gone back to an ex? Was it worth it?",
      "What's your wildest first-date story?",
      "Who here would you swipe right on?",
      "What's the cheekiest thing you've done to get someone's attention?",
      "Have you ever left someone on read because you were too nervous to reply?",
      "What's the boldest thing you've done to spice up a relationship?",
    ],
    PromptType.dare: [
      "Whisper the most flirtatious line you can think of to the person on your left.",
      "Send a flirty emoji to the last person you texted.",
      "Give someone in the group a 20-second shoulder massage, if they're up for it.",
      "Do a sultry reading of the back of a cereal box.",
      "Deliver your best pick-up line to a player of your choice.",
      "Do a slow, sultry dance for 15 seconds.",
      "Describe your ideal date as dramatically as possible.",
      "Give the person across from you your best bedroom eyes for 20 seconds without laughing.",
      "Close your eyes and guess who's next to you by touching only their hand.",
      "Let someone feed you a snack, rom-com style.",
      "Write a flirty one-liner for each player in the group.",
      "Hold eye contact with the person on your right for 30 seconds.",
      "Compliment every player in the room with a flirty twist.",
      "Take a selfie with the person on your left and let the group write the caption.",
      "Build the sexiest outfit you can from items in the room in 60 seconds, then strut.",
      "Say your best chat-up line in a Barry White voice.",
      "Give a cheek kiss to someone in the group, but only if they agree.",
      "Act out your most dramatic breakup scene.",
      "Play Marry, Kiss, Avoid with three players the group names.",
      "Do a seductive impression of a famous movie character.",
      "Send a voice note to a friend saying only 'I've got a secret' in your sultriest voice.",
      "Describe the person on your right using only romantic movie titles.",
      "Slow-dance with a pillow like it's prom night.",
      "Share your best pick-up line, then let the group rate it from 1 to 10.",
      "Swap jackets or jumpers with someone and sweet-talk them.",
    ],
  },
  GameMode.afterHours: {
    PromptType.truth: [
      "What's the worst decision you've ever made after 2am?",
      "What's the most unhinged text you've sent at 3am?",
      "What's the biggest secret you've kept from everyone in this room?",
      "Who here do you think has the wildest hidden side?",
      "What's the closest you've come to getting arrested, fined, or banned?",
      "Have you ever woken up with zero memory of how you got home?",
      "What's the most shameful thing on your phone right now?",
      "Who here would you least want scrolling through your camera roll?",
      "What's the most regrettable thing you've ever done for a dare?",
      "Have you ever lied about where you were to cover up a wild night?",
      "What's the most cringe thing a friend has caught you doing?",
      "If you could erase one night from your life, which would it be?",
      "What's a rule you swore you'd never break, and then absolutely did?",
      "Who here is most likely to end up in a viral video, and why?",
      "What's the pettiest revenge you've ever taken?",
      "What's the most awkward excuse you've used to escape a bad date?",
      "What's the strangest place you've ever fallen asleep at a party?",
      "Have you ever been banned from a bar, a group chat, or a family event?",
      "What's the worst thing you've said about someone that got back to them?",
      "What's the most chaotic thing you've done on holiday?",
      "Which friend here would you call at 4am to bail you out?",
      "What's the most embarrassing nickname you got after a night out?",
      "What's one thing you'd confess right now if you knew nobody would judge you?",
      "What's the most reckless purchase you've made at midnight?",
      "What's the biggest 'never again' promise you broke within a week?",
    ],
    PromptType.dare: [
      "Read your last three search terms out loud in a dramatic movie-trailer voice.",
      "Post 'I have an announcement' to your story and leave it up for five minutes without explaining.",
      "Send a friend 'I just had the weirdest dream about you' and show the group their reply.",
      "Do your most unhinged 3am dance for 20 seconds.",
      "Give a passionate eulogy for your phone battery.",
      "Order an imaginary pizza from thin air in an accent the group picks.",
      "Say the alphabet backwards in under 20 seconds, or do ten star jumps.",
      "Take a selfie from the worst possible angle and make it your lock screen for 10 minutes.",
      "Dance to three songs the group picks, like nobody is watching.",
      "Call a friend and swear you've secretly been a mime for years.",
      "Wear your jumper or hoodie backwards for the rest of the game.",
      "Impersonate the most dramatic person you know until someone guesses who.",
      "Let the group rename you in a group chat for an hour.",
      "Stand on a chair and give a motivational speech about snacks.",
      "Let the group give you a silly new name and stay in character for three turns.",
      "Make a red-carpet entrance as a famous celebrity.",
      "Send a voice note singing 'Happy Anniversary' to a mate.",
      "Defend your most unpopular opinion for 30 seconds against the whole group.",
      "Text your next three messages using only one emoji chosen by the group.",
      "Invent a conspiracy theory about the person on your right and present it seriously.",
      "Give a reality-TV confessional about how this game is going.",
      "Sing everything you say until your next turn.",
      "Read your last sent text like a Shakespearean monologue.",
      "Swap shoes with someone and strut around the room like it's a catwalk.",
      "Let the group draw a temporary tattoo on your arm with a washable marker.",
      "Stare at someone and deliver 'it's not you, it's me' with a straight face.",
      "Post a throwback photo you hate with the caption 'peak performance'.",
      "Fake a phone call and make the most over-the-top escape from the room.",
      "Give a 30-second TED Talk on pineapple on pizza.",
      "Talk in the third person until your next turn.",
      "Have a staring contest with someone. The loser does 10 squats.",
      "Hand every player a made-up job title and explain their daily duties.",
      "Attempt the moonwalk across the room and back.",
      "Perform an interpretive dance about your last relationship.",
      "Add 'no cap' to the end of every sentence until your next turn.",
      "Plan a ridiculous heist out loud and assign everyone a role.",
      "Deliver a villain monologue about why you ran out of snacks.",
      "Do a dramatic slow-motion replay of the last time you tripped.",
      "Say a famous movie quote as if you're sobbing.",
      "Pretend to be a flight attendant and give safety instructions for this room.",
    ],
  },
  GameMode.couples: {
    PromptType.truth: [
      "What's your favourite memory of the two of you?",
      "What was your first impression of the other person?",
      "What's one thing they do that instantly melts you?",
      "What's the most romantic thing you've ever done for someone?",
      "What's a tiny habit of theirs that secretly drives you mad?",
      "When did you first realise you liked them?",
      "What song instantly reminds you of them?",
      "What's your dream date night, with no budget?",
      "What's one thing you've never told them but want to?",
      "Which rom-com couple are the two of you most like?",
      "What's the best compliment you've ever had from them?",
      "What do you think they'd say is your most annoying habit?",
      "What's your love language: words, touch, gifts, time, or acts of service?",
      "What's the most embarrassing thing you did to impress them early on?",
      "Where would you take them on a surprise weekend away?",
      "What's one thing you'd like to try together this year?",
      "What's the cheesiest nickname you'd secretly love?",
      "What's the most memorable kiss you've ever had?",
      "What was something you were nervous to tell them, but glad you did?",
      "What would they order for your last meal together?",
      "What's a guilty pleasure you hide from them?",
      "What do you admire most about how they treat other people?",
      "If your story were a TV series, what would it be called?",
      "What's the most spontaneous thing you'd do for them?",
      "What's one thing that makes you feel closest to them?",
    ],
    PromptType.dare: [
      "Give the other person a 30-second hand massage.",
      "Slow-dance for one full song with no phones.",
      "Whisper your favourite memory of the two of you.",
      "Write a four-line love poem in under a minute and read it out.",
      "Recreate the pose from your first-ever photo together.",
      "Feed each other a bite of a snack with your eyes closed.",
      "Take turns giving compliments until one of you runs out.",
      "Hold hands and stare into each other's eyes for 30 seconds without laughing.",
      "Draw each other in 60 seconds using your non-dominant hand.",
      "Act out your first date in 30 seconds.",
      "Give each other a couple nickname and use it for the rest of the game.",
      "Say 'you're the best' in three different accents.",
      "Invent a signature handshake and perform it.",
      "Send each other something sweet by text, then read the replies aloud.",
      "Take a cute selfie together and make it your wallpaper for the night.",
      "Give a serious 20-second wedding-style toast about the other person.",
      "Name three things you love about their personality.",
      "Swap seats and mimic how the other person talks for 30 seconds.",
      "Close your eyes and let them guide you around the room by the hand.",
      "Plan your perfect Sunday together out loud in 60 seconds.",
      "Sing a love song to them, even badly.",
      "Give them a forehead kiss, if they're happy with that.",
      "Invent a secret signal that means 'let's leave this party'.",
      "Narrate the next minute of your relationship like a nature documentary.",
      "Pick the song that could be 'your song' and play it.",
      "Finish the sentence 'I feel most loved when...' three times each.",
      "Wear each other's jumpers or jackets for the next three rounds.",
      "Pose for a film-poster photo of your love story.",
      "Share a 15-second hug without saying a word.",
      "Describe the other person like a dating-app profile.",
      "Make a pinky promise about something fun you'll do together.",
      "Name three things you want to do together before the year ends.",
      "Do an impression of the two of you arguing about where to eat.",
      "Give them a 'Best Partner' award with a full acceptance speech.",
      "Make a heart shape with your arms together and hold it for 20 seconds.",
      "Re-enact the moment you first held hands.",
      "Share an inside joke with the group and explain it.",
      "Write each other a one-sentence love note on paper and swap.",
      "Hold a couples yoga pose together for 20 seconds.",
      "Plan a surprise for them out loud, then promise to make it happen.",
    ],
  },
  GameMode.exposed: {
    PromptType.truth: [
      "Whose message have you screenshotted and sent to someone else?",
      "What's the biggest piece of gossip you've ever spread?",
      "Who in this room has annoyed you the most this year?",
      "What's the juiciest rumour you've heard about someone here?",
      "Have you ever made a fake account to snoop on someone?",
      "Who's the most two-faced person you know?",
      "What's the pettiest thing you've done to a friend?",
      "Who here would you least want to share a flat with?",
      "Which friend do you secretly find the most exhausting?",
      "Have you ever read someone's messages without them knowing?",
      "What's the biggest lie someone told you that you only just found out?",
      "What's something about yourself you hope no one ever finds out?",
      "Who in your circle is the biggest drama magnet?",
      "What's the real reason you fell out with a past close friend?",
      "Have you ever faked being ill to skip someone's event?",
      "Who here would be the first to leak a secret?",
      "What's your most controversial opinion about someone in this room?",
      "What's the harshest thing you've ever thought about someone's outfit?",
      "Which couple in your friend group do you think won't last?",
      "Have you ever taken credit for someone else's idea?",
      "What's the most scandalous thing you know that you swore to keep quiet?",
      "Who here posts the most staged-looking photos?",
      "Which celebrity scandal did you take way too personally?",
      "What's the worst advice you've ever knowingly given someone?",
      "If you had to expose one secret about yourself, what would it be?",
    ],
    PromptType.dare: [
      "Show the group the last screenshot in your camera roll.",
      "Read out the last text you sent to your best friend.",
      "Reveal your most-played song this month and defend it.",
      "Give every player a one-word honest description.",
      "Rate every player's Instagram feed out of 10, kindly.",
      "Say the first thing that pops into your head about each player, no filter.",
      "Show the weirdest photo in your Favourites album.",
      "Reveal your screen time for the week.",
      "Report a fake celebrity scandal like a breaking-news anchor.",
      "Impersonate the group's biggest gossip until someone guesses who.",
      "Tell your most embarrassing story in 30 seconds.",
      "Read your last three notifications out loud, skipping anything truly private.",
      "Show the group your most embarrassing playlist.",
      "Describe the type of person you've muted the most online.",
      "Tell the group one true thing about yourself that sounds completely fake.",
      "Post a story poll: 'Who's the messiest in this group?' Don't name anyone.",
      "Guess the most-used app on each player's phone, then reveal.",
      "Read your oldest Notes entry out loud.",
      "Open your unread messages and read the oldest one aloud.",
      "Spill a secret or do 15 squats. Your choice.",
      "Spill the tea about a celebrity you secretly can't stand, or do 10 star jumps.",
      "Reveal your top three most-used emojis and what they say about you.",
      "Tell the group about your most ridiculous online shopping regret.",
      "Reveal your most common food-delivery order and how often you get it.",
      "Spill one harmless secret about a past job.",
      "Name your biggest red flag, then let the group vote on it.",
      "Name a group-chat habit of yours that annoys everyone.",
      "Let the group pick one app on your phone for you to open and show.",
      "Say with a straight face which friend you'd trade for a lifetime supply of pizza.",
      "Reveal an unsent draft message, if you have one.",
      "Let the group ask you one yes-or-no question about your love life.",
      "Give an honest first impression of each player.",
      "Rank the players from most to least likely to cancel plans last minute.",
      "Rank the players from most to least likely to start drama.",
      "Share the most ridiculous lie you told at school or work.",
      "Do your best gossip voice and spill something harmless about yourself.",
      "Reveal your most-liked post and admit why you posted it.",
      "Show the group the oldest photo on your phone.",
      "Tell the group about a time you were the villain in someone's story.",
      "Invent a 'Most Likely To' award for each player.",
    ],
  },
};
