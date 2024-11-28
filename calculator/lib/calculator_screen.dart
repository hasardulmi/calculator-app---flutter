import 'dart:math';
import 'package:flutter/material.dart';
import 'package:calculator/button_values.dart';
import 'package:math_expressions/math_expressions.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String expression = ""; // Stores the input expression
  String result = "0";    // Stores the result
  String previousResult = ""; // Store the previous result
  
  // History list to store previous operations and results
  List<String> history = [];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: showHistory,  // Show history when tapped
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: clearHistory,  // Clear history when tapped
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Display area for the expression and result
            Expanded(
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      expression.isEmpty ? "" : expression, // If expression is empty, show nothing
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.end,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result,
                      style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
            ),
            // Calculator buttons layout
            Wrap(
              children: Btn.buttonValues
                  .map(
                    (value) => SizedBox(
                      width: value == Btn.n0
                          ? screenSize.width / 2
                          : screenSize.width / 4,
                      height: screenSize.width / 6,
                      child: buildButton(value),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Display the history of previous operations
  void showHistory() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('History'),
          content: SingleChildScrollView(
            child: Column(
              children: history
                  .map((entry) => ListTile(
                        title: Text(entry),
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Clear history
  void clearHistory() {
    setState(() {
      history.clear();
    });
    Navigator.pop(context); // Close the dialog if it's open
  }

  Widget buildButton(String value) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Material(
        color: getBtnColor(value),
        clipBehavior: Clip.hardEdge,
        shape: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(100),
        ),
        child: InkWell(
          onTap: () => onBtnTap(value),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ),
        ),
      ),
    );
  }

  void onBtnTap(String value) {
    setState(() {
      if (value == Btn.del) {
        delete();
      } else if (value == Btn.clr) {
        clearAll();
      } else if (value == Btn.calculate) {
        calculate();
      } else if (value == Btn.square) {
        appendValue("√("); // Add √( for square root
      } else if (value == Btn.minors) {
        toggleSign();
      } else if (value == Btn.openbracket || value == Btn.closebracket) {
        appendValue(value);
      } else {
        appendValue(value);
      }
    });
  }

  void clearAll() {
    expression = "";
    result = "0";
    previousResult = ""; // Clear the previous result
  }

  void delete() {
    if (expression.isNotEmpty) {
      expression = expression.substring(0, expression.length - 1);
    }
  }

  void appendValue(String value) {
    if (expression == "Error") {
      expression = "";
    }
    if (previousResult.isNotEmpty) {
      // If there's a previous result, append the new input to it
      expression = previousResult + value;
      previousResult = ""; // Clear the stored result after appending
    } else {
      expression += value;
    }
  }

  void calculate() {
    if (expression.isEmpty) return;

    // Handle consecutive parentheses like (89)(85)(96)7 as multiplication
    expression = handleAdjacentParentheses(expression);

    try {
      // Check for division 
      if (expression.contains('/0')) {
        result = "Undefined"; // Division by zero
        previousResult = ""; // Clear previous result
        expression = ""; // Clear expression
        return; // Exit the method
      }

      // Insert '*' where necessary, and replace square root symbol
      String parsedExpression = expression
          .replaceAll(Btn.multiply, '*')
          .replaceAll(Btn.divide, '/')
          .replaceAll(Btn.per, '/100')
          .replaceAll("√", "sqrt"); // Replace √ with sqrt

      // Evaluate the expression
      Parser parser = Parser();
      Expression exp = parser.parse(parsedExpression);
      ContextModel contextModel = ContextModel();

      double eval = exp.evaluate(EvaluationType.REAL, contextModel);
      if (eval.isInfinite || eval.isNaN) {
        result = "Undefined";
      } else {
        result = eval.toString();
      }
      previousResult = result; // Store the result to append later

      // Save the expression and result to history
      history.add("$expression = $result");

      expression = ""; // Clear the expression to show only the result
    } catch (e) {
      result = "Error";
      expression = ""; // Clear the expression in case of error
      previousResult = ""; // Clear the previous result on error
    }
  }

  // Handle consecutive parentheses by inserting multiplication in between
  String handleAdjacentParentheses(String expression) {
    String result = expression;

    // This regular expression will match closing bracket followed by opening bracket
    final regExp = RegExp(r'\)(\()');
    result = result.replaceAllMapped(regExp, (match) {
      return ')*(';  // Add multiplication between parentheses
    });

    return result;
  }

  void toggleSign() {
    if (expression.isNotEmpty) {
      // Check if the last number is negative and toggle the sign
      if (expression.startsWith('-')) {
        // Remove the negative sign
        expression = expression.substring(1);
      } else {
        // Add the negative sign
        expression = "-$expression";
      }
    } else {
      // If empty, assume "0" and toggle it
      expression = "-";
    }
  }

  Color getBtnColor(String value) {
    return [Btn.del, Btn.clr].contains(value)
        ? const Color.fromARGB(255, 0, 212, 46)
        : [
            Btn.per,
            Btn.multiply,
            Btn.add,
            Btn.subtract,
            Btn.divide,
            Btn.calculate,
            Btn.openbracket,
            Btn.closebracket,
            Btn.minors,
            Btn.square,
          ].contains(value)
            ? const Color.fromARGB(255, 241, 155, 16)
            : const Color.fromARGB(221, 165, 162, 164);
  }
}
