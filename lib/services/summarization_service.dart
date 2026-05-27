import 'summarization/summarization_service.dart'
    as new_summary;

class SummarizationService {
  final _service = new_summary.SummarizationService();

  String summarize(String text) {
    return _service.summarize(text);
  }
}
