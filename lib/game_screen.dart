import 'package:flutter/material.dart';
import 'game_logic.dart';
import 'dart:ui';
import 'package:flutter_tts/flutter_tts.dart';

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final DartsCaller _caller = DartsCaller();
  DartGame game = DartGame();

  @override
  void initState() {
    super.initState();
    // Асинхрон өгөгдлийг уншиж дуусаад дэлгэцийг заавал шинэчилнэ
    game.loadSavedStats().then((_) {
      if (mounted) setState(() {});
    });
  }


  void _showEditNamesDialog() {
    TextEditingController p1Ctrl = TextEditingController(text: game.player1Name);
    TextEditingController p2Ctrl = TextEditingController(text: game.player2Name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey,
        title: const Text('Тоглогчдын нэр засах', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: p1Ctrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Тоглогч 1 нэр', labelStyle: TextStyle(color: Colors.green)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: p2Ctrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Тоглогч 2 нэр', labelStyle: TextStyle(color: Colors.green)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Цуцлах', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (p1Ctrl.text.isNotEmpty) game.player1Name = p1Ctrl.text.toUpperCase();
                if (p2Ctrl.text.isNotEmpty) game.player2Name = p2Ctrl.text.toUpperCase();
                game.isVsAI = false; 
              });
              Navigator.pop(context);
            },
            child: const Text('Хадгалах', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showMatchOverDialog(String winner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey,
        title: const Text('ТЭМЦЭЭН ДУУСЛАА! 🏆', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
        content: Text('$winner тэмцээний АВАРГА боллоо!', style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                game.resetFullMatch();
              });
            },
            child: const Text('Шинэ тэмцээн эхлүүлэх', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _triggerAIPlay() async {
    await Future.delayed(const Duration(milliseconds: 1200)); 
    if (!mounted) return;
    
    String aiResult = game.generateAIScore();
    setState(() {});

    _parseResult(aiResult, false);
  }

   void _parseResult(String result, bool isP1) {
    if (result == 'match_win') {
      String winner = isP1 ? game.player1Name : game.player2Name;
      _showMatchOverDialog(winner);
    } else if (result == 'leg_win') {
      String legWinner = isP1 ? game.player1Name : game.player2Name;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$legWinner үеийг авлаа! 🎯'), 
          backgroundColor: const Color(0xFF2E3440).withOpacity(0.9), // backgroundColor: гэж зааж өгөв
        ),
      );
      if (game.isVsAI && !game.isPlayer1Turn) _triggerAIPlay();
    } else if (result == 'bust') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar( // const түлхүүр үгийг эндээс устгасан
          content: const Text('Bust! Оноо хэтэрлээ 🎯'), // const-ийг зөвхөн Text рүү шилжүүлэв
          backgroundColor: Colors.redAccent.withOpacity(0.9), // backgroundColor: гэж зааж өгөв
          duration: const Duration(seconds: 2),
        ),
      );
      if (game.isVsAI && !game.isPlayer1Turn) _triggerAIPlay();
    } else if (result == 'success') {
      if (game.isVsAI && !game.isPlayer1Turn) _triggerAIPlay();
    }
  }

  void _handleScoreSubmit() {
    // Оноо хасагдахаас ӨМНӨ хэний ээлж байсныг хадгалж авна
    bool wasPlayer1Turn = game.isPlayer1Turn;
    
    String result = game.submitScore();
    setState(() {}); // Оноо хасагдсаныг дэлгэцэнд шууд харуулна

    if (result == 'invalid') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Алдаатай оноо! (0-180)'), backgroundColor: Colors.amber, duration: Duration(seconds: 2)),
      );
      return;
    }

    // ШИНЭ ТУШААЛ: Үр дүнг хүйс харгалзахгүй (Тоглогч 1 эсвэл 2) зөв уншина
    _parseResult(result, wasPlayer1Turn);
    if (result == 'ai_thinking') _triggerAIPlay();
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E6), 
      appBar: AppBar(
        title: const Text("МОНГОЛ ДАРТС", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 18)),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.smart_toy, color: Colors.white, size: 26),
            onSelected: (String level) {
              setState(() {
                game.isVsAI = true;
                game.aiLevel = level;
                game.player2Name = "РОБОТ ($level)";
                game.resetFullMatch();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "ХЯЛБАР", child: Text("🤖 Робот: Хялбар")),
              const PopupMenuItem(value: "ДУНД", child: Text("🤖 Робот: Medium")),
              const PopupMenuItem(value: "МЭРГЭЖЛИЙН", child: Text("🤖 Робот: Про")),
            ],
          ),
          PopupMenuButton<int>(
            icon: const Icon(Icons.videogame_asset, color: Colors.white, size: 26),
            onSelected: (int score) {
              setState(() {
                game.startScore = score;
                game.resetFullMatch(); 
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 301, child: Text("301 Горим")),
              const PopupMenuItem(value: 501, child: Text("501 Горим")),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.white, size: 28),
            onPressed: _showEditNamesDialog, 
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() => game.resetFullMatch()), 
          )
        ],
      ),
      // БОЛОР ЭФФЕКТИЙГ ИДЭВХЖҮҮЛЭХ АРЫН УУСГАЛТТАЙ КОНТЕЙНЕР
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF04471C), // Дээд хэсэг - үл ялиг цайвар хөх саарал туяа
              Color(0xFF181F56), // Доод хэсэг - гүн харанхуй өнгө
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 15),
                Text(
                  "ГОРИМ: ${game.startScore} — ТЭМЦЭЭН (${game.targetLegs} ХОЖИХ)",
                  style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPlayerCard(
                      game.player1Name, 
                      game.player1Score, 
                      game.isPlayer1Turn, 
                      game.getCheckoutGuide(true), 
                      game.player1Legs, 
                      game.getAverage(true), 
                      game.getHighCount(true, 100), 
                      game.getHighCount(true, 140),
                      game.p1TotalMatchWins,
                      game.p1BestAverage
                    ),
                    _buildPlayerCard(
                      game.player2Name, 
                      game.player2Score, 
                      !game.isPlayer1Turn, 
                      game.getCheckoutGuide(false), 
                      game.player2Legs, 
                      game.getAverage(false), 
                      game.getHighCount(false, 100), 
                      game.getHighCount(false, 140),
                      game.p2TotalMatchWins,
                      game.p2BestAverage
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  height: 50,
                  alignment: Alignment.center,
                  child: Text(
                    game.currentInput.isEmpty && !game.isPlayer1Turn && game.isVsAI ? "РОБОТ БОДОЖ БАЙНА..." : (game.currentInput.isEmpty ? "ОНОО ОРУУЛНА УУ" : game.currentInput),
                    style: TextStyle(
                      fontSize: game.currentInput.isEmpty ? 18 : 36, 
                      fontWeight: FontWeight.bold, 
                      color: !game.isPlayer1Turn && game.isVsAI ? Colors.green : (game.currentInput.isEmpty ? Colors.grey : Colors.amber)
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02), 
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.8,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      children: [
                        for (var i = 1; i <= 9; i++)
                          _buildNumButton(i.toString(), () => game.isVsAI && !game.isPlayer1Turn ? null : game.addDigit(i.toString())),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumButton("↩", () => game.undoLastMove(), isUndo: true)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildNumButton("❌", () => game.isVsAI && !game.isPlayer1Turn ? null : game.deleteDigit(), isAction: true)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildNumButton("0", () => game.isVsAI && !game.isPlayer1Turn ? null : game.addDigit("0"))),
                        const SizedBox(width: 10),
                                                  // ЗӨВ (✔) ТОВЧЛУУР: Энд нийлбэр оноог зарлана
                        Expanded(
                          child: _buildNumButton("✔", () {
                            if (game.isVsAI && !game.isPlayer1Turn) return;

                            // 1. Хэрэглэгчийн дэлгэц дээр бичсэн байгаа нийлбэр оноог уншиж авна
                            String totalScore = game.currentInput;

                            // 2. Хэрэв оноо хоосон биш бол шүүгч чангаар зарлана
                            if (totalScore.isNotEmpty) {
                              _caller.speak(totalScore); 
                            }

                            // 3. Оноог системд хадгалж дараагийн тоглогчийн ээлж рүү шилжүүлнэ
                            _handleScoreSubmit();
                          }, isSubmit: true),
                        ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


      Widget _buildPlayerCard(
        String name, 
        int score, 
        bool isActive, 
        String checkoutGuide, 
        int legsWon, 
        double avg, 
        int high100, 
        int high140, 
        int totalWins, 
        double bestAvg) {
      return AnimatedContainer(
        duration: const Duration(
          milliseconds: 250),
          padding: const EdgeInsets.all(4),
          width: MediaQuery.of(context).
          size.width * 0.46,
          height: 195, // ШИНЭ: Түүхэн өгөгдлийг багтаахын тулд өндрийг нэмэв
          decoration: BoxDecoration(
            color: isActive ? Colors.green.withOpacity(0.1) : 
          Colors.black45,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isActive ? Colors.green : Colors.black, 
               width: isActive ? 3.5 : 1.5,
            ),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(name, 
          style: TextStyle(fontSize: 14, 
          fontWeight: FontWeight.bold, 
          color: isActive ? Colors.green : Colors.grey), 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis),
          Text("ҮЕ ХОЖИЛ: $legsWon (Нийт: $totalWins🏆)", 
            style: const TextStyle(fontSize: 11, 
              color: Colors.green, 
              fontWeight: FontWeight.w600)),
          Text("$score", style: const TextStyle(
            fontSize: 48, 
            fontWeight: FontWeight.w900, 
            color: Colors.white)),
            Divider(
              color: Colors.grey.withOpacity(0.5), 
              height: 6),Row(mainAxisAlignment: 
                MainAxisAlignment.spaceBetween,
              children: [
              const Text("ДУНДАЖ:", 
                style: TextStyle(
                  fontSize: 11, 
                  color: Colors.grey)),
                Text("$avg (Дээд: $bestAvg)", 
                  style: const TextStyle(
                    fontSize: 11, 
                    color: Colors.white, 
                    fontWeight: FontWeight.bold)),
                  ],
                ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [
            const Text("100+ / 140+:", 
              style: TextStyle(
                fontSize: 11, 
                color: Colors.grey)),
              Text("$high100 / $high140", 
                style: const TextStyle(
                  fontSize: 11, color: Colors.amber, 
                  fontWeight: FontWeight.bold)),
                ],
              ),
            Divider(color: Colors.grey.withOpacity(0.5), 
              height: 6),Container(
                height: 20,
                alignment: Alignment.center,child: checkoutGuide.isNotEmpty? 
              Text("🎯 $checkoutGuide", 
              style: const TextStyle(
                fontSize: 12, 
                color: Colors.amber, 
                fontWeight: FontWeight.bold)): 
              const SizedBox(),
            ),
          ],
        ),
      );
    }
   Widget _buildNumButton(
    String text, 
    VoidCallback? onTap, {
      bool isAction = false, 
      bool isSubmit = false, 
      bool isUndo = false}) {
    
    // 1. Усны дусал шиг гялалзуулах өнгөний уусгалт (Gradient) бэлдэх
    List<Color> gradientColors = [
      Colors.white.withOpacity(0.18), // Дээд тал нь гэрэл ойсон тод
      Colors.white.withOpacity(0.04), // Доод тал нь тунгалаг ууссан
    ];
    Color borderColor = Colors.white.withOpacity(0.35); // Дусал шиг гялалзах нарийн ирмэг
    Color textColor = Colors.white.withOpacity(0.95);

    if (isAction) { // Улаан "❌" дусал
      gradientColors = [Colors.red.withOpacity(0.3), Colors.red.withOpacity(0.08)];
      borderColor = Colors.red.withOpacity(0.5);
      textColor = Colors.red.shade100;
    }
    if (isSubmit) { // Ногоон "✔" дусал
      gradientColors = [Colors.green.withOpacity(0.35), Colors.green.withOpacity(0.1)];
      borderColor = Colors.green.withOpacity(0.6);
      textColor = Colors.green.shade100;
    }
    if (isUndo) { // Цэнхэр саарал "↩" дусал
      gradientColors = [Colors.blueGrey.withOpacity(0.3), Colors.blueGrey.withOpacity(0.08)];
      borderColor = Colors.blueGrey.withOpacity(0.5);
      textColor = Colors.blueGrey.shade100;
    }

    // Товчлуур идэвхгүй үед (Робот бодож байхад) дуслыг хатаах / бүдгэрүүлэх
    if (onTap == null) {
      gradientColors = [Colors.white.withOpacity(0.03), Colors.white.withOpacity(0.01)];
      borderColor = Colors.white.withOpacity(0.08);
      textColor = Colors.white.withOpacity(0.2);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22), // Усны дусал шиг илүү дугуй булантай болгоно
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            // Цул өнгө биш, Градиент ашиглан дээрээс нь туссан гэрэл үүсгэнэ
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: borderColor,
              width: 1.3,
            ),
            // Дуслыг цаанаасаа товгор харагдуулах гэрлийн ойлт болон сүүдэр
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, -2), // Дээд талын гэрэлтэлт
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 3), // Доод талын зөөлөн сүүдэр
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              splashColor: textColor.withOpacity(0.2), // Дарахад усан дотор долгион үүсэх мэт
              highlightColor: textColor.withOpacity(0.05),
              onTap: onTap == null ? null : () => setState(onTap),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                child: Text(
                  text, 
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold, 
                    color: textColor,
                    shadows: [
                      Shadow(
                        blurRadius: 3,
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(1, 15 / 10),
                      )
                    ]
                  )
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class DartsCaller {
  final FlutterTts _flutterTts = FlutterTts();
  
  // Хэлэх ёстой тоонуудыг хадгалах дараалал (Жагсаалт)
  final List<String> _speechQueue = [];
  bool _isSpeaking = false; // Одоо дуугарч байгаа эсэхийг хянах нууц унтраалга

  DartsCaller() {
    _initTts();
  }

  void _initTts() {
    _flutterTts.setLanguage("en-US"); // Англиар хэлбэл дартсын шүүгч шиг гоё сонсогдоно
    _flutterTts.setSpeechRate(0.6);   // Хэлэх хурд (Үл ялиг удаашруулсан)
    _flutterTts.setVolume(1.0);       // Дууны хэмжээ хамгийн чанга дээр

    // Хамгийн чухал хэсэг: Нэг үг хэлж дуусахыг Гит системд мэдэгдэх ухаалаг холбоос
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false; 
      _checkQueue(); // Үг хэлж дуусангуут дараагийн үг байгаа эсэхийг шалгана
    });
  }

  // Товчлуур дарахад энэ функцийг дуудна
  void speak(String text) {
    _speechQueue.add(text); // Шинэ тоог шууд жагсаалтын төгсгөлд нэмнэ
    if (!_isSpeaking) {
      _checkQueue(); // Хэрэв апп одоогоор чимээгүй байвал шууд уншиж эхэлнэ
    }
  }

  void _checkQueue() async {
    if (_speechQueue.isEmpty) return; // Жагсаалт хоосон бол зогсоно

    _isSpeaking = true;
    String nextText = _speechQueue.removeAt(0); // Хамгийн эхний тоог сугалж авна
    await _flutterTts.speak(nextText); // Түүнийгээ дуустал нь уншина
  }
}