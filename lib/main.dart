import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

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
  final List<Transakcja> _transakcje = [];
  double _sumaWydanychPieniedzy = 0.0;

  void _dodajNowaTransakcje(String tytulTx, double kwotaTx, String kategoriaTx) {
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

    // Nawiguj do trasy '/historia'
    Navigator.pushNamed(context, '/historia');
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
                  Text('Suma wydanych pieniędzy: \$${_sumaWydanychPieniedzy.toStringAsFixed(2)}'),
                ],
              ),
              elevation: 5,
            ),
          ),
          Column(
            children: _transakcje.map((tx) {
              return Card(
                child: Row(
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 15,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.purple,
                          width: 2,
                        ),
                      ),
                      padding: EdgeInsets.all(10),
                      child: Text(
                        '\$${tx.kwota.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          tx.tytul,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          DateFormat('yyyy-MM-dd').format(tx.data),
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'Kategoria: ${tx.kategoria}',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
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
      if (kategorieSumy.containsKey(tx.kategoria)) {
        kategorieSumy[tx.kategoria] = kategorieSumy[tx.kategoria]! + tx.kwota;
      } else {
        kategorieSumy[tx.kategoria] = tx.kwota;
      }
    });

    return kategorieSumy.entries.map((entry) {
      final isTouched = entry.key == kategorieSumy.keys.first;
      final double fontSize = isTouched ? 16 : 12;

      return PieChartSectionData(
        color: Colors.primaries[kategorieSumy.keys.toList().indexOf(entry.key) % Colors.primaries.length],
        value: entry.value,
        title: '\$${entry.value.toStringAsFixed(2)}',
        radius: isTouched ? 60 : 50,
        titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: const Color(0xffffffff)),
      );
    }).toList();
  }
}

class NowaTransakcja extends StatefulWidget {
  final Function dodajTx;

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
    final wprowadzonaKwota = double.parse(kwotaController.text);
    final wprowadzonaKategoria = kategoriaController.text;

    if (wprowadzonyTytul.isEmpty || wprowadzonaKwota <= 0 || wprowadzonaKategoria.isEmpty) {
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
}
