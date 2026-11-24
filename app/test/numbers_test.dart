import 'package:arth/features/tools/numbers.dart';
import 'package:flutter_test/flutter_test.dart';

HindiNumber _n(int value) => kHindiNumbers[value - 1];

List<int> _found(String query) =>
    [for (final n in kHindiNumbers) if (n.matches(foldQuery(query))) n.value];

void main() {
  group('the table', () {
    test('is one to a hundred, in order', () {
      expect(kHindiNumbers.length, 100);
      expect([for (final n in kHindiNumbers) n.value], List.generate(100, (i) => i + 1));
    });

    test('names no number twice', () {
      // A Hindi name repeated would mean one of the hundred is wrong: no two
      // numbers between 1 and 100 share a name.
      expect({for (final n in kHindiNumbers) n.hindi}.length, 100);
      expect({for (final n in kHindiNumbers) n.roman}.length, 100);
      expect({for (final n in kHindiNumbers) n.english}.length, 100);
    });

    test('leaves no name blank', () {
      for (final n in kHindiNumbers) {
        expect(n.hindi.trim(), isNotEmpty, reason: '${n.value} has no Hindi name');
        expect(n.roman.trim(), isNotEmpty, reason: '${n.value} has no Roman name');
        expect(n.english.trim(), isNotEmpty, reason: '${n.value} has no English name');
      }
    });

    test('groups into ten tens', () {
      expect(_n(1).decade, 0);
      expect(_n(10).decade, 0);
      expect(_n(11).decade, 1);
      expect(_n(91).decade, 9);
      expect(_n(100).decade, 9);
    });

    test('writes the value in Devanagari digits', () {
      expect(_n(1).devanagari, '१');
      expect(_n(42).devanagari, '४२');
      expect(_n(90).devanagari, '९०');
      expect(_n(100).devanagari, '१००');
    });
  });

  group('search', () {
    test('folds case, spaces and hyphens away', () {
      expect(foldQuery('Forty-Two'), 'fortytwo');
      expect(foldQuery('  forty two '), 'fortytwo');
      expect(foldQuery('sattaa-ees'), 'sattaaees');
    });

    test('finds a number by any of its names', () {
      expect(_found('बयालीस'), [42]);
      expect(_found('bayaalees'), [42]);
      expect(_found('forty-two'), [42]);
      expect(_found('fortytwo'), [42]);
      expect(_found('४२'), [42]);
    });

    test('finds a half-remembered name anywhere in it', () {
      // Every name in the forties carries -aalees; only some of them keep the
      // t (iktaalees, but bayaalees), which is exactly why a reader searching
      // from memory needs the loose match.
      expect(_found('aalees'), containsAll([40, 41, 42, 43, 44, 45, 46, 47, 48]));
      expect(_found('taalees'), containsAll([39, 41, 43, 45, 47, 48]));
      expect(_found('taalees'), isNot(contains(42)));
      expect(_found('aalees'), isNot(contains(30)));
    });

    test('matches digits from the front, so a 4 is not every 4', () {
      expect(_found('4'), [4, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49]);
      expect(_found('100'), [100]);
    });

    test('keeps the hyphenated names reachable without the hyphen', () {
      expect(_found('sattaaees'), [27]);
      expect(_found('sattaa-ees'), [27]);
    });

    test('comes back empty for a name no number has', () {
      expect(_found('zzz'), isEmpty);
    });

    test('an empty query holds nothing back', () {
      expect(_found('').length, 100);
    });
  });
}
