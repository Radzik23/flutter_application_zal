import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MojBudzetDomowyApp());

class MojBudzetDomowyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mój Budżet Domowy',
      initialRoute: '/',
      routes: {
        '/': (context) => StronaGlowna(),
        '/historia': (context) => HistoriaTransakcji(),
      },
    );
  }
}

class StronaGlowna extends StatefulWidget {
  @override
  _StronaGlownaState createState() => _StronaGlownaState();
}

class _StronaGlownaState extends State<StronaGlowna> {
  List<Transakcja> _transakcje = [];
  double _sumaWydanychPieniedzy = 0.0;

  @override
  void initState() {
    super.initState();
    _wczytajTransakcje();
  }

  void _dodajNowaTransakcje(
      String tytulTx, double kwotaTx, String kategoriaTx) {
    final nowaTx = Transakcja(
      id: DateTime.now().toString(),
      tytul: tytulTx,
      kwota: kwotaTx,
      data: DateTime.now(),
      kategoria: kategoriaTx,
    );

    setState(() {
      _transakcje.add(nowaTx);
      _sumaWydanychPieniedzy += kwotaTx;
    });
    _zapiszTransakcje();

    Navigator.pushNamed(context, '/historia');
  }

  void _zapiszTransakcje() async {
    final prefs = await SharedPreferences.getInstance();
    final String transakcjeJson =
        jsonEncode(_transakcje.map((tx) => tx.toJson()).toList());
    await prefs.setString('transakcje', transakcjeJson);
  }

  void _wczytajTransakcje() async {
    final prefs = await SharedPreferences.getInstance();
    final String? transakcjeJson = prefs.getString('transakcje');
    if (transakcjeJson != null) {
      final List<dynamic> transakcjeList = jsonDecode(transakcjeJson);
      setState(() {
        _transakcje =
            transakcjeList.map((tx) => Transakcja.fromJson(tx)).toList();
      });
    }
    _aktualizujSumeWydanychPieniedzy();
  }

  void _aktualizujSumeWydanychPieniedzy() {
    setState(() {
      _sumaWydanychPieniedzy =
          _transakcje.fold(0.0, (sum, item) => sum + item.kwota);
    });
  }

  void _rozpocznijDodawanieNowejTransakcji(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) {
        return GestureDetector(
          onTap: () {},
          child: NowaTransakcja(_dodajNowaTransakcje),
          behavior: HitTestBehavior.opaque,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mój Budżet Domowy'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _rozpocznijDodawanieNowejTransakcji(context),
          ),
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/historia'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            width: double.infinity,
            child: Card(
              color: Colors.blue,
              child: Column(
                children: <Widget>[
                  Text('Wykres'),
                  Container(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 5.0,
                        centerSpaceRadius: 40.0,
                        sections: _getChartData(),
                      ),
                    ),
                  ),
                  Text(
                      'Suma wydanych pieniędzy: \$${_sumaWydanychPieniedzy.toStringAsFixed(2)}'),
                ],
              ),
              elevation: 5,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _transakcje.length,
              itemBuilder: (ctx, index) {
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 30,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: FittedBox(
                          child: Text(
                              '\$${_transakcje[index].kwota.toStringAsFixed(2)}'),
                        ),
                      ),
                    ),
                    title: Text(
                      _transakcje[index].tytul,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      DateFormat('yyyy-MM-dd').format(_transakcje[index].data),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _rozpocznijDodawanieNowejTransakcji(context),
      ),
    );
  }

  List<PieChartSectionData> _getChartData() {
    Map<String, double> kategorieSumy = {};
    _transakcje.forEach((tx) {
      double kwota = tx.kwota;
      if (kategorieSumy.containsKey(tx.kategoria)) {
        kategorieSumy[tx.kategoria] =
            (kategorieSumy[tx.kategoria] ?? 0) + kwota;
      } else {
        kategorieSumy[tx.kategoria] = kwota;
      }
    });

    return kategorieSumy.entries.map((entry) {
      final isTouched = entry.key == kategorieSumy.keys.first;
      final double fontSize = isTouched ? 16 : 12;

      return PieChartSectionData(
        color: Colors.primaries[kategorieSumy.keys.toList().indexOf(entry.key) %
            Colors.primaries.length],
        value: entry.value,
        title: '\$${entry.value.toStringAsFixed(2)}',
        radius: isTouched ? 60 : 50,
        titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xffffffff)),
      );
    }).toList();
  }
}

class NowaTransakcja extends StatefulWidget {
  final Function(String, double, String) dodajTx;

  NowaTransakcja(this.dodajTx);

  @override
  _NowaTransakcjaState createState() => _NowaTransakcjaState();
}

class _NowaTransakcjaState extends State<NowaTransakcja> {
  final tytulController = TextEditingController();
  final kwotaController = TextEditingController();
  final kategoriaController = TextEditingController();

  void _zatwierdzDane() {
    final wprowadzonyTytul = tytulController.text;
    final wprowadzonaKwota = double.tryParse(kwotaController.text) ?? 0;
    final wprowadzonaKategoria = kategoriaController.text;

    if (wprowadzonyTytul.isEmpty ||
        wprowadzonaKwota <= 0 ||
        wprowadzonaKategoria.isEmpty) {
      return;
    }

    widget.dodajTx(
      wprowadzonyTytul,
      wprowadzonaKwota,
      wprowadzonaKategoria,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      child: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            TextField(
              decoration: InputDecoration(labelText: 'Tytuł'),
              controller: tytulController,
              onSubmitted: (_) => _zatwierdzDane(),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Kwota'),
              controller: kwotaController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onSubmitted: (_) => _zatwierdzDane(),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Kategoria'),
              controller: kategoriaController,
              onSubmitted: (_) => _zatwierdzDane(),
            ),
            TextButton(
              onPressed: _zatwierdzDane,
              child: Text('Dodaj transakcję'),
              style: TextButton.styleFrom(
                primary: Colors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoriaTransakcji extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historia Transakcji'),
      ),
      body: Center(
        child: Text('Tu będzie widok historii transakcji.'),
      ),
    );
  }
}

class Transakcja {
  final String id;
  final String tytul;
  final double kwota;
  final DateTime data;
  final String kategoria;

  Transakcja({
    required this.id,
    required this.tytul,
    required this.kwota,
    required this.data,
    required this.kategoria,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tytul': tytul,
        'kwota': kwota,
        'data': data.toIso8601String(),
        'kategoria': kategoria,
      };

  static Transakcja fromJson(Map<String, dynamic> json) => Transakcja(
        id: json['id'],
        tytul: json['tytul'],
        kwota: json['kwota'],
        data: DateTime.parse(json['data']),
        kategoria: json['kategoria'],
      );
}