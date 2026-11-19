class ActivityAnalysis {
  final String category;
  final String title;
  final String source;
  final String? warning;

  const ActivityAnalysis({
    required this.category,
    required this.title,
    required this.source,
    this.warning,
  });

  factory ActivityAnalysis.fromJson(Map<String, dynamic> json) {
    const categories = [
      'Sport',
      'Shopping',
      'Culture',
      'Plein air',
      'Gastronomie',
      'Loisirs',
      'Autre',
    ];
    final category = json['category'];
    if (!categories.contains(category)) {
      throw const FormatException('Catégorie IA invalide.');
    }
    return ActivityAnalysis(
      category: category as String,
      title: json['title']?.toString().trim() ?? '',
      source: json['source']?.toString() ?? 'CLIP',
      warning: json['warning']?.toString(),
    );
  }
}
