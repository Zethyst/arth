// The words that carry no meaning on their own. Both the idioms list and the
// synonym and antonym sets use them to tell a lesson from a piece of
// grammar: a phrase built only from these plus one content word ("at first",
// "by the way") reads as grammar, and "the", "is" and "you" are not words a
// reader sets out to learn a synonym for.

/// Words that carry no meaning on their own. A phrase built only from these
/// plus one content word ("at first", "by the way") reads as grammar; one
/// that uses two or more ("night owl", "spill the beans") reads as an idiom.
const Set<String> kFunctionWords = {
  'a', 'an', 'the', 'and', 'or', 'but', 'if', 'so', 'as', 'at', 'by', 'for',
  'from', 'in', 'into', 'of', 'off', 'on', 'out', 'to', 'up', 'with', 'be',
  'is', 'am', 'are', 'was', 'were', 'been', 'being', 'do', 'does', 'did',
  'have', 'has', 'had', 'will', 'would', 'shall', 'should', 'can', 'could',
  'may', 'might', 'must', 'not', 'no', 'nor', 'than', 'then', 'that', 'this',
  'these', 'those', 'there', 'here', 'it', 'its', 'he', 'she', 'they', 'them',
  'his', 'her', 'their', 'you', 'your', 'we', 'our', 'i', 'me', 'my', 'all',
  'any', 'some', 'such', 'very', 'too', 'just', 'only', 'own', 'same',
  'other', 'another', 'each', 'every', 'both', 'few', 'more', 'most', 'much',
  'many', 'what', 'which', 'who', 'whom', 'whose', 'when', 'where', 'why',
  'how', 'about', 'after', 'again', 'against', 'because', 'before', 'below',
  'between', 'down', 'during', 'once', 'over', 'under', 'while',
};
