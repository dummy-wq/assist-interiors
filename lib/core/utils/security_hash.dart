import 'dart:convert';
import 'dart:math';

/// Pure-Dart cryptographic SHA-256 + per-user salted password hashing utility.
/// Prevents plaintext credentials from ever being persisted in local storage.
class SecurityHash {
  SecurityHash._();

  static const List<int> _k = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1,
    0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
    0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
    0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
    0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
    0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ];

  static const int _mask32 = 0xffffffff;

  static int _rotr(int x, int n) =>
      ((x & _mask32) >>> n) | ((x << (32 - n)) & _mask32);

  /// Generates a 16-byte cryptographically random hex salt.
  static String generateSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Computes a standard lower-case hex SHA-256 digest of [input].
  static String sha256Hex(String input) {
    final msg = utf8.encode(input);
    final bitLen = msg.length * 8;
    final padded = List<int>.from(msg)..add(0x80);
    while ((padded.length % 64) != 56) {
      padded.add(0);
    }
    for (int shift = 56; shift >= 0; shift -= 8) {
      padded.add((bitLen >> shift) & 0xff);
    }

    int h0 = 0x6a09e667;
    int h1 = 0xbb67ae85;
    int h2 = 0x3c6ef372;
    int h3 = 0xa54ff53a;
    int h4 = 0x510e527f;
    int h5 = 0x9b05688c;
    int h6 = 0x1f83d9ab;
    int h7 = 0x5be0cd19;

    final w = List<int>.filled(64, 0);

    for (int chunkStart = 0; chunkStart < padded.length; chunkStart += 64) {
      for (int i = 0; i < 16; i++) {
        final j = chunkStart + i * 4;
        w[i] =
            ((padded[j] << 24) |
                (padded[j + 1] << 16) |
                (padded[j + 2] << 8) |
                padded[j + 3]) &
            _mask32;
      }
      for (int i = 16; i < 64; i++) {
        final s0 = _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >>> 3);
        final s1 = _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >>> 10);
        w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & _mask32;
      }

      int a = h0, b = h1, c = h2, d = h3, e = h4, f = h5, g = h6, h = h7;
      for (int i = 0; i < 64; i++) {
        final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
        final ch = (e & f) ^ ((~e & _mask32) & g);
        final temp1 = (h + s1 + ch + _k[i] + w[i]) & _mask32;
        final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final temp2 = (s0 + maj) & _mask32;

        h = g;
        g = f;
        f = e;
        e = (d + temp1) & _mask32;
        d = c;
        c = b;
        b = a;
        a = (temp1 + temp2) & _mask32;
      }

      h0 = (h0 + a) & _mask32;
      h1 = (h1 + b) & _mask32;
      h2 = (h2 + c) & _mask32;
      h3 = (h3 + d) & _mask32;
      h4 = (h4 + e) & _mask32;
      h5 = (h5 + f) & _mask32;
      h6 = (h6 + g) & _mask32;
      h7 = (h7 + h) & _mask32;
    }

    return [h0, h1, h2, h3, h4, h5, h6, h7]
        .map((v) => (v & _mask32).toRadixString(16).padLeft(8, '0'))
        .join();
  }

  /// Stretches [password] with [salt] across multiple SHA-256 rounds.
  static String hashPassword(String password, String salt) {
    var digest = sha256Hex('$salt:$password');
    for (int i = 0; i < 250; i++) {
      digest = sha256Hex('$salt:$digest:$password');
    }
    return digest;
  }

  /// Constant-time comparison against stored salted [expectedHash].
  static bool verifyPassword(
    String password,
    String salt,
    String expectedHash,
  ) {
    final computed = hashPassword(password, salt);
    if (computed.length != expectedHash.length) return false;
    int diff = 0;
    for (int i = 0; i < computed.length; i++) {
      diff |= computed.codeUnitAt(i) ^ expectedHash.codeUnitAt(i);
    }
    return diff == 0;
  }
}
