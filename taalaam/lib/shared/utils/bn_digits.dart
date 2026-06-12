/// Converts every ASCII digit in [n] to its Bengali numeral equivalent.
String bnDigits(Object n) =>
    '$n'.replaceAllMapped(RegExp(r'\d'), (m) => '০১২৩৪৫৬৭৮৯'[int.parse(m[0]!)]);
