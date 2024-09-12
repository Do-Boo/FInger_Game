import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const FingerGameApp());
}

class FingerGameApp extends StatelessWidget {
  const FingerGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    return MaterialApp(
      title: 'Finger Game',
      theme: ThemeData(fontFamily: 'Roboto'),
      home: const FingerGameScreen(),
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
  List<TouchInfo> _touches = [];
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
      _touches = [];
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

  void _onTouch(TapDownDetails details) {
    if (_gameStarted && !_gameEnded && _countdown == 0) {
      setState(() {
        _touches.add(TouchInfo(details.localPosition, _rainbowColors[_colorIndex], _colorIndex));
        _colorIndex = (_colorIndex + 1) % _rainbowColors.length;

        if (_touches.length == 1) {
          _startTimer();
        }
      });
    }
  }

  void _startTimer() {
    _timer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _gameEnded = true;
      });
      _animationController.reverse();
    });
  }

  String _getResult(AppLocalizations localizations) {
    if (_touches.isEmpty) return localizations.noTouch;
    return localizations.lastTouchedColor(_touches.last.colorIndex);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      body: GestureDetector(
        onTapDown: _onTouch,
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
              ..._touches.map(
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
      'lastTouchedRed': '마지막으로 빨강색을 터치한 사람이 범인입니다!',
      'lastTouchedOrange': '마지막으로 주황색을 터치한 사람이 범인입니다!',
      'lastTouchedYellow': '마지막으로 노랑색을 터치한 사람이 범인입니다!',
      'lastTouchedGreen': '마지막으로 초록색을 터치한 사람이 범인입니다!',
      'lastTouchedBlue': '마지막으로 파랑색을 터치한 사람이 범인입니다!',
      'lastTouchedIndigo': '마지막으로 남색을 터치한 사람이 범인입니다!',
      'lastTouchedPurple': '마지막으로 보라색을 터치한 사람이 범인입니다!',
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
