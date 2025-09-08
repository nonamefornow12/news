import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MH Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        checkboxTheme: CheckboxThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          side: const BorderSide(color: Colors.black, width: 2),
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.black;
            }
            return Colors.white;
          }),
          checkColor: MaterialStateProperty.all(Colors.white),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      home: const GoalsPage(),
    );
  }
}

// Category icons
final Map<String, IconData> categoryIcons = {
  "Health": Icons.favorite,
  "Mental Health": Icons.self_improvement,
  "Gym": Icons.fitness_center,
  "Work": Icons.work,
  "Study": Icons.menu_book,
  "Family": Icons.family_restroom,
  "Finance": Icons.attach_money,
  "Faith": Icons.church,
  "Other": Icons.lightbulb,
};

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  List<String> _goals = [];
  List<bool> _goalStatus = [];
  List<String> _goalCategories = [];
  List<String> _goalNotes = [];
  Map<String, List<Map<String, dynamic>>> _history = {};

  final List<String> _categories = [
    "Health",
    "Mental Health",
    "Gym",
    "Work",
    "Study",
    "Family",
    "Finance",
    "Faith",
    "Other"
  ];

  String _filterCategory = "All";

  @override
  void initState() {
    super.initState();
    _loadGoals();
    _checkForNewDay();
  }

  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final goals = prefs.getStringList('goals') ?? [];
    final goalStatus =
        prefs.getStringList('goalStatus')?.map((e) => e == 'true').toList() ??
            [];
    final goalCategories = prefs.getStringList('goalCategories') ?? [];
    final goalNotes = prefs.getStringList('goalNotes') ?? [];
    final historyString = prefs.getString('history');

    if (historyString != null && historyString.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(historyString);
        _history = decoded.map((k, v) {
          final list =
              (v as List).map((e) => Map<String, dynamic>.from(e)).toList();
          return MapEntry(k, list);
        });
      } catch (e) {
        _history = {};
      }
    }

    while (goalStatus.length < goals.length) goalStatus.add(false);
    while (goalCategories.length < goals.length) goalCategories.add("Other");
    while (goalNotes.length < goals.length) goalNotes.add("");

    setState(() {
      _goals = goals;
      _goalStatus = goalStatus;
      _goalCategories = goalCategories;
      _goalNotes = goalNotes;
    });
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('goals', _goals);
    await prefs.setStringList(
        'goalStatus', _goalStatus.map((e) => e.toString()).toList());
    await prefs.setStringList('goalCategories', _goalCategories);
    await prefs.setStringList('goalNotes', _goalNotes);
    await prefs.setString('history', jsonEncode(_history));
  }

  Future<void> _checkForNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final lastReset = prefs.getString('lastReset');
    final now =
        DateTime.now().toUtc().add(const Duration(hours: 1)); // Amsterdam UTC+1
    final today = DateFormat('yyyy-MM-dd').format(now);

    if (lastReset != today) {
      if (_goals.isNotEmpty) {
        _history[today] = [];
        for (int i = 0; i < _goals.length; i++) {
          _history[today]!.add({
            "goal": _goals[i],
            "done": _goalStatus[i],
            "category": _goalCategories[i],
            "note": _goalNotes[i],
          });
        }
      }

      setState(() {
        _goalStatus = List.filled(_goals.length, false);
      });

      await prefs.setString('lastReset', today);
      await _saveGoals();
    }
  }

  void _addGoal(String goal, String category, String note) {
    setState(() {
      _goals.add(goal);
      _goalStatus.add(false);
      _goalCategories.add(category);
      _goalNotes.add(note);
    });
    _saveGoals();
  }

  void _editGoal(int index, String goal, String category, String note) {
    setState(() {
      _goals[index] = goal;
      _goalCategories[index] = category;
      _goalNotes[index] = note;
    });
    _saveGoals();
  }

  void _deleteGoal(int index) {
    setState(() {
      _goals.removeAt(index);
      _goalStatus.removeAt(index);
      _goalCategories.removeAt(index);
      _goalNotes.removeAt(index);
    });
    _saveGoals();
  }

  void _showGoalDialog({int? index}) {
    final controller =
        TextEditingController(text: index != null ? _goals[index] : '');
    final noteController =
        TextEditingController(text: index != null ? _goalNotes[index] : '');
    String selectedCategory =
        index != null ? _goalCategories[index] : _categories.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.black,
                      child: Icon(
                        categoryIcons[selectedCategory] ?? Icons.lightbulb,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: index == null ? "New Goal" : "Edit Goal",
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: "Notes / Description",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _categories.contains(selectedCategory)
                      ? selectedCategory
                      : "Other",
                  items: _categories
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Row(
                              children: [
                                Icon(categoryIcons[cat]),
                                const SizedBox(width: 8),
                                Text(cat),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedCategory = value ?? "Other"),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Choose Category",
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      String goal = controller.text.replaceAll("god", "God");
                      if (index == null) {
                        _addGoal(goal, selectedCategory, noteController.text);
                      } else {
                        _editGoal(
                            index, goal, selectedCategory, noteController.text);
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: Text(index == null ? "Add Goal" : "Save Changes"),
                ),
                if (index != null) ...[
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () {
                      _deleteGoal(index);
                      Navigator.pop(context);
                    },
                    child: const Text("Delete Goal"),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds styled text where "God" is not crossed out, but the rest is
  Widget _buildGoalText(String goal, bool done) {
    if (!done) {
      return Text(
        goal,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final regex = RegExp(r"(God|god)");
    final matches = regex.allMatches(goal);

    if (matches.isEmpty) {
      return Text(
        goal,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.lineThrough,
        ),
      );
    }

    List<TextSpan> spans = [];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: goal.substring(lastIndex, match.start),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.lineThrough,
          ),
        ));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
        ),
      ));
      lastIndex = match.end;
    }

    if (lastIndex < goal.length) {
      spans.add(TextSpan(
        text: goal.substring(lastIndex),
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.lineThrough,
        ),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildGoalList() {
    if (_goals.isEmpty) {
      return const Center(
        child: Text(
          "No goals yet.\nAdd one with the + button!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
      );
    }

    final Map<String, List<int>> categoryMap = {};
    for (int i = 0; i < _goals.length; i++) {
      final cat = _goalCategories[i];
      if (_filterCategory == "All" || cat == _filterCategory) {
        categoryMap.putIfAbsent(cat, () => []).add(i);
      }
    }

    return ListView(
      children: categoryMap.entries.map((entry) {
        final category = entry.key;
        final indices = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black,
                  child: Icon(categoryIcons[category], color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  category,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ],
            ),
            const Divider(),
            ...indices.map((index) {
              final goal = _goals[index];

              return ListTile(
                title: _buildGoalText(goal, _goalStatus[index]),
                subtitle: _goalNotes[index].isNotEmpty
                    ? Text(_goalNotes[index])
                    : null,
                leading: Checkbox(
                  value: _goalStatus[index],
                  onChanged: (value) {
                    setState(() {
                      _goalStatus[index] = value ?? false;
                    });
                    _saveGoals();
                  },
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.black54),
                  onPressed: () => _showGoalDialog(index: index),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GoalDetailPage(
                      title: goal,
                      note: _goalNotes[index],
                      category: _goalCategories[index],
                      done: _goalStatus[index],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      }).toList(),
    );
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HistoryPage(history: _history)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MH Habit Tracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: _openHistory,
            tooltip: 'History',
          ),
          DropdownButton<String>(
            value: _filterCategory,
            underline: const SizedBox(),
            dropdownColor: Colors.white,
            items: ["All", ..._categories]
                .map((cat) =>
                    DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
            onChanged: (val) =>
                setState(() => _filterCategory = val ?? "All"),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildGoalList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGoalDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ----------------- Goal Detail Page -----------------
class GoalDetailPage extends StatelessWidget {
  final String title;
  final String note;
  final String category;
  final bool done;

  const GoalDetailPage({
    super.key,
    required this.title,
    required this.note,
    required this.category,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFEFEFEF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  CircleAvatar(
                      backgroundColor: Colors.black,
                      child: Icon(categoryIcons[category] ?? Icons.lightbulb,
                          color: Colors.white)),
                  const SizedBox(width: 12),
                  Text(category,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 12),
                if (note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text("Notes: $note",
                        style: const TextStyle(fontSize: 16)),
                  ),
                const SizedBox(height: 20),
                Text("Status: ${done ? "✅ Completed" : "❌ Not completed"}",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: done ? Colors.green : Colors.red)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------- History Page -----------------
class HistoryPage extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> history;

  const HistoryPage({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final sortedDates = history.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    if (sortedDates.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("History")),
        body: const Center(child: Text("No history yet.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("History")),
      body: ListView.builder(
        itemCount: sortedDates.length,
        itemBuilder: (context, idx) {
          final date = sortedDates[idx];
          final items = history[date] ?? [];
          return ExpansionTile(
            title: Text(DateFormat.yMMMMd().format(DateTime.parse(date))),
            children: items.map((entry) {
              final title = entry['goal'] ?? '';
              final done = entry['done'] == true;
              final cat = entry['category'] ?? 'Other';
              return ListTile(
                leading: CircleAvatar(
                    backgroundColor: Colors.black,
                    child: Icon(categoryIcons[cat] ?? Icons.lightbulb,
                        color: Colors.white)),
                title: Text(title),
                trailing: Icon(done ? Icons.check_circle : Icons.remove_circle,
                    color: done ? Colors.green : Colors.red),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
