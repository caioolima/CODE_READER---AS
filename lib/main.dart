import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:jiffy/jiffy.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

void main() {
  runApp(CodeReaderApp());
}

class CodeReaderApp extends StatefulWidget {
  @override
  _CodeReaderAppState createState() => _CodeReaderAppState();
}

class _CodeReaderAppState extends State<CodeReaderApp> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Code Reader',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: _isLoading ? SplashScreen() : HomeScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Code Reader',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<BarcodeData> history = [];

  Future<void> scanBarcode() async {
    String barcode = await FlutterBarcodeScanner.scanBarcode(
      '#FF0000',
      'Cancelar',
      true,
      ScanMode.BARCODE,
    );

    if (barcode != '-1') {
      setState(() {
        String formattedDateTime = Jiffy().format("dd/MM/yyyy HH:mm");
        history.add(BarcodeData(code: barcode, status: 'Encontrado', time: formattedDateTime));
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Código de Barras'),
            content: Text('Código: $barcode'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Fechar'),
              ),
            ],
          ),
        );
      });
    } else {
      setState(() {
        history.add(BarcodeData(code: 'N/A', status: 'Código não encontrado/Leitura cancelada', time: ''));
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Código de Barras'),
            content: Text('Leitura cancelada ou nenhum código encontrado.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Fechar'),
              ),
            ],
          ),
        );
      });
    }
  }

  void deleteHistoryItems(List<int> indexes) {
    setState(() {
      indexes.sort((a, b) => b.compareTo(a));
      for (int index in indexes) {
        history.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Code Reader'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              child: AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'Olá, sou Code Reader.',
                    textStyle: TextStyle(fontSize: 28,  fontWeight: FontWeight.bold),
                    speed: const Duration(milliseconds: 100),
                  ),
                ],
                totalRepeatCount: 1,
                pause: const Duration(milliseconds: 1000),
                displayFullTextOnTap: true,
                stopPauseOnTap: true,
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: scanBarcode,
                child: Text('Fazer Leitura', style: TextStyle(fontSize: 16)),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HistoryScreen(history: history, onDelete: deleteHistoryItems),
                    ),
                  );
                },
                child: Text('Ver Histórico', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  final List<BarcodeData> history;
  final Function(List<int>) onDelete;

  HistoryScreen({required this.history, required this.onDelete});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<int> selectedIndexes = [];

  Future<void> _refreshHistory() async {
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      selectedIndexes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshHistory,
        child: ListView.builder(
          itemCount: widget.history.length,
          itemBuilder: (context, index) {
            BarcodeData item = widget.history[index];
            String formattedTime = item.time.isNotEmpty ? item.time : 'N/A';

            return ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Leitura ${widget.history.length - index} - $formattedTime',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('Status: ${item.status}'),
                ],
              ),
              tileColor: selectedIndexes.contains(index) ? Colors.grey[300] : null,
              onTap: () {
                setState(() {
                  if (selectedIndexes.contains(index)) {
                    selectedIndexes.remove(index);
                  } else {
                    selectedIndexes.add(index);
                  }
                });
              },
            );
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: ElevatedButton(
            onPressed: selectedIndexes.isEmpty
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Excluir Leituras'),
                        content: Text('Selecione as leituras que deseja excluir:'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              widget.onDelete(selectedIndexes);
                              Navigator.pop(context);
                            },
                            child: Text('Excluir'),
                          ),
                        ],
                      ),
                    );
                  },
            child: Text('Excluir Leituras'),
          ),
        ),
      ),
    );
  }
}

class BarcodeData {
  final String code;
  final String status;
  final String time;

  BarcodeData({required this.code, required this.status, required this.time});
}