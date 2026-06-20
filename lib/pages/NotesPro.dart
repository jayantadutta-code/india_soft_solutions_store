import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

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

// ================= ENTRY POINT =================
// ================= MAIN SCREEN WITH BOTTOM NAV =================
class NotesPro extends StatefulWidget {
  const NotesPro({super.key});

  @override
  State<NotesPro> createState() => _NotesProState();
}

class _NotesProState extends State<NotesPro> {
  List<Todo> todos = [];
  List<Todo> recycleBin = [];

  String filterType = 'All';
  String completionFilter = 'All';

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

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
    }

    if (binData != null) {
      recycleBin = (jsonDecode(binData) as List).map((e) => Todo.fromJson(e)).toList();
    }

    setState(() {});
  }

  // ================= CRUD OPERATIONS =================
  void addTodo(String title) {
    setState(() {
      final newTodo = Todo(
        id: DateTime.now().toString(),
        title: title,
        createdAt: DateTime.now(),
        order: todos.length,
        subTodos: [],
      );
      todos.add(newTodo);
    });
    saveData();
  }

  void addSubTodo(Todo parent, String title) {
    setState(() {
      parent.subTodos.add(Todo(
        id: DateTime.now().toString(),
        title: title,
        parentId: parent.id,
        isSubTask: true,
        createdAt: DateTime.now(),
        order: parent.subTodos.length,
        subTodos: [],
      ));
    });
    saveData();
  }

  void editTodo(Todo todo, String newTitle) {
    setState(() {
      todo.title = newTitle;
      todo.updatedAt = DateTime.now();
    });
    saveData();
  }

  void deleteTodo(Todo todo) {
    setState(() {
      todo.updatedAt = DateTime.now();
      final parent = findParentOfTodo(todo);
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
      recycleBin.add(todo);
    });
    saveData();
  }

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
    });
    saveData();
  }

  // ================= RESTORE LOGIC (PRESERVES ORIGINAL POSITION) =================
  void restoreFromBin(Todo todo) {
    setState(() {
      if (todo.isSubTask && todo.parentChain != null && todo.parentChain!.isNotEmpty) {
        Todo? nearestParent = findNearestExistingParentFromChain(todo.parentChain);
        if (nearestParent != null) {
          todo.parentId = nearestParent.id;
          int insertIndex = todo.order.clamp(0, nearestParent.subTodos.length);
          nearestParent.subTodos.insert(insertIndex, todo);
          _updateOrders(nearestParent.subTodos);
        } else {
          todo.isSubTask = false;
          todo.parentId = null;
          int insertIndex = todo.order.clamp(0, todos.length);
          todos.insert(insertIndex, todo);
          _updateOrders(todos);
        }
      } else {
        int insertIndex = todo.order.clamp(0, todos.length);
        todos.insert(insertIndex, todo);
        _updateOrders(todos);
      }
      recycleBin.remove(todo);
    });
    saveData();
  }

  void restoreAllFromBin() {
    if (recycleBin.isEmpty) return;
    setState(() {
      List<Todo> itemsToRestore = List.from(recycleBin);
      itemsToRestore.sort((a, b) => a.order.compareTo(b.order));
      for (var todo in itemsToRestore) {
        if (todo.isSubTask && todo.parentChain != null && todo.parentChain!.isNotEmpty) {
          Todo? nearestParent = findNearestExistingParentFromChain(todo.parentChain);
          if (nearestParent != null) {
            todo.parentId = nearestParent.id;
            int insertIndex = todo.order.clamp(0, nearestParent.subTodos.length);
            nearestParent.subTodos.insert(insertIndex, todo);
            _updateOrders(nearestParent.subTodos);
          } else {
            todo.isSubTask = false;
            todo.parentId = null;
            int insertIndex = todo.order.clamp(0, todos.length);
            todos.insert(insertIndex, todo);
            _updateOrders(todos);
          }
        } else {
          int insertIndex = todo.order.clamp(0, todos.length);
          todos.insert(insertIndex, todo);
          _updateOrders(todos);
        }
        recycleBin.remove(todo);
      }
    });
    saveData();
  }

  void permanentlyDelete(Todo todo) {
    setState(() {
      recycleBin.remove(todo);
    });
    saveData();
  }

  void emptyBin() {
    setState(() {
      recycleBin.clear();
    });
    saveData();
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
      if (parent != null) return parent;
    }
    return null;
  }

  void _updateOrders(List<Todo> todoList) {
    for (int i = 0; i < todoList.length; i++) {
      todoList[i].order = i;
      _updateOrders(todoList[i].subTodos);
    }
  }

  bool isCircularReference(Todo source, Todo target) {
    if (target.parentId == source.id) return true;
    for (var sub in target.subTodos) {
      if (isCircularReference(source, sub)) return true;
    }
    return false;
  }

  // ================= DRAG & DROP =================
  void handleMainListReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final item = todos.removeAt(oldIndex);
      todos.insert(newIndex, item);
      _updateOrders(todos);
    });
    saveData();
  }

  void handleSubTaskReorderWithinParent(Todo dragged, Todo target) {
    if (!dragged.isSubTask || !target.isSubTask || dragged.parentId != target.parentId) return;
    final parent = findParentById(dragged.parentId!);
    if (parent == null) return;
    setState(() {
      int oldIndex = parent.subTodos.indexWhere((t) => t.id == dragged.id);
      int newIndex = parent.subTodos.indexWhere((t) => t.id == target.id);
      if (oldIndex == -1 || newIndex == -1) return;
      parent.subTodos.removeAt(oldIndex);
      if (oldIndex < newIndex) newIndex -= 1;
      parent.subTodos.insert(newIndex, dragged);
      _updateOrders(parent.subTodos);
    });
    saveData();
  }

  // ================= SELECTION =================
  void deleteSelected(List<String> selectedIds) {
    final List<Todo> deletedItems = [];
    void collectAndDelete(List<Todo> todoList, {Todo? parent}) {
      for (int i = todoList.length - 1; i >= 0; i--) {
        final t = todoList[i];
        if (selectedIds.contains(t.id)) {
          deletedItems.add(t);
          t.updatedAt = DateTime.now();
          recycleBin.add(t);
          todoList.removeAt(i);
        } else {
          collectAndDelete(t.subTodos, parent: t);
        }
      }
    }
    setState(() {
      collectAndDelete(todos);
      _updateOrders(todos);
    });
    saveData();
  }

  // ================= NAVIGATION =================
  void _onNavItemTapped(int index) {
    if (index == 1) {
      _showAddDialog();
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  void _showAddDialog() {
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
              addTodo(c.text);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(
            key: ValueKey('home_${filterType}_$completionFilter'),
            todos: todos,
            filterType: filterType,
            completionFilter: completionFilter,
            onToggleCompletion: toggleCompletion,
            onToggleAllSubtasks: toggleAllSubtasks,
            onEditTodo: editTodo,
            onDeleteTodo: deleteTodo,
            onAddSubTodo: addSubTodo,
            onMainListReorder: handleMainListReorder,
            onSubTaskReorder: handleSubTaskReorderWithinParent,
            onDeleteSelected: deleteSelected,
            saveData: saveData,
          ),
          Container(), // Add is handled separately (dialog)
          RecycleBinPage(
            key: const ValueKey('recycle_bin'),
            recycleBin: recycleBin,
            onRestore: restoreFromBin,
            onDeletePermanently: permanentlyDelete,
            onRestoreAll: restoreAllFromBin,
            onEmptyBin: emptyBin,
          ),
          FilterPage(
            key: ValueKey('filter_${filterType}_$completionFilter'),
            currentFilter: filterType,
            currentStatus: completionFilter,
            onFilterChanged: (value) {
              if (value != null) {
                setState(() {
                  filterType = value;
                });
              }
            },
            onStatusChanged: (value) {
              if (value != null) {
                setState(() {
                  completionFilter = value;
                });
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: CurvedNavigationBar(
          key: GlobalKey<CurvedNavigationBarState>(),
          index: _currentIndex,
          height: 70,
          items: const [
            Icon(Icons.home, size: 30, color: Colors.white),
            Icon(Icons.add, size: 30, color: Colors.white),
            Icon(Icons.delete_outline, size: 30, color: Colors.white),
            Icon(Icons.filter_list, size: 30, color: Colors.white),
          ],
          color: Colors.blue[700]!,
          buttonBackgroundColor: Colors.blue[700]!,
          backgroundColor: Colors.transparent,
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 300),
          onTap: _onNavItemTapped,
          letIndexChange: (index) => true,
        ),
      ),
    );
  }
}

// ================= HOME PAGE =================
class HomePage extends StatefulWidget {
  final List<Todo> todos;
  final String filterType;
  final String completionFilter;
  final Function(Todo) onToggleCompletion;
  final Function(Todo) onToggleAllSubtasks;
  final Function(Todo, String) onEditTodo;
  final Function(Todo) onDeleteTodo;
  final Function(Todo, String) onAddSubTodo;
  final Function(int, int) onMainListReorder;
  final Function(Todo, Todo) onSubTaskReorder;
  final Function(List<String>) onDeleteSelected;
  final VoidCallback saveData;

  const HomePage({
    super.key,
    required this.todos,
    required this.filterType,
    required this.completionFilter,
    required this.onToggleCompletion,
    required this.onToggleAllSubtasks,
    required this.onEditTodo,
    required this.onDeleteTodo,
    required this.onAddSubTodo,
    required this.onMainListReorder,
    required this.onSubTaskReorder,
    required this.onDeleteSelected,
    required this.saveData,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String searchQuery = '';
  Set<String> selectedIds = {};
  bool isSelectionMode = false;
  Todo? dragTargetParent;
  Map<String, bool> _expandedState = {};

  @override
  void initState() {
    super.initState();
    _initializeExpandedState(widget.todos);
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.todos != widget.todos) {
      _initializeExpandedState(widget.todos);
    }
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

  List<Todo> get filteredTodos {
    return widget.todos.where((todo) => _matchesFilter(todo)).toList();
  }

  bool _matchesFilter(Todo todo) {
    if (widget.filterType == 'With Subtasks' && todo.subTodos.isEmpty) return false;
    if (widget.filterType == 'Without Subtasks' && todo.subTodos.isNotEmpty) return false;
    if (widget.completionFilter == 'Completed' && !todo.isCompleted) return false;
    if (widget.completionFilter == 'Pending' && todo.isCompleted) return false;
    if (searchQuery.isNotEmpty) {
      bool matches = todo.title.toLowerCase().contains(searchQuery.toLowerCase());
      if (!matches) matches = _searchSubtasks(todo.subTodos);
      return matches;
    }
    return true;
  }

  bool _searchSubtasks(List<Todo> subtasks) {
    for (var sub in subtasks) {
      if (sub.title.toLowerCase().contains(searchQuery.toLowerCase())) return true;
      if (_searchSubtasks(sub.subTodos)) return true;
    }
    return false;
  }

  void _toggleSelection(String id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else {
        selectedIds.add(id);
      }
      isSelectionMode = selectedIds.isNotEmpty;
    });
  }

  void _selectAll() {
    Set<String> ids = {};
    void collectIds(List<Todo> todoList) {
      for (var t in todoList) {
        ids.add(t.id);
        collectIds(t.subTodos);
      }
    }
    collectIds(filteredTodos);
    setState(() {
      selectedIds = ids;
      isSelectionMode = true;
    });
  }

  void _clearSelection() {
    setState(() {
      selectedIds.clear();
      isSelectionMode = false;
    });
  }

  void _deleteSelected() {
    if (selectedIds.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Selected'),
        content: Text('Are you sure you want to delete ${selectedIds.length} item(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              widget.onDeleteSelected(selectedIds.toList());
              setState(() {
                selectedIds.clear();
                isSelectionMode = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ================= BUILD TODO ITEM =================
  Widget buildTodoItem(Todo todo, int level) {
    if (!_expandedState.containsKey(todo.id)) _expandedState[todo.id] = false;
    bool isDragTarget = dragTargetParent == todo;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Card(
        color: isDragTarget ? Colors.blue[50] : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 1,
        child: Padding(
          padding: EdgeInsets.only(left: level * 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                leading: isSelectionMode
                    ? Checkbox(
                  value: selectedIds.contains(todo.id),
                  onChanged: (_) => _toggleSelection(todo.id),
                  visualDensity: VisualDensity.compact,
                )
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: todo.isCompleted,
                      onChanged: (_) => widget.onToggleCompletion(todo),
                      activeColor: Colors.green,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Icon(Icons.drag_handle, color: Colors.grey[400], size: 14),
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
                        onTap: () => widget.onToggleAllSubtasks(todo),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(Icons.done_all, size: 16, color: Colors.blue),
                        ),
                      ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 16),
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        switch (value) {
                          case 'add':
                            _showAddSubTodoDialog(todo);
                            break;
                          case 'edit':
                            _showEditTodoDialog(todo);
                            break;
                          case 'delete':
                            _showDeleteConfirmDialog(todo);
                            break;
                          case 'expand':
                            setState(() {
                              _expandedState[todo.id] = !(_expandedState[todo.id] ?? false);
                            });
                            break;
                        }
                      },
                      itemBuilder: (context) {
                        List<PopupMenuItem<String>> menuItems = [];
                        if (level < 3) {
                          menuItems.add(
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
                          );
                        }
                        menuItems.add(
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
                        );
                        if (todo.subTodos.isNotEmpty) {
                          menuItems.add(
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
                          );
                        }
                        menuItems.add(
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
                        );
                        return menuItems;
                      },
                    ),
                  ],
                ),
                onTap: () {
                  if (!isSelectionMode) widget.onToggleCompletion(todo);
                },
              ),
              if (_expandedState[todo.id] == true && todo.subTodos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _buildSubTasksList(todo.subTodos, level + 1),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
                width: MediaQuery.of(context).size.width - 16,
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
            childWhenDragging: Opacity(opacity: 0.5, child: buildTodoItem(subtask, level)),
            onDragEnd: (details) {
              setState(() {
                dragTargetParent = null;
              });
            },
            child: DragTarget<Todo>(
              onAccept: (dragged) {
                if (dragged.isSubTask && subtask.isSubTask && dragged.parentId == subtask.parentId) {
                  widget.onSubTaskReorder(dragged, subtask);
                }
                setState(() {
                  dragTargetParent = null;
                });
              },
              onWillAccept: (dragged) {
                if (dragged != null &&
                    dragged.id != subtask.id &&
                    dragged.isSubTask &&
                    subtask.isSubTask &&
                    dragged.parentId == subtask.parentId) {
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
      if (i < subtasks.length - 1) widgets.add(const SizedBox(height: 2));
    }
    return widgets;
  }

  void _showAddSubTodoDialog(Todo parent) {
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
              widget.onAddSubTodo(parent, c.text);
              setState(() {
                _expandedState[parent.id] = true;
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditTodoDialog(Todo todo) {
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
              widget.onEditTodo(todo, c.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ★ Store parentChain before deleting a subtask ★
  void _showDeleteConfirmDialog(Todo todo) {
    List<String> parentChain = [];
    Todo? currentParent = _findParentOfTodo(todo);
    while (currentParent != null) {
      parentChain.insert(0, currentParent.id);
      currentParent = _findParentOfTodo(currentParent);
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              todo.parentChain = parentChain.isNotEmpty ? parentChain : null;
              widget.onDeleteTodo(todo);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Todo? _findParentOfTodo(Todo todo) {
    return _findParentOfTodoRecursive(todo, widget.todos);
  }

  Todo? _findParentOfTodoRecursive(Todo todo, List<Todo> todoList) {
    for (var item in todoList) {
      if (item.subTodos.contains(todo)) {
        return item;
      }
      final found = _findParentOfTodoRecursive(todo, item.subTodos);
      if (found != null) return found;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSelectionMode
            ? Text('${selectedIds.length} selected')
            : const Text('My Tasks'),
        actions: [
          if (isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAll,
              tooltip: 'Select All',
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSelection,
              tooltip: 'Clear Selection',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelected,
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
      body: Builder(
        builder: (context) {
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
                        : widget.todos.isEmpty
                        ? 'No todos yet'
                        : 'No tasks match the filter',
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                  if (widget.todos.isEmpty && searchQuery.isEmpty) ...[
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
            onReorder: widget.onMainListReorder,
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final todo = filtered[index];
              return Container(
                key: ValueKey('main_${todo.id}_$index'),
                child: buildTodoItem(todo, 0),
              );
            },
          );
        },
      ),
    );
  }
}

// ================= RECYCLE BIN PAGE =================
class RecycleBinPage extends StatefulWidget {
  final List<Todo> recycleBin;
  final Function(Todo) onRestore;
  final Function(Todo) onDeletePermanently;
  final VoidCallback onRestoreAll;
  final VoidCallback onEmptyBin;

  const RecycleBinPage({
    super.key,
    required this.recycleBin,
    required this.onRestore,
    required this.onDeletePermanently,
    required this.onRestoreAll,
    required this.onEmptyBin,
  });

  @override
  State<RecycleBinPage> createState() => _RecycleBinPageState();
}

class _RecycleBinPageState extends State<RecycleBinPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin'),
        backgroundColor: Colors.grey[800],
        actions: [
          if (widget.recycleBin.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.restore, color: Colors.white),
              onPressed: widget.onRestoreAll,
              tooltip: 'Restore All',
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              onPressed: widget.onEmptyBin,
              tooltip: 'Empty Recycle Bin',
            ),
          ],
        ],
      ),
      body: widget.recycleBin.isEmpty
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
          ],
        ),
      )
          : ListView.builder(
        itemCount: widget.recycleBin.length,
        itemBuilder: (context, index) {
          final todo = widget.recycleBin[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: Icon(
                todo.isSubTask ? Icons.subdirectory_arrow_right : Icons.checklist,
                color: Colors.grey[600],
              ),
              title: Text(
                todo.title,
                style: TextStyle(
                  decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                ),
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
                    onPressed: () => widget.onRestore(todo),
                    tooltip: 'Restore',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () => widget.onDeletePermanently(todo),
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

// ================= FILTER PAGE =================
class FilterPage extends StatefulWidget {
  final String currentFilter;
  final String currentStatus;
  final ValueChanged<String?> onFilterChanged;
  final ValueChanged<String?> onStatusChanged;

  const FilterPage({
    super.key,
    required this.currentFilter,
    required this.currentStatus,
    required this.onFilterChanged,
    required this.onStatusChanged,
  });

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  late String _filter;
  late String _status;

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
    _status = widget.currentStatus;
  }

  @override
  void didUpdateWidget(FilterPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentFilter != oldWidget.currentFilter) {
      setState(() {
        _filter = widget.currentFilter;
      });
    }
    if (widget.currentStatus != oldWidget.currentStatus) {
      setState(() {
        _status = widget.currentStatus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter & Status'),
        backgroundColor: Colors.blue[700],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Filter by Subtasks',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildRadioTile(
            title: 'All Tasks',
            value: 'All',
            groupValue: _filter,
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  _filter = newValue;
                });
                widget.onFilterChanged(newValue);
              }
            },
          ),
          _buildRadioTile(
            title: 'With Subtasks',
            value: 'With Subtasks',
            groupValue: _filter,
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  _filter = newValue;
                });
                widget.onFilterChanged(newValue);
              }
            },
          ),
          _buildRadioTile(
            title: 'Without Subtasks',
            value: 'Without Subtasks',
            groupValue: _filter,
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  _filter = newValue;
                });
                widget.onFilterChanged(newValue);
              }
            },
          ),
          const Divider(height: 32),
          const Text(
            'Filter by Status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildRadioTile(
            title: 'All Tasks',
            value: 'All',
            groupValue: _status,
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  _status = newValue;
                });
                widget.onStatusChanged(newValue);
              }
            },
          ),
          _buildRadioTile(
            title: 'Completed',
            value: 'Completed',
            groupValue: _status,
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  _status = newValue;
                });
                widget.onStatusChanged(newValue);
              }
            },
          ),
          _buildRadioTile(
            title: 'Pending',
            value: 'Pending',
            groupValue: _status,
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  _status = newValue;
                });
                widget.onStatusChanged(newValue);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRadioTile({
    required String title,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: Colors.blue,
      dense: true,
    );
  }
}