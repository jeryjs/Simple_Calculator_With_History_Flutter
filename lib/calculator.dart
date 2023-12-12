// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/services.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MaterialApp(home: Calculator()));
}

class Calculator extends StatefulWidget {
  const Calculator({Key? key}) : super(key: key);

  @override
  State<Calculator> createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  String output = "0";
  String _expression = "";
  List<String> _history = [];
  int _historyIndex = 0;

  buttonPressed(String buttonText) async {
    setState(() {
      if (buttonText == "C") {
        _expression = "";
        output = "0";
      } else if (buttonText == "=") {
        try {
          String parseableExp = convertToParceableExp(_expression);
          Expression exp = Parser().parse(parseableExp);
          ContextModel cm = ContextModel();
          output = '${exp.evaluate(EvaluationType.REAL, cm)}';
          _history.add("$_expression = $output");
          saveHistory();
        } catch (e) {
          output = "Error";
        }
      } else {
        if (output == "0") {
          output = buttonText;
        } else {
          output = output + buttonText;
        }
        _expression = output;
      }
    });
  }
  String convertToParceableExp(str) {
    String exp;
    exp = str.replaceAll('%', '/100*');
    exp = exp.replaceAll('x', '*');
    exp = exp.replaceAll('÷', '/');
    exp = exp.replaceAll(RegExp(r'[*%/]$'), '');
    return exp;
  }

  get showHistory {
  loadHistory().then((_) {
    showGeneralDialog(
      context: context,
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return ScaleTransition(
              scale: animation,
              child: AlertDialog(
                title: const Text('History'),
                content: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: List<Widget>.generate(_history.length, (int index) {
                    String historyItem = _history[index];
                    return GestureDetector(
                      onTap: () {
                        this.setState(() {
                          _expression = historyItem.split(' = ')[0];
                          output = _expression;
                        });
                        Navigator.of(context).pop();
                      },
                      child: Chip(
                        label: Text(historyItem),
                        onDeleted: () {
                          setState(() {
                            _history.removeAt(index);
                            saveHistory();
                          });
                        },
                      ),
                    );
                  }),
                ),
                actions: [
                  TextButton(
                    child: const Text('Close'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _history.clear();
                        saveHistory();
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text('Clear History'),
                  ),
                ],
              ),
            );
          });
        },
        transitionDuration: const Duration(milliseconds: 200),
      );
    });
  }
  get previousExpression async {
    await loadHistory();
    loadHistory().then((_) {
      if (_history.isNotEmpty) {
        setState(() {
          _expression = _history[_historyIndex].split(' = ')[0];
          output = _expression;
          _historyIndex = (_historyIndex + 1) % _history.length;
        });
      }
    });
  }
  get copyOutputToClipboard {
    Clipboard.setData(ClipboardData(text: output)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Copied to Clipboard: $output"))
      );
    });
  }
  get backspacePressed {
    setState(() {
      if (output.length > 1) {
        output = output.substring(0, output.length - 1);
        _expression = output;
      } else {
        output = "0";
        _expression = "";
      }
    });
  }

  saveHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('history', _history.toSet().toList());
  }

  loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _history = prefs.getStringList('history') ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Simple Calculator')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              child: AutoSizeText(
                output,
                style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
                maxLines: 1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
            child: Row(
              children: [
                specialButton(Icons.access_time_outlined, ()=>showHistory),
                specialButton(Icons.keyboard_double_arrow_up_outlined, ()=>previousExpression),
                specialButton(Icons.copy_all_outlined, ()=>copyOutputToClipboard),
                const Spacer(),
                specialButton(Icons.backspace_outlined, ()=>backspacePressed),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                buildButtonRow("C", "(", ")", "÷", fg1: clr.error, fg2: clr.primary, fg3: clr.primary, fg4: clr.primary),
                buildButtonRow("7", "8", "9", "x", fg4: clr.primary),
                buildButtonRow("4", "5", "6", "-", fg4: clr.primary),
                buildButtonRow("1", "2", "3", "+", fg4: clr.primary),
                buildButtonRow("%", "0", ".", "=", fg4: clr.primary, bg4: clr.primaryContainer),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildButtonRow(String b1, String b2, String b3, String b4, {Color? fg1, Color? fg2, Color? fg3, Color? fg4, Color? bg1, Color? bg2, Color? bg3, Color? bg4}) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildButton(b1, fg: fg1, bg: bg1),
          buildButton(b2, fg: fg2, bg: bg2),
          buildButton(b3, fg: fg3, bg: bg3),
          buildButton(b4, fg: fg4, bg: bg4),
        ],
      ),
    );
  }

  Widget specialButton(IconData icon, fun) {
    return IconButton(
      icon: Icon(icon),
      iconSize: 28,
      color: Theme.of(context).colorScheme.primary,
      onPressed: fun,
    );
  }

  Widget buildButton(String buttonText, {Color? fg, Color? bg}) {
    fg ??= Theme.of(context).colorScheme.onSurface;
    return Expanded(
      child: ElevatedButton(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.resolveWith((states) => fg),
          backgroundColor: MaterialStateProperty.resolveWith((states) => bg),
        ),
        onPressed: () => buttonPressed(buttonText),
        child: Text(
          buttonText,
          style: const TextStyle(fontSize: 36),
        ),
      ),
    );
  }
}