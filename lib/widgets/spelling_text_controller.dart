import 'package:flutter/material.dart';

import '../services/spelling_service.dart';

class SpellingTextController extends TextEditingController {
  SpellingTextController({super.text});

  List<SpellingIssue> _issues = [];

  void updateIssues(List<SpellingIssue> issues) {
    _issues = issues;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final source = text;
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final errorStyle = baseStyle.copyWith(
      color: const Color(0xFFB91C1C),
      decoration: TextDecoration.underline,
      decorationColor: const Color(0xFFDC2626),
      decorationStyle: TextDecorationStyle.wavy,
      decorationThickness: 2,
    );

    final spans = <TextSpan>[];
    var cursor = 0;

    final orderedIssues = _issues.where((issue) {
      return issue.start >= 0 &&
          issue.end <= source.length &&
          issue.start < issue.end;
    }).toList()..sort((a, b) => a.start.compareTo(b.start));

    for (final issue in orderedIssues) {
      if (issue.start < cursor) {
        continue;
      }

      if (issue.start > cursor) {
        spans.add(
          TextSpan(
            text: source.substring(cursor, issue.start),
            style: baseStyle,
          ),
        );
      }

      spans.add(
        TextSpan(
          text: source.substring(issue.start, issue.end),
          style: errorStyle,
        ),
      );
      cursor = issue.end;
    }

    if (cursor < source.length) {
      spans.add(TextSpan(text: source.substring(cursor), style: baseStyle));
    }

    return TextSpan(style: baseStyle, children: spans);
  }
}
