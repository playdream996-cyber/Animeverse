class StoryDefinition {
  const StoryDefinition({required this.id, required this.title, required this.genre,
    required this.description, required this.art, required this.character,
    required this.tag, required this.opening, required this.choices,
    required this.responses, required this.foundation, required this.sourceUrl,
    this.referenceTitle, this.referenceUrl});
  final String id, title, genre, description, art, character, tag, opening;
  final List<String> choices, responses;
  final String foundation, sourceUrl;
  final String? referenceTitle, referenceUrl;
  StoryDefinition withReference(String title, String url) => StoryDefinition(
    id: id, title: this.title, genre: genre, description: description, art: art,
    character: character, tag: tag, opening: opening, choices: choices,
    responses: responses, foundation: foundation, sourceUrl: sourceUrl,
    referenceTitle: title, referenceUrl: url);
}
abstract interface class StoryCatalog {
  List<StoryDefinition> get stories;
  Future<List<StoryDefinition>> refresh();
}
