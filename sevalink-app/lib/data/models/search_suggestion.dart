class SearchSuggestion {
  final String text;
  final String type; // "CATEGORY", "WORKER", "SKILL"

  const SearchSuggestion({required this.text, required this.type});

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      text: json['text'] as String? ?? '',
      type: json['type'] as String? ?? 'GENERAL',
    );
  }
}
