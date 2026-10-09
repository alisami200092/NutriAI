/// Deterministic clinical red-flag detector for the NutriBot chat.
///
/// Runs before any AI call. When it fires, the bot must stop meal planning
/// and show [triageNotice] only. It is intentionally biased toward safety:
/// when in doubt it flags, except for clearly negated statements
/// (e.g. "no blood in my stool") and ordinary period cramps.
class RedFlagTriageService {
  static const String triageNotice =
      "⚠️ These symptoms may require immediate medical attention. Please consult a qualified doctor or visit an urgent care center promptly.";

  /// Returns true if [input] contains at least one non-negated red flag.
  static bool hasRedFlag(String input) => detect(input).isNotEmpty;

  /// Returns the red-flag categories detected in [input]
  /// (e.g. `['gi_bleeding', 'high_fever']`). Empty if none.
  static List<String> detect(String input) {
    final text = _normalize(input);
    if (text.isEmpty) return const [];

    final bool mentionsPeriod = RegExp(
      r"\b(period|periods|menstrual|menses|pms|menstruation)\b",
    ).hasMatch(text);

    final Set<String> found = {};
    for (final rule in _rules) {
      if (found.contains(rule.category)) continue;
      for (final match in rule.pattern.allMatches(text)) {
        final phrase = match.group(0)!;

        // Ordinary menstrual cramps are not an abdominal emergency.
        if (rule.category == 'severe_abdominal_pain' &&
            mentionsPeriod &&
            phrase.contains('cramp')) {
          continue;
        }

        if (_isNegatedBefore(text, match.start)) continue;
        if (!rule.allowInternalNegation && _containsNegation(phrase)) continue;

        found.add(rule.category);
        break;
      }
    }
    return found.toList();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  static String _normalize(String input) => input
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll('`', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static const Set<String> _negationWords = {
    'no', 'not', 'never', 'without', 'nahi', 'nahin', 'nai',
    "don't", 'dont', "didn't", 'didnt', "doesn't", 'doesnt',
    "isn't", 'isnt', "wasn't", 'wasnt', "haven't", 'havent',
    "hasn't", 'hasnt', "aren't", 'arent', "weren't", 'werent',
  };

  static const Set<String> _internalNegationWords = {
    'no', 'not', 'never', 'without', 'nahi', 'nahin', 'nai',
  };

  /// Checks the last few words of the same clause before the match,
  /// so "no blood in stool" is negated but
  /// "not sure why, but there is blood in my stool" is not.
  static bool _isNegatedBefore(String text, int start) {
    final prefix = text.substring(0, start);
    final clause = prefix
        .split(RegExp(r"[.!?;,]|\bbut\b|\bhowever\b|\balthough\b|\bthough\b"))
        .last;
    final words =
        clause.trim().split(' ').where((w) => w.isNotEmpty).toList();
    final window =
        words.length > 4 ? words.sublist(words.length - 4) : words;
    return window.any(_negationWords.contains);
  }

  /// Catches negation inside a match, e.g. "my stool has no blood".
  static bool _containsNegation(String phrase) =>
      phrase.split(' ').any(_internalNegationWords.contains);

  static const String _stool =
      r"(stool|stools|poop|poo|potty|motion|motions|feces|faeces|bowel movements?|latrine|pakhana)";
  static const String _vomit =
      r"(vomit\w*|throw\w* up|threw up|puk\w*|ulti\w*)";
  static const String _belly =
      r"(abdomen|abdominal|stomach|belly|tummy|gut|lower right|right side|pet)";
  static const String _severe =
      r"(severe|sharp|stabbing|excruciating|unbearable|intense|extreme|terrible|worst|shooting|knife[- ]like)";

  static final List<_Rule> _rules = [
    // 1. Blood in stool / black stool / vomiting blood
    _Rule('gi_bleeding', r"\b(blood|bloody|bleeding|black|tarry|maroon|khoon|kaala|kala|kaali|kali)\b[^.!?]{0,30}\b" "$_stool" r"\b"),
    _Rule('gi_bleeding', r"\b" "$_stool" r"\b[^.!?]{0,30}\b(blood|bloody|black|tarry|maroon|bright red|khoon|kaala|kala|kaali|kali)\b"),
    _Rule('gi_bleeding', r"\b(pooping|pooped|passing|passed|shitting) blood\b"),
    _Rule('gi_bleeding', r"\b(rectal bleeding|bleeding from (the |my )?(rectum|bum|behind)|melena|hematochezia|hematemesis|khooni dast)\b"),
    _Rule('gi_bleeding', r"\b" "$_vomit" r"\b[^.!?]{0,20}\b(blood|khoon)\b"),
    _Rule('gi_bleeding', r"\b(blood|bloody|khoon)\b[^.!?]{0,15}\b(vomit\w*|ulti\w*)\b"),
    _Rule('gi_bleeding', r"\bcoffee[- ]ground\w*\b"),

    // 2. High fever
    _Rule('high_fever', r"\b(high|very high|burning|severe|raging|tez) (fever|temperature|temp|bukhar)\b"),
    _Rule('high_fever', r"\b(fever|temperature|temp|bukhar)\b[^.!?\d]{0,15}\b(10[2-9]|11\d|39|4[0-2])(\.\d+)?\b"),
    _Rule('high_fever', r"\b(10[2-9]|39|4[0-2])(\.\d+)? ?(°|degrees?|deg\b|f\b|c\b)[^.!?\d]{0,10}\b(fever|temperature|temp|bukhar)\b"),

    // 3. Persistent vomiting / unable to keep liquids down
    _Rule('persistent_vomiting', r"\b" "$_vomit" r"\b[^.!?]{0,30}\b(all night|all day|whole day|whole night|since yesterday|for (a|one|1|2|two|several|many) days?|24 ?(h|hrs?|hours?)|non[- ]?stop|continuous\w*|constant\w*|repeated\w*|every (time|hour)|can'?t stop)\b",
        allowInternalNegation: true),
    _Rule('persistent_vomiting', r"\b(continuous|constant|nonstop|non-stop|persistent|repeated|uncontrollable) (vomit\w*|throwing up)\b"),
    _Rule('persistent_vomiting', r"\b(can'?t|cannot|can not|unable to|not able to) (keep|hold) (down )?(water|liquids?|fluids?|drinks?)( down| in)?\b",
        allowInternalNegation: true),
    _Rule('persistent_vomiting', r"\b(can'?t|cannot|can not|unable to|not able to) (keep|hold) (anything|any thing|food) (down|in)\b",
        allowInternalNegation: true),

    // 4. Severe localized / sharp abdominal pain
    _Rule('severe_abdominal_pain', r"\b" "$_severe" r"\b[^.!?]{0,25}\b(pain|ache|cramp\w*)\b[^.!?]{0,25}\b" "$_belly" r"\b"),
    _Rule('severe_abdominal_pain', r"\b" "$_severe" r"\b[^.!?]{0,25}\b" "$_belly" r"\b[^.!?]{0,15}\b(pain|ache|cramp\w*)\b"),
    _Rule('severe_abdominal_pain', r"\b" "$_belly" r"\b[^.!?]{0,15}\b(pain|ache)\b[^.!?]{0,20}\b(severe|sharp|unbearable|excruciating|intense|extreme)\b"),
    _Rule('severe_abdominal_pain', r"\b" "$_belly" r" (pain|ache)\b[^.!?]{0,25}\b(can'?t (move|walk|stand|breathe|sleep)|doubled over)\b",
        allowInternalNegation: true),
    _Rule('severe_abdominal_pain', r"\b(pain|ache)\b[^.!?]{0,20}\blower right\b"),

    // 5. Fainting / severe or unexplained dizziness
    _Rule('fainting_dizziness', r"\b(fainted|fainting|faint spells?|feel(ing)? faint|passed out|pass out|passing out|blacked out|blacking out|collapsed|lost consciousness|losing consciousness|unconscious|behosh\w*)\b"),
    _Rule('fainting_dizziness', r"\b(severe|extreme|unexplained|constant|very bad|tez) (dizz\w*|light-?headed\w*|chakkar)\b"),
    _Rule('fainting_dizziness', r"\bdizz\w*\b[^.!?]{0,25}\b(can'?t stand|fell|fall(ing)? down|room (is )?spinning)\b",
        allowInternalNegation: true),
  ];
}

class _Rule {
  final String category;
  final RegExp pattern;
  final bool allowInternalNegation;

  _Rule(this.category, String source, {this.allowInternalNegation = false})
      : pattern = RegExp(source);
}
