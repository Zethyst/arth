// The numbers from one to a hundred, in Hindi and in English.
//
// Hindi does not build its number names the way English does. There is no
// "forty-two" to assemble from forty and two: बयालीस is its own word, and so
// are the other ninety-nine. They can only be learnt one at a time, which is
// why they are here in full rather than computed.
//
// The Devanagari digits are derived from the value, so there is one fewer
// column to get wrong.

/// One number, by every name it goes by.
class HindiNumber {
  const HindiNumber(this.value, this.hindi, this.roman, this.english);

  final int value;

  /// The Hindi name in Devanagari: बयालीस.
  final String hindi;

  /// The same name in Roman letters. A hyphen marks two vowels that are
  /// spoken apart rather than run together: सत्ताईस is sattaa-ees, three
  /// beats, not two.
  final String roman;

  /// The English name: forty-two.
  final String english;

  /// Which ten this number belongs to: 0 for 1-10, 9 for 91-100.
  int get decade => (value - 1) ~/ 10;

  /// The value in Devanagari digits: ४२. ० is U+0966, and the rest follow.
  String get devanagari =>
      value.toString().split('').map((d) => String.fromCharCode(0x0966 + (d.codeUnitAt(0) - 0x30))).join();

  /// Whether this number answers [q], a query already through [foldQuery].
  ///
  /// Digits match from the front, so 4 offers four and the forties rather
  /// than every number with a 4 anywhere in it; names match anywhere, so
  /// half-remembered ones ("taalees") still come back.
  bool matches(String q) {
    if (q.isEmpty) return true;
    if (value.toString().startsWith(q) || devanagari.startsWith(q)) return true;
    return foldQuery(hindi).contains(q) || foldQuery(roman).contains(q) || foldQuery(english).contains(q);
  }
}

/// Lower-cases a query and drops everything that isn't a letter, a digit or
/// Devanagari, so "Forty-Two", "forty two" and "fortytwo" all arrive the same.
String foldQuery(String s) => s.toLowerCase().replaceAll(RegExp('[^a-z0-9\u0900-\u097f]'), '');

/// One to a hundred, in order; index 0 is one.
const kHindiNumbers = <HindiNumber>[
  HindiNumber(1, 'एक', 'ek', 'one'),
  HindiNumber(2, 'दो', 'do', 'two'),
  HindiNumber(3, 'तीन', 'teen', 'three'),
  HindiNumber(4, 'चार', 'chaar', 'four'),
  HindiNumber(5, 'पाँच', 'paanch', 'five'),
  HindiNumber(6, 'छह', 'chhah', 'six'),
  HindiNumber(7, 'सात', 'saat', 'seven'),
  HindiNumber(8, 'आठ', 'aath', 'eight'),
  HindiNumber(9, 'नौ', 'nau', 'nine'),
  HindiNumber(10, 'दस', 'das', 'ten'),
  HindiNumber(11, 'ग्यारह', 'gyaarah', 'eleven'),
  HindiNumber(12, 'बारह', 'baarah', 'twelve'),
  HindiNumber(13, 'तेरह', 'terah', 'thirteen'),
  HindiNumber(14, 'चौदह', 'chaudah', 'fourteen'),
  HindiNumber(15, 'पंद्रह', 'pandrah', 'fifteen'),
  HindiNumber(16, 'सोलह', 'solah', 'sixteen'),
  HindiNumber(17, 'सत्रह', 'satrah', 'seventeen'),
  HindiNumber(18, 'अठारह', 'athaarah', 'eighteen'),
  HindiNumber(19, 'उन्नीस', 'unnees', 'nineteen'),
  HindiNumber(20, 'बीस', 'bees', 'twenty'),
  HindiNumber(21, 'इक्कीस', 'ikkees', 'twenty-one'),
  HindiNumber(22, 'बाईस', 'baa-ees', 'twenty-two'),
  HindiNumber(23, 'तेईस', 'te-ees', 'twenty-three'),
  HindiNumber(24, 'चौबीस', 'chaubees', 'twenty-four'),
  HindiNumber(25, 'पच्चीस', 'pachchees', 'twenty-five'),
  HindiNumber(26, 'छब्बीस', 'chhabbees', 'twenty-six'),
  HindiNumber(27, 'सत्ताईस', 'sattaa-ees', 'twenty-seven'),
  HindiNumber(28, 'अट्ठाईस', 'atthaa-ees', 'twenty-eight'),
  HindiNumber(29, 'उनतीस', 'untees', 'twenty-nine'),
  HindiNumber(30, 'तीस', 'tees', 'thirty'),
  HindiNumber(31, 'इकतीस', 'ikattees', 'thirty-one'),
  HindiNumber(32, 'बत्तीस', 'battees', 'thirty-two'),
  HindiNumber(33, 'तैंतीस', 'taintees', 'thirty-three'),
  HindiNumber(34, 'चौंतीस', 'chauntees', 'thirty-four'),
  HindiNumber(35, 'पैंतीस', 'paintees', 'thirty-five'),
  HindiNumber(36, 'छत्तीस', 'chhattees', 'thirty-six'),
  HindiNumber(37, 'सैंतीस', 'saintees', 'thirty-seven'),
  HindiNumber(38, 'अड़तीस', 'adtees', 'thirty-eight'),
  HindiNumber(39, 'उनतालीस', 'untaalees', 'thirty-nine'),
  HindiNumber(40, 'चालीस', 'chaalees', 'forty'),
  HindiNumber(41, 'इकतालीस', 'iktaalees', 'forty-one'),
  HindiNumber(42, 'बयालीस', 'bayaalees', 'forty-two'),
  HindiNumber(43, 'तैंतालीस', 'taintaalees', 'forty-three'),
  HindiNumber(44, 'चवालीस', 'chavaalees', 'forty-four'),
  HindiNumber(45, 'पैंतालीस', 'paintaalees', 'forty-five'),
  HindiNumber(46, 'छियालीस', 'chhiyaalees', 'forty-six'),
  HindiNumber(47, 'सैंतालीस', 'saintaalees', 'forty-seven'),
  HindiNumber(48, 'अड़तालीस', 'adtaalees', 'forty-eight'),
  HindiNumber(49, 'उनचास', 'unchaas', 'forty-nine'),
  HindiNumber(50, 'पचास', 'pachaas', 'fifty'),
  HindiNumber(51, 'इक्यावन', 'ikyaavan', 'fifty-one'),
  HindiNumber(52, 'बावन', 'baavan', 'fifty-two'),
  HindiNumber(53, 'तिरपन', 'tirpan', 'fifty-three'),
  HindiNumber(54, 'चौवन', 'chauvan', 'fifty-four'),
  HindiNumber(55, 'पचपन', 'pachpan', 'fifty-five'),
  HindiNumber(56, 'छप्पन', 'chhappan', 'fifty-six'),
  HindiNumber(57, 'सत्तावन', 'sattaavan', 'fifty-seven'),
  HindiNumber(58, 'अट्ठावन', 'atthaavan', 'fifty-eight'),
  HindiNumber(59, 'उनसठ', 'unsath', 'fifty-nine'),
  HindiNumber(60, 'साठ', 'saath', 'sixty'),
  HindiNumber(61, 'इकसठ', 'iksath', 'sixty-one'),
  HindiNumber(62, 'बासठ', 'baasath', 'sixty-two'),
  HindiNumber(63, 'तिरसठ', 'tirsath', 'sixty-three'),
  HindiNumber(64, 'चौंसठ', 'chausath', 'sixty-four'),
  HindiNumber(65, 'पैंसठ', 'painsath', 'sixty-five'),
  HindiNumber(66, 'छियासठ', 'chhiyaasath', 'sixty-six'),
  HindiNumber(67, 'सड़सठ', 'sarsath', 'sixty-seven'),
  HindiNumber(68, 'अड़सठ', 'adsath', 'sixty-eight'),
  HindiNumber(69, 'उनहत्तर', 'unhattar', 'sixty-nine'),
  HindiNumber(70, 'सत्तर', 'sattar', 'seventy'),
  HindiNumber(71, 'इकहत्तर', 'ikahattar', 'seventy-one'),
  HindiNumber(72, 'बहत्तर', 'bahattar', 'seventy-two'),
  HindiNumber(73, 'तिहत्तर', 'tihattar', 'seventy-three'),
  HindiNumber(74, 'चौहत्तर', 'chauhattar', 'seventy-four'),
  HindiNumber(75, 'पचहत्तर', 'pachahattar', 'seventy-five'),
  HindiNumber(76, 'छिहत्तर', 'chhihattar', 'seventy-six'),
  HindiNumber(77, 'सतहत्तर', 'satahattar', 'seventy-seven'),
  HindiNumber(78, 'अठहत्तर', 'athahattar', 'seventy-eight'),
  HindiNumber(79, 'उन्यासी', 'unyaasee', 'seventy-nine'),
  HindiNumber(80, 'अस्सी', 'assee', 'eighty'),
  HindiNumber(81, 'इक्यासी', 'ikyaasee', 'eighty-one'),
  HindiNumber(82, 'बयासी', 'bayaasee', 'eighty-two'),
  HindiNumber(83, 'तिरासी', 'tiraasee', 'eighty-three'),
  HindiNumber(84, 'चौरासी', 'chauraasee', 'eighty-four'),
  HindiNumber(85, 'पचासी', 'pachaasee', 'eighty-five'),
  HindiNumber(86, 'छियासी', 'chhiyaasee', 'eighty-six'),
  HindiNumber(87, 'सत्तासी', 'sattaasee', 'eighty-seven'),
  HindiNumber(88, 'अट्ठासी', 'atthaasee', 'eighty-eight'),
  HindiNumber(89, 'नवासी', 'navaasee', 'eighty-nine'),
  HindiNumber(90, 'नब्बे', 'nabbe', 'ninety'),
  HindiNumber(91, 'इक्यानवे', 'ikyaanave', 'ninety-one'),
  HindiNumber(92, 'बानवे', 'baanave', 'ninety-two'),
  HindiNumber(93, 'तिरानवे', 'tiraanave', 'ninety-three'),
  HindiNumber(94, 'चौरानवे', 'chauraanave', 'ninety-four'),
  HindiNumber(95, 'पंचानवे', 'panchaanave', 'ninety-five'),
  HindiNumber(96, 'छियानवे', 'chhiyaanave', 'ninety-six'),
  HindiNumber(97, 'सत्तानवे', 'sattaanave', 'ninety-seven'),
  HindiNumber(98, 'अट्ठानवे', 'atthaanave', 'ninety-eight'),
  HindiNumber(99, 'निन्यानवे', 'ninyaanave', 'ninety-nine'),
  HindiNumber(100, 'सौ', 'sau', 'one hundred'),
];
