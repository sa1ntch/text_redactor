class EventModel {
  final String subject;
  final String action;
  final String object;
  final String originalSentence;
  final double score;

  EventModel({
    required this.subject,
    required this.action,
    required this.object,
    required this.originalSentence,
    required this.score,
  });

  @override
  String toString() {
    return '$subject $action $object';
  }
}
