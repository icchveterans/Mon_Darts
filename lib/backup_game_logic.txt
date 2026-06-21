import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DartGame {
  List<int> p1History = List<int>.from([501]);
  List<int> p2History = List<int>.from([501]);
  List<int> p1Turns = [];
  List<int> p2Turns = [];

  bool isPlayer1Turn = true;
  String currentInput = "";

  String player1Name = "БУЖГАА";
  String player2Name = "ЧӨДӨРӨӨ";

  int player1Legs = 0;
  int player2Legs = 0;
  int targetLegs = 3; 
  int startScore = 501;

  bool isVsAI = false;
  String aiLevel = "ДУНД"; 

  // ШИНЭ: Өгөгдлийн санд хадгалагдах түүхэн үзүүлэлтүүд
  int p1TotalMatchWins = 0;
  int p2TotalMatchWins = 0;
  double p1BestAverage = 0.0;
  double p2BestAverage = 0.0;

  final AudioPlayer _audioPlayer = AudioPlayer();

  DartGame() {
    loadSavedStats(); // Класс үүсэхэд хуучин статуудыг санах ойгоос ачаална
  }

  int get player1Score => p1History.last;
  int get player2Score => p2History.last;
  // Гурван дартсын дундаж оноог бодох функц (3-Dart Average)
  double getAverage(bool isP1) {
    List<int> turns = isP1 ? p1Turns : p2Turns;
    if (turns.isEmpty) return 0.0;
    int total = turns.reduce((a, b) => a + b);
    return double.parse((total / turns.length).toStringAsFixed(1));
  }
   // Өндөр онооны тоог гаргах функц (100+ болон 140+)
  int getHighCount(bool isP1, int benchmark) {
    List<int> turns = isP1 ? p1Turns : p2Turns;
    if (benchmark == 100) {
      return turns.where((score) => score >= 100 && score < 140).length;
    } else if (benchmark == 140) {
      return turns.where((score) => score >= 140).length;
    }
    return 0;
  }

  // Санах ойгоос стат унших зөв функц
  Future<void> loadSavedStats() async {
    final prefs = await SharedPreferences.getInstance();
    p1TotalMatchWins = prefs.getInt('p1_wins') ?? 0;
    p2TotalMatchWins = prefs.getInt('p2_wins') ?? 0;
    p1BestAverage = prefs.getDouble('p1_best_avg') ?? 0.0;
    p2BestAverage = prefs.getDouble('p2_best_avg') ?? 0.0;
  }

  // Тэмцээн дуусахад стат хадгалах зөв функц
  Future<void> saveMatchStats(bool isP1Winner) async {
    final prefs = await SharedPreferences.getInstance();
    if (isP1Winner) {
      p1TotalMatchWins++;
      await prefs.setInt('p1_wins', p1TotalMatchWins);
    } else {
      p2TotalMatchWins++;
      await prefs.setInt('p2_wins', p2TotalMatchWins);
    }

    double p1CurrentAvg = getAverage(true);
    double p2CurrentAvg = getAverage(false);

    if (p1CurrentAvg > p1BestAverage) {
      p1BestAverage = p1CurrentAvg;
      await prefs.setDouble('p1_best_avg', p1BestAverage);
    }
    if (p2CurrentAvg > p2BestAverage) {
      p2BestAverage = p2CurrentAvg;
      await prefs.setDouble('p2_best_avg', p2BestAverage);
    }
  }

  final Map<int, String> checkoutMap = {
    170: "T20, T20, Bull", 167: "T20, T19, Bull", 164: "T20, T18, Bull",
    161: "T20, T17, Bull", 160: "T20, T20, D20",  158: "T20, T20, D19",
    157: "T20, T19, D20",  156: "T20, T20, D18",  155: "T20, T19, D19",
    154: "T20, T18, D20",  153: "T20, T19, D18",  152: "T20, T20, D16",
    151: "T20, T17, D20",  150: "T20, T18, D18",  149: "T20, T19, D16",
    148: "T20, T16, D20",  147: "T20, T17, D18",  146: "T20, T18, D16",
    145: "T20, T15, D20",  144: "T20, T20, D12",  143: "T20, T17, D16",
    142: "T20, T14, D20",  141: "T20, T15, D18",  140: "T20, T16, D12",
    139: "T19, T14, D20",  138: "T20, T18, D12",  137: "T19, T16, D16",
    136: "T20, T20, D8",   135: "T20, T15, D15",  134: "T20, T14, D16",
    133: "T20, T17, D6",   132: "T20, T16, D12",  131: "T20, T13, D16",
    130: "T20, T20, D5",   129: "T19, T16, D12",  128: "T18, T14, D16",
    127: "T20, T17, D8",   126: "T19, T19, D6",   125: "T18, T13, D16",
    124: "T20, D16, D16",  123: "T19, T16, D8",   122: "T18, T16, D10",
    121: "T20, T15, D8",   120: "T20, 20, D20",   119: "T19, 12, D25",
    118: "T20, 18, D20",   117: "T20, 17, D20",   116: "T20, 16, D20",
    115: "T20, 15, D20",   114: "T20, 14, D20",   113: "T19, 16, D20",
    112: "T20, 12, D20",   111: "T20, 11, D20",   110: "T20, 10, D20",
    109: "T19, 12, D20",   108: "T19, 11, D20",   107: "T19, 10, D20",
    106: "T20, 10, D18",   105: "T19, 12, D16",   104: "T18, 10, D20",
    103: "T19, 10, D16",   102: "T20, 10, D16",   101: "T17, 10, D25",
    100: "T20, D20",       99: "T19, 10, D16",    98: "T20, D19",
    97: "T19, D20",        96: "T20, D18",        95: "T19, D19",
    94: "T18, D20",        93: "T19, D18",        92: "T20, D16",
    91: "T17, D20",        90: "T20, D15",        89: "T19, D16",
    88: "T16, D20",        87: "T17, D17",        86: "T18, D16",
    85: "T15, D20",        84: "T20, D12",        83: "T17, D16",
    82: "T14, D20",        81: "T15, D18",        80: "T20, D10",
    79: "T13, D20",        78: "T18, D12",        77: "T15, D16",
    76: "T20, D8",         75: "T17, D12",        74: "T14, D16",
    73: "T19, D8",         72: "T16, D12",        71: "T13, D16",
    70: "T10, D20",        69: "T15, D12",        68: "T16, D10",
    67: "T17, D8",         66: "T14, D12",        65: "T15, D10",
    64: "T16, D8",         63: "T13, D12",
    62: "T10, D16",        61: "T15, D8",         60: "20, D20",
    59: "19, D20",         58: "18, D20",         57: "17, D20",
    56: "16, D20",         55: "15, D20",         54: "14, D20",
    53: "13, D20",         52: "12, D20",         51: "11, D20",
    50: "10, D20",         49: "9, D20",          48: "8, D20",
    47: "7, D20",          46: "6, D20",          45: "5, D20",
    44: "4, D20",          43: "3, D20",          42: "2, D20",
    41: "1, D20",          40: "D20",             38: "D19",
    36: "D18",             34: "D17",             32: "D16",
    30: "D15",             28: "D14",             26: "D13",
    24: "D12",             22: "D11",             20: "D10",
    18: "D9",              16: "D8",              14: "D7",
    12: "D6",              10: "D5",              8: "D4",
    6: "D3",               4: "D2",               2: "D1",
  };

  String getCheckoutGuide(bool isPlayer1) {
    int score = isPlayer1 ? player1Score : player2Score;
    if (score <= 170 && checkoutMap.containsKey(score)) {
      return checkoutMap[score]!;
    }
    return "";
  }

  void addDigit(String digit) {
    if (currentInput.length < 3) { 
      currentInput += digit;
    }
  }

  void deleteDigit() {
    if (currentInput.isNotEmpty) {
      currentInput = currentInput.substring(0, currentInput.length - 1);
    }
  }

  void _playAudio(String fileName) async {
    try {
      await _audioPlayer.play(AssetSource('audio/$fileName'));
    } catch (e) {
      print("Дуу тоглуулахад алдаа гарлаа: $e");
    }
  }

    String submitScore() {
    if (currentInput.isEmpty) return 'invalid';
    int score = int.parse(currentInput);
    currentInput = ""; 
    if (score > 180) return 'invalid'; 

    // Хэн шидэж байгааг тооцож оноо хасах үндсэн логик
    String result;
    if (isPlayer1Turn) {
      result = _processScore(p1History, p1Turns, score, true);
    } else {
      result = _processScore(p2History, p2Turns, score, false);
    }

    // Хэрэв робот горим идэвхтэй бөгөөд роботын ээлж ирсэн бол
    if (isVsAI && !isPlayer1Turn && result == 'success') {
      return 'ai_thinking';
    }

    return result;
  }
  // Робот өөрийн түвшинд тааруулж оноо үүсгэх алгоритм
  String generateAIScore() {
    final random = Random();
    int score = 0;
    int currentAIScore = p2History.last;

    if (currentAIScore <= 60) {
      // Хаалтын үе шат: Түвшингээс шалтгаалж хаах магадлал
      int chance = aiLevel == "ХЯЛБАР" ? 15 : (aiLevel == "ДУНД" ? 35 : 65);
      if (random.nextInt(100) < chance && currentAIScore % 2 == 0) {
        score = currentAIScore; // Яг хаалаа
      } else {
        score = random.nextInt(min(currentAIScore, 20)) + 1;
      }
    } else {
      // Хэвийн үе шат: Түвшин бүрийн дундаж онооны муж
      if (aiLevel == "ХЯЛБАР") {
        score = random.nextInt(35) + 10; // 10-45 оноо
      } else if (aiLevel == "ДУНД") {
        score = random.nextInt(45) + 30; // 30-75 оноо
      } else {
        score = random.nextInt(60) + 60; // 60-120 оноо
      }
    }

    return _processScore(p2History, p2Turns, score, false);
  }

  String _processScore(List<int> history, List<int> turns, int score, bool isP1) {
    int current = history.last;
    int nextScore = current - score;

    if (nextScore == 0) {
      turns.add(score); 
      _playAudio('success.mp3');
      if (isP1) {
        player1Legs++;
        if (player1Legs >= targetLegs) {
          saveMatchStats(true); // ШИНЭ: Бужгаа тэмцээнд хожвол өгөгдлийг хадгална
          return 'match_win';
        }
      } else {
        player2Legs++;
        if (player2Legs >= targetLegs) {
          saveMatchStats(false); // ШИНЭ: Робот тэмцээнд хожвол өгөгдлийг хадгална
          return 'match_win';
        }
      }
      _startNewLeg();
      return 'leg_win'; 
    } else if (nextScore < 0 || nextScore == 1) {
      history.add(current); 
      turns.add(0); 
      isPlayer1Turn = !isPlayer1Turn;
      _playAudio('bust.mp3');
      return 'bust';
    } else {
      history.add(nextScore);
      turns.add(score); 
      isPlayer1Turn = !isPlayer1Turn;
      _playAudio('success.mp3');
      return 'success';
    }
  }

  void _startNewLeg() {
    p1History = List<int>.from([startScore]);
    p2History = List<int>.from([startScore]);
    isPlayer1Turn = (player1Legs + player2Legs) % 2 == 0; 
  }

  void undoLastMove() {
    if (p1History.length <= 1 && p2History.length <= 1) return;
    isPlayer1Turn = !isPlayer1Turn; 
    if (isPlayer1Turn) {
      if (p1History.length > 1) p1History.removeLast();
      if (p1Turns.isNotEmpty) p1Turns.removeLast();
    } else {
      if (p2History.length > 1) p2History.removeLast();
      if (p2Turns.isNotEmpty) p2Turns.removeLast();
    }
  }

  void resetFullMatch() {
    p1History = List<int>.from([startScore]);
    p2History = List<int>.from([startScore]);
    p1Turns.clear();
    p2Turns.clear();
    player1Legs = 0;
    player2Legs = 0;
    isPlayer1Turn = true;
    currentInput = "";
    if (isVsAI) player2Name = "РОБОТ ($aiLevel)";
    loadSavedStats(); // Шинэ тоглолт эхлэхэд түүхэн өгөгдлийг дахин шинэчилнэ
  }
}
