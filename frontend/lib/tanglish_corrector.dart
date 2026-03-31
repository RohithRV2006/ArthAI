class TanglishCorrector {
  // ── THE ULTIMATE HOUSEHOLD TANGLISH DICTIONARY ──
  // Format: 'wrong word from mic': 'correct tanglish word'
  static const Map<String, String> _dictionary = {
    // Time & Periods
    'mosam': 'masam',
    'maasam': 'masam',
    'iniki': 'innaiku',
    'iniku': 'innaiku',
    'nethu': 'nethikku',

    // Actions & Intents
    'selav': 'selavu',
    'sellavu': 'selavu',
    'panen': 'pannen',
    'vangunen': 'vanginen',
    'kuduthen': 'kuduthan',
    'katinen': 'kattinen',
    'vadi': 'vaddi',
    'sollu': 'sollu',

    // Household Categories
    'vadagai': 'vaadagai',
    'vadagay': 'vaadagai',
    'vada guy': 'vaadagai', // Mic hilariously hears "vada guy"
    'maligai': 'maligai',
    'malligai': 'maligai',
    'sapad': 'saapadu',
    'sapadu': 'saapadu',
    'paul': 'paal',         // Mic hears the English name "Paul"
    'pal': 'paal',
    'karant': 'current',
    'karan': 'current',
    'foot': 'food',
    'shooping': 'shopping',

    // Medical, Kids, Finance
    'marundhu': 'marunthu',
    'maruthuvam': 'maruthuvam',
    'pulla': 'pillai',
    'pullai': 'pillai',
    'sambalam': 'sambalam',
    'sombalam': 'sambalam',
    'sample am': 'sambalam',
    'cotton': 'kadan',      // Mic hears "cotton" instead of kadan
    'kadam': 'kadan',
    'semippu': 'semippu',
    'samipu': 'semippu',
    'undiyal': 'undiyal',
  };

  static String fix(String input) {
    String correctedText = input;

    _dictionary.forEach((wrongWord, correctWord) {
      // The \b ensures we only replace exact whole words
      correctedText = correctedText.replaceAll(
        RegExp(r'\b' + wrongWord + r'\b', caseSensitive: false),
        correctWord,
      );
    });

    return correctedText;
  }
}