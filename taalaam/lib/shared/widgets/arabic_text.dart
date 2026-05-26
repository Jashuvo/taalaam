import 'package:flutter/material.dart';

/// Renders Arabic text with correct RTL direction and NotoNaskhArabic font.
/// Always use this widget — never render Arabic in a plain Text() without Directionality.
class ArabicText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color? color;
  final TextAlign textAlign;
  final FontWeight fontWeight;

  const ArabicText(
    this.text, {
    super.key,
    this.fontSize = 22,
    this.color,
    this.textAlign = TextAlign.right,
    this.fontWeight = FontWeight.normal,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontFamily: 'NotoNaskhArabic',
          fontSize: fontSize,
          height: 1.8,
          fontWeight: fontWeight,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Bangla body text with HindSiliguri font.
class BanglaText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color? color;
  final TextAlign textAlign;

  const BanglaText(
    this.text, {
    super.key,
    this.fontSize = 16,
    this.color,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontFamily: 'HindSiliguri',
        fontSize: fontSize,
        height: 1.6,
        color: color,
      ),
    );
  }
}
