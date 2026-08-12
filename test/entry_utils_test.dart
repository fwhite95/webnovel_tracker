import 'package:flutter_test/flutter_test.dart';
import 'package:webnovel_tracker/shared/utils/entry_utils.dart';

void main() {
  group('splitTitle', () {
    test('takes the chapter from either end', () {
      expect(splitTitle('Chapter 48 - Reverend Insanity'), (
        title: 'Reverend Insanity',
        chapter: '48',
      ));
      expect(splitTitle('Reverend Insanity - Ch. 48'), (
        title: 'Reverend Insanity',
        chapter: '48',
      ));
    });

    test('drops the chapter name with the number', () {
      expect(
        splitTitle('Chapter 48: The Beginning - Reverend Insanity - NovelFull'),
        (title: 'Reverend Insanity - NovelFull', chapter: '48'),
      );
    });

    test('keeps split releases', () {
      expect(splitTitle('Reverend Insanity - Chapter 4 Part 2'), (
        title: 'Reverend Insanity',
        chapter: '4 part 2',
      ));
    });

    test('strips only the marker when the title is one segment', () {
      expect(splitTitle('Read Reverend Insanity Chapter 48 online free'), (
        title: 'Read Reverend Insanity online free',
        chapter: '48',
      ));
    });

    test('keeps a marker-only title rather than blanking it', () {
      expect(splitTitle('Chapter 48'), (title: 'Chapter 48', chapter: ''));
    });

    test('does not split hyphenated titles', () {
      expect(splitTitle('Re-Zero - Chapter 12'), (
        title: 'Re-Zero',
        chapter: '12',
      ));
    });

    test('royalroad', () {
      // ignore: avoid_print
      print(splitTitle('Chapter 5- Child of Destiny - Sky Pride  | Royal Road'));
    });
  });

  group('titleKey', () {
    test('two chapters of one novel share a key', () {
      final a = splitTitle('Chapter 48: The Beginning - Reverend Insanity');
      final b = splitTitle('Chapter 49: The Second Step - Reverend Insanity');
      expect(titleKey(a.title), titleKey(b.title));
    });

    test('URL-titled rows share a key across chapters', () {
      expect(
        titleKey('https://novelfull.com/reverend-insanity/chapter-48'),
        titleKey('https://novelfull.com/reverend-insanity/chapter-49'),
      );
    });

    test('different novels do not', () {
      expect(
        titleKey('Reverend Insanity'),
        isNot(titleKey('Lord of the Mysteries')),
      );
    });
  });
}
