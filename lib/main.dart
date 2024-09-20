import 'dart:async';
import 'dart:math';
import 'package:Finger_Game/splash.dart';
import 'package:Finger_Game/widgets/w_banner_ads.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  FlutterNativeSplash.remove();
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(MobileAds.instance.initialize());
  runApp(const FingerGameApp());
}

class FingerGameApp extends StatelessWidget {
  const FingerGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finger Game',
      theme: ThemeData(fontFamily: 'Roboto'),
      home: const SplashScreen(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ko', ''),
      ],
    );
  }
}

class FingerGameScreen extends StatefulWidget {
  const FingerGameScreen({super.key});

  @override
  _FingerGameScreenState createState() => _FingerGameScreenState();
}

class _FingerGameScreenState extends State<FingerGameScreen> with SingleTickerProviderStateMixin {
  bool _gameStarted = false;
  bool _gameEnded = false;
  final Map<int, TouchInfo> _touches = {};
  Timer? _timer;
  int _colorIndex = 0;
  int _countdown = 3;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<Color> _rainbowColors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
  ];

  final Color _initialColor = Colors.grey;
  bool _timerStarted = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _gameEnded = false;
      _touches.clear();
      _colorIndex = 0;
      _countdown = 3;
    });
    _startCountdown();
  }

  void _startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          timer.cancel();
          _animationController.forward();
        }
      });
    });
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_gameStarted && !_gameEnded && _countdown == 0) {
      setState(() {
        if (!_touches.containsKey(event.pointer)) {
          _touches[event.pointer] = TouchInfo(event.position, _initialColor, -1);
          if (!_timerStarted) {
            _startTimer();
            _timerStarted = true;
          }
        }
      });
    }
  }

  // _onPointerUp 메서드 제거

  void _startTimer() {
    _timer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _gameEnded = true;
        final randomColorIndices = List.generate(_rainbowColors.length, (index) => index)..shuffle();
        _touches.forEach((key, value) {
          final randomColorIndex = randomColorIndices[key % _rainbowColors.length];
          _touches[key] = TouchInfo(value.position, _rainbowColors[randomColorIndex], randomColorIndex);
        });
      });
      _animationController.reverse();
    });
  }

  String _getResult(AppLocalizations localizations) {
    if (_touches.isEmpty) return localizations.noTouch;
    final lastTouch = _touches.values.last;
    return localizations.lastTouchedColor(lastTouch.colorIndex);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Listener(
      onPointerDown: _onPointerDown,
      // onPointerUp 리스너 제거
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue[100]!, Colors.purple[100]!],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ..._touches.values.map(
                      (touch) => Positioned(
                        left: touch.position.dx - 25,
                        top: touch.position.dy - 25,
                        child: TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, double value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: touch.color.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 5,
                                      offset: Offset(2, 2),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          if (_countdown > 0)
                            Text(
                              '$_countdown',
                              style: TextStyle(
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4.0,
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                            )
                          else if (_gameStarted && !_gameEnded)
                            FadeTransition(
                              opacity: _animation,
                              child: Text(
                                localizations.touchNow,
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4.0,
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(2, 2),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (_gameEnded)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                _getResult(localizations),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4.0,
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(2, 2),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 40),
                          if (!_gameStarted || _gameEnded)
                            ElevatedButton(
                              onPressed: _startGame,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.deepPurple[600],
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(localizations.startGame, style: const TextStyle(fontSize: 18)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            BannerAdWidget(adSize: AdSize.banner),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }
}

class TouchInfo {
  final Offset position;
  final Color color;
  final int colorIndex;

  TouchInfo(this.position, this.color, this.colorIndex);
}

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'touchNow': 'Touch now!',
      'startGame': 'Start Game',
      'noTouch': 'No one touched!',
      'lastTouchedRed': 'The last touched Red!',
      'lastTouchedOrange': 'The last touched Orange!',
      'lastTouchedYellow': 'The last touched Yellow!',
      'lastTouchedGreen': 'The last touched Green!',
      'lastTouchedBlue': 'The last touched Blue!',
      'lastTouchedIndigo': 'The last touched Indigo!',
      'lastTouchedPurple': 'The last touched Purple!',
    },
    'ko': {
      'touchNow': '터치하세요!',
      'startGame': '게임 시작',
      'noTouch': '아무도 터치하지 않았습니다!',
      'lastTouchedRed': '빨강색 술래입니다!',
      'lastTouchedOrange': '주황색을 술래입니다!',
      'lastTouchedYellow': '노랑색을 술래입니다!',
      'lastTouchedGreen': '초록색을 술래입니다!',
      'lastTouchedBlue': '파랑색을 술래입니다!',
      'lastTouchedIndigo': '남색을 술래입니다!',
      'lastTouchedPurple': '보라색을 술래입니다!',
    },
  };

  String get touchNow => _localizedValues[locale.languageCode]!['touchNow']!;
  String get startGame => _localizedValues[locale.languageCode]!['startGame']!;
  String get noTouch => _localizedValues[locale.languageCode]!['noTouch']!;

  String lastTouchedColor(int colorIndex) {
    final colorKeys = ['Red', 'Orange', 'Yellow', 'Green', 'Blue', 'Indigo', 'Purple'];
    return _localizedValues[locale.languageCode]!['lastTouched${colorKeys[colorIndex]}']!;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ko'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
