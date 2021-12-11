import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:small_read/small_read.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: const Scaffold(
        backgroundColor: Color(0xFF444444),
        body: Padding(
          padding: EdgeInsets.all(40),
          child: Converter(),
        ),
      ),
    );
  }
}

class Converter extends StatefulWidget {
  const Converter({
    Key? key,
  }) : super(key: key);

  @override
  State<Converter> createState() => _ConverterState();
}

class _ConverterState extends State<Converter> {
  static const jsonDecoder = JsonDecoder();
  static const jsonEncoder = JsonEncoder.withIndent("  ");

  late TextEditingController ctrlJson, ctrlSR;
  @override
  void initState() {
    super.initState();
    ctrlJson = TextEditingController(
      text: [
        '{',
        '  "field-1": "value-1",',
        '  "field-2": "value-2",',
        '  "object": {',
        '    "of1": "v1",',
        '    "of2": "v2",',
        '    "nestedObject": {',
        '      "nestedField": "100"',
        '    }',
        '  }',
        '}',
      ].join('\n'),
    );
    ctrlSR = TextEditingController();
  }

  @override
  void dispose() {
    ctrlJson.dispose();
    ctrlSR.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TextBox(
          title: "JSON",
          ctrl: ctrlJson,
          onConvert: convertJsonToSr,
        ),
        TextBox(
          title: "SR",
          ctrl: ctrlSR,
          onConvert: convertSrToJson,
        ),
      ],
    );
  }

  void convertJsonToSr() {
    late String sr;
    try {
      Map json = jsonDecoder.convert(ctrlJson.text);
      sr = SmallReadConverter.encode(json.cast());
    } catch (e) {
      _showError(e);
      return;
    }
    setState(() {
      ctrlSR.text = sr;
    });
  }

  void convertSrToJson() {
    late String json;
    try {
      Map sr = SmallReadConverter.decode(ctrlSR.text);
      json = jsonEncoder.convert(sr);
    } catch (e) {
      _showError(e);
      return;
    }
    setState(() {
      ctrlJson.text = json;
    });
  }

  void _showError(error) {
    showDialog(
      context: context,
      builder: (c) => Center(
        child: Text(
          "ERROR: $error",
        ),
      ),
    );
  }
}

class TextBox extends StatelessWidget {
  const TextBox({
    Key? key,
    required this.title,
    required this.ctrl,
    required this.onConvert,
  }) : super(key: key);

  final String title;
  final TextEditingController ctrl;
  final void Function() onConvert;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 300,
          height: 600,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            color: Color(0xFF222222),
          ),
          child: TextField(
            controller: ctrl,
            minLines: 20,
            maxLines: null,
            style: GoogleFonts.robotoMono(),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onConvert,
          child: const Text("Convert"),
        ),
      ],
    );
  }
}
