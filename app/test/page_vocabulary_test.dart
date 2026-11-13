import 'dart:ui';

import 'package:arth/app/theme.dart';
import 'package:arth/core/text/page_text_index.dart';
import 'package:arth/features/reader/page_vocabulary.dart';
import 'package:arth/features/reader/page_words_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lays each character out on a 10×10 grid, one line per '\n'.
PageTextIndex _build(String text) {
  final rects = <Rect>[];
  var x = 0.0;
  var y = 0.0;
  for (final ch in text.split('')) {
    if (ch == '\n') {
      rects.add(Rect.zero);
      x = 0;
      y += 10;
    } else {
      rects.add(Rect.fromLTWH(x, y, 10, 10));
      x += 10;
    }
  }
  return PageTextIndex.build(text, rects);
}

List<String> _keys(String text) => advancedCandidates(_build(text)).map((w) => w.key).toList();

PageVocabularyWord _w(String key, int? rank) =>
    PageVocabularyWord(key: key, text: key, source: 0, wordIndex: 0, rank: rank);

void main() {
  _rarity();
  group('advancedCandidates', () {
    test('short words are not vocabulary', () {
      expect(_keys('The cat sat on a mat with gusto.'), ['with', 'gusto']);
    });

    test('a word is offered once however often it appears', () {
      expect(_keys('Gusto, and more gusto, and gusto again.'), ['gusto', 'more', 'again']);
    });

    test('a capitalised word mid-sentence is a name, not a hard word', () {
      expect(_keys('They met Darcy there.'), ['they', 'there']);
    });

    test('page numbers, years and citations are not words', () {
      expect(_keys('Printed 1813 page 42 chapter iv.'), ['printed', 'page', 'chapter']);
    });

    test('a hyphenated or possessive word survives', () {
      expect(_keys("The well-known author's prose."), ['well-known', "author's", 'prose']);
    });
  });

  group('alwaysCapitalised', () {
    test('a name never appears lower-case', () {
      expect(alwaysCapitalised(_build('Elizabeth spoke. They all heard Elizabeth plainly.')), contains('elizabeth'));
    });

    test('a word used as ordinary prose does', () {
      expect(alwaysCapitalised(_build('Gusto matters. They showed little gusto.')), isNot(contains('gusto')));
    });

    test('a word that only ever opens a sentence is still flagged', () {
      // Which is why the rank has to agree before it is dropped.
      expect(alwaysCapitalised(_build('Printed in 1813.')), contains('printed'));
    });
  });

  group('ordering', () {
    test('the rarest known word comes first', () {
      final list = [_w('common', 900), _w('rare', 40000), _w('middling', 9000)]..sort(PageVocabularyWord.compare);
      expect(list.map((w) => w.key), ['rare', 'middling', 'common']);
    });

    test('a word the phone\u2019s dictionary lacks is the rarest of all', () {
      // The on-device slice is the commonest 20,000 words, so a miss means
      // rarer than anything in it — "obsequious" outranks "refreshments".
      final list = [_w('refreshments', 19000), _w('obsequious', null)]..sort(PageVocabularyWord.compare);
      expect(list.map((w) => w.key), ['obsequious', 'refreshments']);
    });

    test('two unknown words keep a stable alphabetical order', () {
      final list = [_w('zephyr', null), _w('brimless', null)]..sort(PageVocabularyWord.compare);
      expect(list.map((w) => w.key), ['brimless', 'zephyr']);
    });
  });

  test('the threshold is the reader’s own "common enough" line', () {
    expect(kAdvancedWordRank, greaterThan(1000));
    expect(kMinAdvancedWordLength, 4);
  });
}

void _rarity() {
  group('how rare a word is', () {
    // Everything in the sheet is already past kAdvancedWordRank, so the
    // tiers only have to separate "uncommon" from "never seen this".
    test('a word the dictionary does not have is the rarest of all', () {
      expect(rarityOf(null), WordRarity.rarest);
    });

    test('past the on-device slice is very rare', () {
      expect(rarityOf(15001), WordRarity.veryRare);
      expect(rarityOf(19000), WordRarity.veryRare);
    });

    test('inside the slice but past the threshold is rare', () {
      expect(rarityOf(kAdvancedWordRank + 1), WordRarity.rare);
      expect(rarityOf(15000), WordRarity.rare);
    });

    test('every tier has its own colour, so the band means something', () {
      const c = ArthColors.light;
      final colors = {
        for (final r in WordRarity.values) rarityColor(r, c),
      };
      expect(colors, hasLength(WordRarity.values.length));
    });
  });
}
