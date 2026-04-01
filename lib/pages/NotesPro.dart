import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ================= MODEL =================
class Todo {
  String id;
  String title;
  List<Todo> subTodos;
  String? parentId;
  List<String>? parentChain;
  bool isSubTask;
  bool isCompleted;
  DateTime createdAt;
  DateTime? updatedAt;
  DateTime? completedAt;
  int order;

  Todo({
    required this.id,
    required this.title,
    List<Todo>? subTodos,
    this.parentId,
    this.parentChain,
    this.isSubTask = false,
    this.isCompleted = false,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.order = 0,
  }) : subTodos = subTodos ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subTodos': subTodos.map((e) => e.toJson()).toList(),
    'parentId': parentId,
    'parentChain': parentChain,
    'isSubTask': isSubTask,
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'order': order,
  };

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'],
      subTodos: json['subTodos'] != null
          ? (json['subTodos'] as List)
          .map((e) => Todo.fromJson(e))
          .toList()
          : [],
      parentId: json['parentId'],
      parentChain: json['parentChain'] != null
          ? List<String>.from(json['parentChain'])
          : null,
      isSubTask: json['isSubTask'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      order: json['order'] ?? 0,
    );
  }
}

// ================= MAIN =================
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Nested Todo App',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         useMaterial3: true,
//       ),
//       home: const TodoScreen(),
//     );
//   }
// }

// ================= RECYCLE BIN SCREEN =================
class RecycleBinScreen extends StatefulWidget {
  final List<Todo> recycleBin;
  final Function(Todo) onRestore;
  final Function(Todo) onDeletePermanently;

  const RecycleBinScreen({
    super.key,
    required this.recycleBin,
    required this.onRestore,
    required this.onDeletePermanently,
  });

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  late List<Todo> localRecycleBin;

  @override
  void initState() {
    super.initState();
    localRecycleBin = List.from(widget.recycleBin);
  }

  @override
  void didUpdateWidget(RecycleBinScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recycleBin != widget.recycleBin) {
      setState(() {
        localRecycleBin = List.from(widget.recycleBin);
      });
    }
  }

  Future<void> _showRestoreConfirmDialog(BuildContext context, Todo todo) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Item'),
        content: Text('Are you sure you want to restore "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onRestore(todo);
              setState(() {
                localRecycleBin.remove(todo);
              });
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPermanentDeleteConfirmDialog(BuildContext context, Todo todo) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete'),
        content: Text('Are you sure you want to permanently delete "${todo.title}"?\n\nThis action cannot be undone!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              widget.onDeletePermanently(todo);
              setState(() {
                localRecycleBin.remove(todo);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Permanently deleted: ${todo.title}')),
              );
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin'),
        backgroundColor: Colors.grey[800],
        actions: [
          if (localRecycleBin.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Empty Recycle Bin'),
                    content: const Text('Are you sure you want to permanently delete all items?\n\nThis action cannot be undone!'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () {
                          for (var item in localRecycleBin.toList()) {
                            widget.onDeletePermanently(item);
                          }
                          setState(() {
                            localRecycleBin.clear();
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Recycle bin emptied')),
                          );
                        },
                        child: const Text('Delete All'),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Empty Recycle Bin',
            ),
        ],
      ),
      body: localRecycleBin.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Recycle bin is empty',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Deleted items will appear here',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: localRecycleBin.length,
        itemBuilder: (context, index) {
          final todo = localRecycleBin[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: Icon(
                todo.isSubTask ? Icons.subdirectory_arrow_right : Icons.checklist,
                color: Colors.grey[600],
              ),
              title: Text(
                todo.title,
                style: const TextStyle(fontSize: 16),
              ),
              subtitle: Text(
                'Deleted: ${_formatDate(todo.updatedAt ?? todo.createdAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.restore, color: Colors.green),
                    onPressed: () => _showRestoreConfirmDialog(context, todo),
                    tooltip: 'Restore',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () => _showPermanentDeleteConfirmDialog(context, todo),
                    tooltip: 'Delete Permanently',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

// ================= MAIN SCREEN WITH OPTIMIZED UI =================
class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<Todo> todos = [];
  List<Todo> recycleBin = [];

  String searchQuery = '';
  String filterType = 'All';
  String completionFilter = 'All';

  Set<String> selectedIds = {};
  bool isSelectionMode = false;

  // Drag and drop state
  Todo? dragTargetParent;

  // Expanded state tracking
  Map<String, bool> _expandedState = {};

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ================= STORAGE =================
  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('todos', jsonEncode(todos.map((e) => e.toJson()).toList()));
    await prefs.setString('bin', jsonEncode(recycleBin.map((e) => e.toJson()).toList()));
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final todoData = prefs.getString('todos');
    final binData = prefs.getString('bin');

    if (todoData != null) {
      todos = (jsonDecode(todoData) as List).map((e) => Todo.fromJson(e)).toList();
      todos.sort((a, b) => a.order.compareTo(b.order));
      _initializeExpandedState(todos);
    }

    if (binData != null) {
      recycleBin = (jsonDecode(binData) as List).map((e) => Todo.fromJson(e)).toList();
    }

    setState(() {});
  }

  void _initializeExpandedState(List<Todo> todoList) {
    for (var todo in todoList) {
      if (!_expandedState.containsKey(todo.id)) {
        _expandedState[todo.id] = false;
      }
      if (todo.subTodos.isNotEmpty) {
        _initializeExpandedState(todo.subTodos);
      }
    }
  }

  // ================= COMPLETION STATUS =================
  void toggleCompletion(Todo todo) {
    setState(() {
      todo.isCompleted = !todo.isCompleted;
      todo.updatedAt = DateTime.now();
      if (todo.isCompleted) {
        todo.completedAt = DateTime.now();
      } else {
        todo.completedAt = null;
      }
    });
    saveData();
  }

  void toggleAllSubtasks(Todo parent) {
    setState(() {
      bool allCompleted = parent.subTodos.every((sub) => sub.isCompleted);
      bool newStatus = !allCompleted;

      void updateSubtasks(List<Todo> subtasks) {
        for (var sub in subtasks) {
          sub.isCompleted = newStatus;
          sub.updatedAt = DateTime.now();
          sub.completedAt = newStatus ? DateTime.now() : null;
          updateSubtasks(sub.subTodos);
        }
      }

      updateSubtasks(parent.subTodos);

      if (newStatus) {
        parent.isCompleted = true;
        parent.completedAt = DateTime.now();
      } else {
        parent.isCompleted = false;
        parent.completedAt = null;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(newStatus ? 'Completed all subtasks' : 'Uncompleted all subtasks')),
      );
    });
    saveData();
  }

  // ================= SELECTION =================
  void toggleSelection(String id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else {
        selectedIds.add(id);
      }
      isSelectionMode = selectedIds.isNotEmpty;
    });
  }

  void selectAll() {
    Set<String> ids = {};
    void collectIds(List<Todo> todoList) {
      for (var t in todoList) {
        ids.add(t.id);
        collectIds(t.subTodos);
      }
    }
    collectIds(todos);
    setState(() {
      selectedIds = ids;
      isSelectionMode = true;
    });
  }

  void clearSelection() {
    setState(() {
      selectedIds.clear();
      isSelectionMode = false;
    });
  }

  void deleteSelectedWithUndo() {
    final List<Todo> deletedItems = [];
    final List<Map<String, dynamic>> parentInfo = [];

    void collectAndDelete(List<Todo> todoList, {Todo? parent, List<String>? parentChain}) {
      for (int i = todoList.length - 1; i >= 0; i--) {
        final t = todoList[i];
        if (selectedIds.contains(t.id)) {
          t.parentChain = parentChain != null ? List.from(parentChain) : [];
          if (parent != null) {
            t.parentChain!.add(parent.id);
          }
          deletedItems.add(t);
          parentInfo.add({'parent': parent, 'todo': t, 'index': i});
          t.updatedAt = DateTime.now();
          recycleBin.add(t);
          todoList.removeAt(i);
        } else {
          List<String> newParentChain = parentChain != null ? List.from(parentChain) : [];
          newParentChain.add(t.id);
          collectAndDelete(t.subTodos, parent: t, parentChain: newParentChain);
        }
      }
    }

    setState(() {
      collectAndDelete(todos);
      selectedIds.clear();
      isSelectionMode = false;
    });

    saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${deletedItems.length} item${deletedItems.length > 1 ? 's' : ''} moved to recycle bin'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              for (int i = 0; i < deletedItems.length; i++) {
                final item = deletedItems[i];
                final info = parentInfo[i];

                if (info['parent'] == null) {
                  todos.insert(info['index'], item);
                } else {
                  info['parent'].subTodos.insert(info['index'], item);
                  for (int j = 0; j < info['parent'].subTodos.length; j++) {
                    info['parent'].subTodos[j].order = j;
                  }
                }
                recycleBin.remove(item);
              }
            });
            saveData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Undo successful')),
            );
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // ================= HELPER FUNCTIONS =================
  Todo? findParentById(String parentId) {
    return _findParentById(parentId, todos);
  }

  Todo? _findParentById(String parentId, List<Todo> todoList) {
    for (var todo in todoList) {
      if (todo.id == parentId) return todo;
      final found = _findParentById(parentId, todo.subTodos);
      if (found != null) return found;
    }
    return null;
  }

  Todo? findParentOfTodo(Todo todo) {
    return _findParentOfTodo(todo, todos);
  }

  Todo? _findParentOfTodo(Todo todo, List<Todo> todoList) {
    for (var item in todoList) {
      if (item.subTodos.contains(todo)) {
        return item;
      }
      final found = _findParentOfTodo(todo, item.subTodos);
      if (found != null) return found;
    }
    return null;
  }

  Todo? findNearestExistingParentFromChain(List<String>? parentChain) {
    if (parentChain == null || parentChain.isEmpty) return null;

    for (int i = parentChain.length - 1; i >= 0; i--) {
      String parentId = parentChain[i];
      Todo? parent = findParentById(parentId);
      if (parent != null) {
        return parent;
      }
    }
    return null;
  }

  bool _removeTodoFromList(Todo todo, List<Todo> todoList) {
    for (int i = 0; i < todoList.length; i++) {
      if (todoList[i].id == todo.id) {
        todoList.removeAt(i);
        return true;
      }
      if (_removeTodoFromList(todo, todoList[i].subTodos)) {
        return true;
      }
    }
    return false;
  }

  void _updateOrders(List<Todo> todoList) {
    for (int i = 0; i < todoList.length; i++) {
      todoList[i].order = i;
      _updateOrders(todoList[i].subTodos);
    }
  }

  void _expandAllParents(Todo todo) {
    _expandedState[todo.id] = true;
    if (todo.parentId != null) {
      Todo? parent = findParentById(todo.parentId!);
      if (parent != null) {
        _expandAllParents(parent);
      }
    }
  }

  bool isCircularReference(Todo source, Todo target) {
    if (target.parentId == source.id) {
      return true;
    }
    for (var sub in target.subTodos) {
      if (isCircularReference(source, sub)) {
        return true;
      }
    }
    return false;
  }

  // ================= DRAG & DROP OPERATIONS =================
  void handleMainTodoToSubTask(Todo dragged, Todo target) {
    if (dragged.id == target.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot drop onto itself')),
      );
      return;
    }

    if (isCircularReference(dragged, target)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot create circular reference')),
      );
      return;
    }

    setState(() {
      _removeTodoFromList(dragged, todos);

      dragged.isSubTask = true;
      dragged.parentId = target.id;
      dragged.order = target.subTodos.length;
      target.subTodos.add(dragged);

      _updateOrders(todos);
      _expandAllParents(target);
    });

    saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Moved "${dragged.title}" to "${target.title}"')),
    );
  }

  void handleSubTaskToAnotherParent(Todo dragged, Todo newParent, {int? position}) {
    if (dragged.parentId == newParent.id) return;

    if (isCircularReference(dragged, newParent)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot create circular reference')),
      );
      return;
    }

    setState(() {
      _removeTodoFromList(dragged, todos);

      dragged.parentId = newParent.id;

      if (position != null && position <= newParent.subTodos.length) {
        newParent.subTodos.insert(position, dragged);
      } else {
        newParent.subTodos.add(dragged);
      }

      for (int i = 0; i < newParent.subTodos.length; i++) {
        newParent.subTodos[i].order = i;
      }

      _expandAllParents(newParent);
    });

    saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Moved "${dragged.title}" to "${newParent.title}"')),
    );
  }

  void handleSubTaskToMainList(Todo dragged, int index) {
    setState(() {
      _removeTodoFromList(dragged, todos);

      dragged.isSubTask = false;
      dragged.parentId = null;
      dragged.order = todos.length;

      if (index < todos.length) {
        todos.insert(index, dragged);
      } else {
        todos.add(dragged);
      }

      _updateOrders(todos);
      _expandedState[dragged.id] = false;
    });

    saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Moved "${dragged.title}" to main list')),
    );
  }

  void handleMainListReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = todos.removeAt(oldIndex);
      todos.insert(newIndex, item);
      _updateOrders(todos);
    });
    saveData();
  }

  void handleSubTaskReorder(Todo parent, int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = parent.subTodos.removeAt(oldIndex);
      parent.subTodos.insert(newIndex, item);
      for (int i = 0; i < parent.subTodos.length; i++) {
        parent.subTodos[i].order = i;
      }
    });
    saveData();
  }

  // ================= CRUD OPERATIONS =================
  void addTodo() {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Todo'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter todo title',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (c.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a title')),
                );
                return;
              }
              setState(() {
                final newTodo = Todo(
                  id: DateTime.now().toString(),
                  title: c.text,
                  createdAt: DateTime.now(),
                  order: todos.length,
                  subTodos: [],
                );
                todos.add(newTodo);
                _expandedState[newTodo.id] = false;
              });
              saveData();
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void addSubTodo(Todo parent) {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Sub Task'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter sub task title',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (c.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a title')),
                );
                return;
              }

              setState(() {
                parent.subTodos.add(Todo(
                  id: DateTime.now().toString(),
                  title: c.text,
                  parentId: parent.id,
                  isSubTask: true,
                  createdAt: DateTime.now(),
                  order: parent.subTodos.length,
                  subTodos: [],
                ));
                _expandedState[parent.id] = true;
              });
              saveData();
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Subtask added: ${c.text}')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void editTodo(Todo todo) {
    final c = TextEditingController(text: todo.title);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(todo.isSubTask ? 'Edit Sub Task' : 'Edit Todo'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter new title',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (c.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a title')),
                );
                return;
              }
              setState(() {
                todo.title = c.text;
                todo.updatedAt = DateTime.now();
              });
              saveData();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmDialog(Todo todo) async {
    List<String> parentChain = [];
    Todo? currentParent = findParentOfTodo(todo);
    while (currentParent != null) {
      parentChain.insert(0, currentParent.id);
      currentParent = findParentOfTodo(currentParent);
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${todo.title}"?\n\nIt will be moved to recycle bin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);

              final parent = findParentOfTodo(todo);

              setState(() {
                todo.updatedAt = DateTime.now();
                todo.parentChain = parentChain;
                recycleBin.add(todo);

                if (parent != null) {
                  parent.subTodos.remove(todo);
                  for (int i = 0; i < parent.subTodos.length; i++) {
                    parent.subTodos[i].order = i;
                  }
                } else {
                  todos.remove(todo);
                  for (int i = 0; i < todos.length; i++) {
                    todos[i].order = i;
                  }
                }
              });

              saveData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted: ${todo.title}')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void deleteTodo(Todo todo) {
    _showDeleteConfirmDialog(todo);
  }

  void restoreFromBin(Todo todo) {
    setState(() {
      if (todo.isSubTask && todo.parentChain != null && todo.parentChain!.isNotEmpty) {
        Todo? nearestParent = findNearestExistingParentFromChain(todo.parentChain);

        if (nearestParent != null) {
          todo.parentId = nearestParent.id;
          nearestParent.subTodos.add(todo);
          nearestParent.subTodos.sort((a, b) => a.order.compareTo(b.order));
          _expandAllParents(nearestParent);

          if (todo.parentChain!.last == nearestParent.id) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Restored: ${todo.title} under original parent')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Restored "${todo.title}" under "${nearestParent.title}" (original parent deleted)')),
            );
          }
        } else {
          todo.isSubTask = false;
          todo.parentId = null;
          todos.add(todo);
          _expandedState[todo.id] = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Parent chain deleted, restored "${todo.title}" as main task')),
          );
        }
      } else {
        todos.add(todo);
        _expandedState[todo.id] = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restored: ${todo.title}')),
        );
      }
      recycleBin.remove(todo);
      todos.sort((a, b) => a.order.compareTo(b.order));
    });
    saveData();
  }

  void permanentlyDelete(Todo todo) {
    setState(() {
      recycleBin.remove(todo);
    });
    saveData();
  }

  // ================= FILTER & SEARCH =================
  List<Todo> get filteredTodos {
    return todos.where((todo) => _matchesFilter(todo)).toList();
  }

  bool _matchesFilter(Todo todo) {
    if (filterType == 'With Subtasks' && todo.subTodos.isEmpty) return false;
    if (filterType == 'Without Subtasks' && todo.subTodos.isNotEmpty) return false;

    if (completionFilter == 'Completed' && !todo.isCompleted) return false;
    if (completionFilter == 'Pending' && todo.isCompleted) return false;

    if (searchQuery.isNotEmpty) {
      bool matches = todo.title.toLowerCase().contains(searchQuery.toLowerCase());
      if (!matches) {
        matches = _searchSubtasks(todo.subTodos);
      }
      return matches;
    }

    return true;
  }

  bool _searchSubtasks(List<Todo> subtasks) {
    for (var sub in subtasks) {
      if (sub.title.toLowerCase().contains(searchQuery.toLowerCase())) {
        return true;
      }
      if (_searchSubtasks(sub.subTodos)) {
        return true;
      }
    }
    return false;
  }

  // ================= UI BUILDERS =================
  Widget buildTodoItem(Todo todo, int level) {
    if (!_expandedState.containsKey(todo.id)) {
      _expandedState[todo.id] = false;
    }

    bool isDragTarget = dragTargetParent == todo;

    return Container(
      margin: EdgeInsets.only(left: level * 12.0, right: 4, top: 2, bottom: 2),
      child: Card(
        color: isDragTarget ? Colors.blue[50] : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              leading: isSelectionMode
                  ? Checkbox(
                value: selectedIds.contains(todo.id),
                onChanged: (_) => toggleSelection(todo.id),
                visualDensity: VisualDensity.compact,
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: todo.isCompleted,
                    onChanged: (_) => toggleCompletion(todo),
                    activeColor: Colors.green,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Icon(
                    Icons.drag_handle,
                    color: Colors.grey[400],
                    size: 14,
                  ),
                ],
              ),
              title: Text(
                todo.title,
                style: TextStyle(
                  decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.grey,
                  decorationThickness: 2,
                  fontWeight: level == 0 ? FontWeight.w500 : FontWeight.normal,
                  fontSize: level == 0 ? 13 : 11,
                  color: todo.isCompleted ? Colors.grey : null,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              trailing: isSelectionMode
                  ? null
                  : Wrap(
                spacing: 0,
                runSpacing: 0,
                alignment: WrapAlignment.end,
                children: [
                  if (todo.subTodos.isNotEmpty)
                    InkWell(
                      onTap: () => toggleAllSubtasks(todo),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.done_all,
                          size: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 16),
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      switch (value) {
                        case 'add':
                          addSubTodo(todo);
                          break;
                        case 'edit':
                          editTodo(todo);
                          break;
                        case 'delete':
                          deleteTodo(todo);
                          break;
                        case 'expand':
                          setState(() {
                            _expandedState[todo.id] = !(_expandedState[todo.id] ?? false);
                          });
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'add',
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 18),
                            SizedBox(width: 8),
                            Text('Add Subtask'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      if (todo.subTodos.isNotEmpty)
                        PopupMenuItem(
                          value: 'expand',
                          child: Row(
                            children: [
                              Icon(
                                _expandedState[todo.id] == true
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(_expandedState[todo.id] == true ? 'Collapse' : 'Expand'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () {
                if (!isSelectionMode) {
                  toggleCompletion(todo);
                }
              },
            ),
            if (_expandedState[todo.id] == true && todo.subTodos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildSubTasksList(todo.subTodos, level + 1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSubTasksList(List<Todo> subtasks, int level) {
    List<Widget> widgets = [];
    for (int i = 0; i < subtasks.length; i++) {
      final subtask = subtasks[i];

      widgets.add(
        Container(
          key: ValueKey('subtask_${subtask.id}_$i'),
          child: Draggable<Todo>(
            data: subtask,
            feedback: Material(
              elevation: 4,
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width - 80 - (level * 12),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: subtask.isCompleted ? Colors.green[50] : Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(subtask.isCompleted ? Icons.check_circle : Icons.subdirectory_arrow_right,
                        color: subtask.isCompleted ? Colors.green : Colors.green, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        subtask.title,
                        style: TextStyle(
                          fontSize: 11,
                          decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const Icon(Icons.drag_handle, size: 14),
                  ],
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.5,
              child: buildTodoItem(subtask, level),
            ),
            onDragEnd: (details) {
              setState(() {
                dragTargetParent = null;
              });
            },
            child: DragTarget<Todo>(
              onAccept: (dragged) {
                if (dragged.isSubTask) {
                  handleSubTaskToAnotherParent(dragged, subtask);
                } else if (!dragged.isSubTask) {
                  handleMainTodoToSubTask(dragged, subtask);
                }
                setState(() {
                  dragTargetParent = null;
                });
              },
              onWillAccept: (dragged) {
                if (dragged != null && dragged.id != subtask.id) {
                  setState(() {
                    dragTargetParent = subtask;
                  });
                  return true;
                }
                return false;
              },
              onLeave: (dragged) {
                setState(() {
                  dragTargetParent = null;
                });
              },
              builder: (context, candidateData, rejectedData) {
                return buildTodoItem(subtask, level);
              },
            ),
          ),
        ),
      );

      if (i < subtasks.length - 1) {
        widgets.add(const SizedBox(height: 2));
      }
    }
    return widgets;
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSelectionMode
            ? Text('${selectedIds.length} selected')
            : const Text('Notes Pro'),
        actions: [
          if (!isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecycleBinScreen(
                      recycleBin: recycleBin,
                      onRestore: restoreFromBin,
                      onDeletePermanently: permanentlyDelete,
                    ),
                  ),
                ).then((_) {
                  setState(() {});
                });
              },
              tooltip: 'Recycle Bin',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              onSelected: (value) {
                setState(() {
                  filterType = value;
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'All',
                  child: Text('All Tasks'),
                ),
                const PopupMenuItem(
                  value: 'With Subtasks',
                  child: Text('With Subtasks'),
                ),
                const PopupMenuItem(
                  value: 'Without Subtasks',
                  child: Text('Without Subtasks'),
                ),
              ],
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.check_circle_outline),
              onSelected: (value) {
                setState(() {
                  completionFilter = value;
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'All',
                  child: Text('All Tasks'),
                ),
                const PopupMenuItem(
                  value: 'Completed',
                  child: Text('Completed'),
                ),
                const PopupMenuItem(
                  value: 'Pending',
                  child: Text('Pending'),
                ),
              ],
            ),
          ],
          if (isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: selectAll,
              tooltip: 'Select All',
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: clearSelection,
              tooltip: 'Clear Selection',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: deleteSelectedWithUndo,
              tooltip: 'Delete Selected',
            ),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: DragTarget<Todo>(
        onAccept: (dragged) {
          if (dragged.isSubTask) {
            handleSubTaskToMainList(dragged, todos.length);
          }
          setState(() {
            dragTargetParent = null;
          });
        },
        onWillAccept: (dragged) {
          return dragged != null;
        },
        builder: (context, candidateData, rejectedData) {
          final filtered = filteredTodos;
          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    searchQuery.isNotEmpty ? Icons.search_off : Icons.checklist,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    searchQuery.isNotEmpty
                        ? 'No results found for "$searchQuery"'
                        : todos.isEmpty
                        ? 'No todos yet'
                        : 'No tasks match the filter',
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                  if (todos.isEmpty && searchQuery.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Tap the + button to add your first todo',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            );
          }

          return ReorderableListView.builder(
            onReorder: handleMainListReorder,
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final todo = filtered[index];
              return Container(
                key: ValueKey('main_${todo.id}_$index'),
                child: Draggable<Todo>(
                  data: todo,
                  feedback: Material(
                    elevation: 4,
                    color: Colors.transparent,
                    child: Container(
                      width: MediaQuery.of(context).size.width - 32,
                      padding: const EdgeInsets.all(6),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: todo.isCompleted ? Colors.green[50] : Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(todo.isCompleted ? Icons.check_circle : Icons.drag_handle,
                              color: todo.isCompleted ? Colors.green : Colors.blue, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              todo.title,
                              style: TextStyle(
                                decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: buildTodoItem(todo, 0),
                  ),
                  onDragEnd: (details) {
                    setState(() {
                      dragTargetParent = null;
                    });
                  },
                  child: DragTarget<Todo>(
                    onAccept: (dragged) {
                      if (dragged.isSubTask) {
                        handleSubTaskToAnotherParent(dragged, todo);
                      } else if (!dragged.isSubTask && dragged.id != todo.id) {
                        handleMainTodoToSubTask(dragged, todo);
                      }
                      setState(() {
                        dragTargetParent = null;
                      });
                    },
                    onWillAccept: (dragged) {
                      if (dragged != null && dragged.id != todo.id) {
                        setState(() {
                          dragTargetParent = todo;
                        });
                        return true;
                      }
                      return false;
                    },
                    onLeave: (dragged) {
                      setState(() {
                        dragTargetParent = null;
                      });
                    },
                    builder: (context, candidateData, rejectedData) {
                      return buildTodoItem(todo, 0);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isSelectionMode
          ? null
          : FloatingActionButton(
        onPressed: addTodo,
        child: const Icon(Icons.add),
        tooltip: 'Add Todo',
      ),
    );
  }
}