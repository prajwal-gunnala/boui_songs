class Pfx {
  final String start;
  final String end;
  Pfx(this.start, this.end);
}

Pfx buildPfx(String t) {
  if (t.isEmpty) {
    // Return range covering everything.
    return Pfx('', String.fromCharCode(0x10FFFF));
  }
  // Use the search term as is with the high Unicode suffix.
  return Pfx(t, t + '\uf8ff');
}
