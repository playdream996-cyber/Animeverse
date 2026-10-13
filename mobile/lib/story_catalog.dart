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
  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'genre': genre, 'description': description, 'art': art,
    'character': character, 'tag': tag, 'opening': opening, 'choices': choices,
    'responses': responses, 'foundation': foundation, 'sourceUrl': sourceUrl,
    'referenceTitle': referenceTitle, 'referenceUrl': referenceUrl};
  factory StoryDefinition.fromJson(Map<String, dynamic> j) => StoryDefinition(
    id: j['id'] as String, title: j['title'] as String, genre: j['genre'] as String,
    description: j['description'] as String, art: j['art'] as String,
    character: j['character'] as String, tag: j['tag'] as String,
    opening: j['opening'] as String, choices: List<String>.from(j['choices'] as List),
    responses: List<String>.from(j['responses'] as List), foundation: j['foundation'] as String,
    sourceUrl: j['sourceUrl'] as String, referenceTitle: j['referenceTitle'] as String?,
    referenceUrl: j['referenceUrl'] as String?);
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
