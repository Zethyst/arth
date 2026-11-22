// A chip's label has to turn over with its fill. Material keeps only the
// label style's *colour* for resolving, so the state rides on a
// WidgetStateColor; a WidgetStateTextStyle is flattened to a style that
// carries neither colour nor font, and a label with no colour paints white —
// invisible on an unselected chip, which fills with card.

import 'package:arth/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('a chip label reads against its fill in ${brightness.name}', (tester) async {
      final c = brightness == Brightness.dark ? ArthColors.dark : ArthColors.light;
      await tester.pumpWidget(
        MaterialApp(
          theme: arthTheme(brightness),
          home: Scaffold(
            body: Row(
              children: [
                for (final selected in [true, false])
                  ChoiceChip(
                    label: Text(selected ? 'picked' : 'not picked'),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) {},
                  ),
              ],
            ),
          ),
        ),
      );
      TextStyle styleOf(String label) => DefaultTextStyle.of(tester.element(find.text(label))).style;
      expect(styleOf('picked').color, c.paper, reason: 'selected: ink fill');
      expect(styleOf('not picked').color, c.ink, reason: 'unselected: card fill');
      // The label keeps its voice, too: the same flattening lost the font.
      expect(styleOf('not picked').fontFamily, contains('MartianMono'));
    });
  }
}
