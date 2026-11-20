import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/core/routing/home_widget_action.dart';

void main() {
  test('uri/parse round-trips every action', () {
    for (final a in HomeWidgetAction.values) {
      expect(HomeWidgetAction.parse(a.uri), a);
    }
  });

  test('matches the URIs the Android widgets launch with', () {
    // Keep in sync with QuickActionWidgets.kt.
    expect(
      HomeWidgetAction.parse(Uri.parse('taskenda://new/note')),
      HomeWidgetAction.newNote,
    );
    expect(
      HomeWidgetAction.parse(Uri.parse('taskenda://new/task')),
      HomeWidgetAction.newTask,
    );
    expect(
      HomeWidgetAction.parse(Uri.parse('taskenda://new/event')),
      HomeWidgetAction.newEvent,
    );
  });

  test('missing or unknown URIs parse to null', () {
    for (final u in [
      null,
      Uri.parse(''),
      Uri.parse('taskenda://new'),
      Uri.parse('taskenda://new/'),
      Uri.parse('taskenda://new/banana'),
      Uri.parse('taskenda://new/note/extra'),
      Uri.parse('taskenda://open/note'),
      Uri.parse('https://new/note'),
    ]) {
      expect(HomeWidgetAction.parse(u), isNull, reason: '$u');
    }
  });

  test('parses the list widget row and header URIs', () {
    // Keep in sync with SummaryWidgets.kt.
    expect(
      HomeWidgetOpenItem.parse(Uri.parse('taskenda://open/note/abc-123')),
      const HomeWidgetOpenItem(HomeWidgetItemKind.note, 'abc-123'),
    );
    expect(
      HomeWidgetOpenItem.parse(Uri.parse('taskenda://open/event/e1')),
      const HomeWidgetOpenItem(HomeWidgetItemKind.event, 'e1'),
    );
    expect(
      HomeWidgetSection.parse(Uri.parse('taskenda://section/tasks')),
      HomeWidgetSection.tasks,
    );
    for (final item in HomeWidgetItemKind.values) {
      final open = HomeWidgetOpenItem(item, 'x');
      expect(HomeWidgetOpenItem.parse(open.uri), open);
    }
    for (final section in HomeWidgetSection.values) {
      expect(HomeWidgetSection.parse(section.uri), section);
    }
  });

  test('malformed list widget URIs parse to null', () {
    for (final u in [
      Uri.parse('taskenda://open/note'),
      Uri.parse('taskenda://open/note/'),
      Uri.parse('taskenda://open/banana/1'),
      Uri.parse('taskenda://open/note/1/extra'),
      Uri.parse('taskenda://new/note'),
    ]) {
      expect(HomeWidgetOpenItem.parse(u), isNull, reason: '$u');
    }
    for (final u in [
      Uri.parse('taskenda://section'),
      Uri.parse('taskenda://section/archive'),
      Uri.parse('taskenda://new/note'),
    ]) {
      expect(HomeWidgetSection.parse(u), isNull, reason: '$u');
    }
  });
}
