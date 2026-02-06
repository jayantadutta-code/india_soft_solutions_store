import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';



/* ===================== MODELS ===================== */

class WorkList {
  String title;
  List<WorkItem> items;
  bool isExpanded;

  WorkList({
    required this.title,
    required this.items,
    this.isExpanded = false,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'isExpanded': isExpanded,
    'items': items.map((e) => e.toJson()).toList(),
  };

  factory WorkList.fromJson(Map<String, dynamic> json) => WorkList(
    title: json['title'],
    isExpanded: json['isExpanded'],
    items:
    (json['items'] as List).map((e) => WorkItem.fromJson(e)).toList(),
  );
}

class WorkItem {
  String name;
  bool isDone;

  WorkItem({required this.name, this.isDone = false});

  Map<String, dynamic> toJson() => {
    'name': name,
    'isDone': isDone,
  };

  factory WorkItem.fromJson(Map<String, dynamic> json) => WorkItem(
    name: json['name'],
    isDone: json['isDone'],
  );
}

/* ===================== HOME PAGE ===================== */

class WorkProgressTracker extends StatefulWidget {
  const WorkProgressTracker({super.key});

  @override
  State<WorkProgressTracker> createState() => _WorkProgressTrackerState();
}

class _WorkProgressTrackerState extends State<WorkProgressTracker> {
  List<WorkList> lists = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  /* ===================== STORAGE ===================== */

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('workData');
    if (data != null) {
      final decoded = jsonDecode(data) as List;
      lists = decoded.map((e) => WorkList.fromJson(e)).toList();
      setState(() {});
    }
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
      'workData',
      jsonEncode(lists.map((e) => e.toJson()).toList()),
    );
  }

  /* ===================== CALCULATIONS ===================== */

  double overallPercentage() {
    int total = 0,
        done = 0;
    for (var l in lists) {
      total += l.items.length;
      done += l.items
          .where((e) => e.isDone)
          .length;
    }
    return total == 0 ? 0 : (done / total) * 100;
  }

  double listPercentage(WorkList list) {
    final total = list.items.length;
    final done = list.items
        .where((e) => e.isDone)
        .length;
    return total == 0 ? 0 : (done / total) * 100;
  }

  /* ===================== CRUD ===================== */

  void addList() {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text("New Work List"),
            content: TextField(controller: c),
            actions: [
              TextButton(
                onPressed: () {
                  if (c.text.isNotEmpty) {
                    setState(() {
                      lists.add(WorkList(title: c.text, items: []));
                    });
                    saveData();
                    Navigator.pop(context);
                  }
                },
                child: const Text("Add"),
              )
            ],
          ),
    );
  }

  void addTask(int li) {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text("Add Task"),
            content: TextField(controller: c),
            actions: [
              TextButton(
                onPressed: () {
                  if (c.text.isNotEmpty) {
                    setState(() {
                      lists[li].items.add(WorkItem(name: c.text));
                    });
                    saveData();
                    Navigator.pop(context);
                  }
                },
                child: const Text("Add"),
              )
            ],
          ),
    );
  }

  void editList(int i) {
    final c = TextEditingController(text: lists[i].title);
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text("Edit List"),
            content: TextField(controller: c),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() => lists[i].title = c.text);
                  saveData();
                  Navigator.pop(context);
                },
                child: const Text("Save"),
              )
            ],
          ),
    );
  }

  void deleteList(int i) {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text("Delete List?"),
            content: const Text("This action cannot be undone."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel")),
              TextButton(
                onPressed: () {
                  setState(() => lists.removeAt(i));
                  saveData();
                  Navigator.pop(context);
                },
                child: const Text(
                    "Delete", style: TextStyle(color: Colors.red)),
              )
            ],
          ),
    );
  }

  void editTask(int li, int ti) {
    final c = TextEditingController(text: lists[li].items[ti].name);
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text("Edit Task"),
            content: TextField(controller: c),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() => lists[li].items[ti].name = c.text);
                  saveData();
                  Navigator.pop(context);
                },
                child: const Text("Save"),
              )
            ],
          ),
    );
  }

  void deleteTask(int li, int ti) {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text("Delete Task?"),
            content: const Text("Are you sure?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel")),
              TextButton(
                onPressed: () {
                  setState(() => lists[li].items.removeAt(ti));
                  saveData();
                  Navigator.pop(context);
                },
                child: const Text(
                    "Delete", style: TextStyle(color: Colors.red)),
              )
            ],
          ),
    );
  }

  /* ===================== UI ===================== */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Work Progress Tracker"),
        centerTitle: true,
      ),
      floatingActionButton:
      FloatingActionButton(onPressed: addList, child: const Icon(Icons.add)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Overall Progress",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("${overallPercentage().toStringAsFixed(1)}%",
                    style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: lists.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = lists.removeAt(oldIndex);
                  lists.insert(newIndex, item);
                });
                saveData();
              },
              itemBuilder: (context, index) {
                final list = lists[index];
                final listNo = index + 1;

                return Card(
                  key: ValueKey(list.title),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      onExpansionChanged: (v) {
                        setState(() => list.isExpanded = v);
                        saveData();
                      },
                      title: Text(
                        "$listNo. ${list.title}",
                        maxLines: list.isExpanded ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                          "Progress: ${listPercentage(list).toStringAsFixed(
                              1)}%"),
                      children: [
                        if (list.isExpanded)
                          const Divider(thickness: 2, color: Colors.black),
                        ...list.items
                            .asMap()
                            .entries
                            .map((e) {
                          final taskNo = e.key + 1;
                          final item = e.value;
                          return ListTile(
                            leading: Checkbox(
                              value: item.isDone,
                              onChanged: (v) {
                                setState(() => item.isDone = v!);
                                saveData();
                              },
                            ),
                            title: Text("$taskNo. ${item.name}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () =>
                                        editTask(index, e.key)),
                                IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        deleteTask(index, e.key)),
                              ],
                            ),
                          );
                        }),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                                onPressed: () => addTask(index),
                                icon: const Icon(Icons.add,
                                    color: Colors.green)),
                            Row(
                              children: [
                                IconButton(
                                    onPressed: () => editList(index),
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue)),
                                IconButton(
                                    onPressed: () => deleteList(index),
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red)),
                              ],
                            )
                          ],
                        ),
                        if (list.isExpanded)
                          const Divider(thickness: 2, color: Colors.black),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Add space from bottom
          const SizedBox(height: 65),
        ],
      ),
    );
  }
}