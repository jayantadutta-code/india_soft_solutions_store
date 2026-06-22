import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; // ADDED

// ================= IMAGE HELPERS =================
Future<String?> saveImageToLocal(File imageFile) async {
  try {
    Directory? dir;
    try {
      dir = await getApplicationDocumentsDirectory();
      final testFile = File('${dir.path}/test.txt');
      await testFile.writeAsString('test');
      await testFile.delete();
    } catch (e) {
      print('⚠️ Documents dir not writable, using temp');
      dir = await getTemporaryDirectory();
    }
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String filePath = '${dir.path}/$fileName';
    final savedImage = await imageFile.copy(filePath);
    if (await savedImage.exists()) {
      print('✅ File saved: $filePath');
      return savedImage.path;
    } else {
      print('❌ File copy failed');
      return null;
    }
  } catch (e) {
    print('❌ saveImageToLocal error: $e');
    return null;
  }
}

void deleteImageFile(String path) {
  if (path.startsWith('base64:')) return;
  final file = File(path);
  if (file.existsSync()) {
    file.deleteSync();
    print('🗑️ Deleted file: $path');
  }
}

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
  List<String> notes;
  List<String> links;
  List<String> photos;

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
    this.notes = const [],
    this.links = const [],
    this.photos = const [],
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
    'notes': notes,
    'links': links,
    'photos': photos,
  };

  factory Todo.fromJson(Map<String, dynamic> json) {
    List<String> links = json['links'] != null
        ? List<String>.from(json['links'])
        : [];
    if (json['videoUrl'] != null && json['videoUrl'].toString().isNotEmpty) {
      if (!links.contains(json['videoUrl'])) {
        links.add(json['videoUrl']);
      }
    }
    List<String> photos = json['photos'] != null
        ? List<String>.from(json['photos'])
        : [];
    return Todo(
      id: json['id'],
      title: json['title'],
      subTodos: json['subTodos'] != null
          ? (json['subTodos'] as List).map((e) => Todo.fromJson(e)).toList()
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
      notes: json['notes'] != null ? List<String>.from(json['notes']) : [],
      links: links,
      photos: photos,
    );
  }
}

// ================= ENTRY POINT =================
class NotesPro extends StatelessWidget {
  const NotesPro({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '4th Gen Indexing ToDos',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const NotesProMainSc(),
    );
  }
}

// ================= MAIN SCREEN WITH BOTTOM NAV =================
class NotesProMainSc extends StatefulWidget {
  const NotesProMainSc({super.key});

  @override
  State<NotesProMainSc> createState() => _NotesProMainScState();
}

class _NotesProMainScState extends State<NotesProMainSc> {
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

    if (mounted) setState(() {});
  }

  // ================= CRUD OPERATIONS (with photos) =================
  void addTodo(String title, List<String> notes, List<String> links, List<String> photos) {
    if (!mounted) return;
    setState(() {
      final newTodo = Todo(
        id: DateTime.now().toString(),
        title: title,
        createdAt: DateTime.now(),
        order: todos.length,
        subTodos: [],
        notes: notes.where((n) => n.trim().isNotEmpty).toList(),
        links: links.where((l) => l.trim().isNotEmpty).toList(),
        photos: photos.where((p) => p.trim().isNotEmpty).toList(),
      );
      todos.add(newTodo);
    });
    saveData();
  }

  void addSubTodo(Todo parent, String title, List<String> notes, List<String> links, List<String> photos) {
    if (!mounted) return;
    setState(() {
      parent.subTodos.add(Todo(
        id: DateTime.now().toString(),
        title: title,
        parentId: parent.id,
        isSubTask: true,
        createdAt: DateTime.now(),
        order: parent.subTodos.length,
        subTodos: [],
        notes: notes.where((n) => n.trim().isNotEmpty).toList(),
        links: links.where((l) => l.trim().isNotEmpty).toList(),
        photos: photos.where((p) => p.trim().isNotEmpty).toList(),
      ));
    });
    saveData();
  }

  void editTodo(Todo todo, String newTitle, List<String> newNotes, List<String> newLinks, List<String> newPhotos) {
    if (!mounted) return;
    setState(() {
      todo.title = newTitle;
      todo.notes = newNotes.where((n) => n.trim().isNotEmpty).toList();
      todo.links = newLinks.where((l) => l.trim().isNotEmpty).toList();
      todo.photos = newPhotos.where((p) => p.trim().isNotEmpty).toList();
      todo.updatedAt = DateTime.now();
    });
    saveData();
  }

  void deleteTodo(Todo todo) {
    if (!mounted) return;
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
    if (!mounted) return;
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
    if (!mounted) return;
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

  // ================= RESTORE LOGIC =================
  void restoreFromBin(Todo todo) {
    if (!mounted) return;
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
    if (!mounted) return;
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
    for (var path in todo.photos) {
      deleteImageFile(path);
    }
    if (!mounted) return;
    setState(() {
      recycleBin.remove(todo);
    });
    saveData();
  }

  void emptyBin() {
    for (var todo in recycleBin) {
      for (var path in todo.photos) {
        deleteImageFile(path);
      }
    }
    if (!mounted) return;
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
    if (!mounted) return;
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
    if (!mounted) return;
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
    if (!mounted) return;
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
    if (index == _currentIndex) return;
    if (index == 1) {
      Future.delayed(const Duration(milliseconds: 300), _showAddDialog);
      return;
    }
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() {
        _currentIndex = index;
      });
    });
  }

  void _showAddDialog() => _showTodoDialog(
    title: 'Add Todo',
    initialTitle: '',
    initialNotes: const [],
    initialLinks: const [],
    initialPhotos: const [],
    onSave: (title, notes, links, photos) => addTodo(title, notes, links, photos),
  );

  void _showEditDialog(Todo todo) => _showTodoDialog(
    title: todo.isSubTask ? 'Edit Sub Task' : 'Edit Todo',
    initialTitle: todo.title,
    initialNotes: todo.notes,
    initialLinks: todo.links,
    initialPhotos: todo.photos,
    onSave: (newTitle, notes, links, photos) => editTodo(todo, newTitle, notes, links, photos),
  );

  void _showAddSubDialog(Todo parent) => _showTodoDialog(
    title: 'Add Sub Task',
    initialTitle: '',
    initialNotes: const [],
    initialLinks: const [],
    initialPhotos: const [],
    onSave: (newTitle, notes, links, photos) => addSubTodo(parent, newTitle, notes, links, photos),
  );

  // ================= UNIVERSAL DIALOG (with photos) =================
  void _showTodoDialog({
    required String title,
    required String initialTitle,
    required List<String> initialNotes,
    required List<String> initialLinks,
    required List<String> initialPhotos,
    required Function(String, List<String>, List<String>, List<String>) onSave,
  }) {
    final titleController = TextEditingController(text: initialTitle);

    List<TextEditingController> noteControllers = [];
    List<TextEditingController> linkControllers = [];

    for (var note in initialNotes) {
      noteControllers.add(TextEditingController(text: note));
    }
    for (var link in initialLinks) {
      linkControllers.add(TextEditingController(text: link));
    }

    // photoPaths declared outside StatefulBuilder to persist across rebuilds
    List<String> photoPaths = List.from(initialPhotos);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void addNote() {
              if (noteControllers.length < 3) {
                setDialogState(() {
                  noteControllers.add(TextEditingController());
                });
              }
            }

            void addLink() {
              if (linkControllers.length < 3) {
                setDialogState(() {
                  linkControllers.add(TextEditingController());
                });
              }
            }

            void pickImage() async {
              print('📸 pickImage called');
              if (photoPaths.length >= 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Maximum 3 photos allowed')),
                );
                return;
              }

              final picker = ImagePicker();
              final XFile? picked = await picker.pickImage(source: ImageSource.gallery);

              if (picked == null) {
                print('❌ User cancelled photo pick');
                return;
              }

              print('📸 Picked file: ${picked.path}');
              final file = File(picked.path);
              final int fileSize = await file.length();
              print('📏 File size: $fileSize bytes');
              const int maxSize = 5 * 1024 * 1024;
              if (fileSize > maxSize) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Image too large (max 5 MB)'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              bool savedAsFile = false;
              String? savedPath;
              try {
                savedPath = await saveImageToLocal(file);
                if (savedPath != null && await File(savedPath).exists()) {
                  savedAsFile = true;
                  print('✅ Saved as file: $savedPath');
                }
              } catch (e) {
                print('⚠️ File save error: $e');
              }

              if (savedAsFile && savedPath != null) {
                setDialogState(() {
                  photoPaths.add(savedPath!);
                  print('📋 Added file path, photoPaths now: $photoPaths');
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Photo added!')),
                );
              } else {
                print('⚠️ Falling back to base64');
                try {
                  final bytes = await picked.readAsBytes();
                  final base64Str = base64Encode(bytes);
                  final base64Prefixed = 'base64:$base64Str';
                  setDialogState(() {
                    photoPaths.add(base64Prefixed);
                    print('📋 Added base64, photoPaths now: $photoPaths');
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Photo added (base64)')),
                  );
                } catch (e) {
                  print('❌ Base64 encoding failed: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to process image: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }

            void removePhoto(int index) {
              setDialogState(() {
                photoPaths.removeAt(index);
                print('🗑️ Removed photo at index $index, now: $photoPaths');
              });
            }

            bool canAddNote = noteControllers.length < 3;
            bool canAddLink = linkControllers.length < 3;
            bool canAddPhoto = photoPaths.length < 3;

            return AlertDialog(
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title field with add button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: titleController,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'Enter title',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'note') addNote();
                            if (value == 'link') addLink();
                            if (value == 'photo') pickImage();
                          },
                          enabled: canAddNote || canAddLink || canAddPhoto,
                          itemBuilder: (context) {
                            List<PopupMenuEntry<String>> items = [];
                            if (canAddNote) {
                              items.add(
                                const PopupMenuItem(
                                  value: 'note',
                                  child: Row(
                                    children: [
                                      Icon(Icons.note_add, size: 20),
                                      SizedBox(width: 8),
                                      Text('Add description'),
                                    ],
                                  ),
                                ),
                              );
                            }
                            if (canAddLink) {
                              items.add(
                                const PopupMenuItem(
                                  value: 'link',
                                  child: Row(
                                    children: [
                                      Icon(Icons.link, size: 20),
                                      SizedBox(width: 8),
                                      Text('Add link'),
                                    ],
                                  ),
                                ),
                              );
                            }
                            if (canAddPhoto) {
                              items.add(
                                const PopupMenuItem(
                                  value: 'photo',
                                  child: Row(
                                    children: [
                                      Icon(Icons.photo, size: 20),
                                      SizedBox(width: 8),
                                      Text('Add photo'),
                                    ],
                                  ),
                                ),
                              );
                            }
                            if (items.isEmpty) {
                              items.add(
                                const PopupMenuItem(
                                  enabled: false,
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, size: 20),
                                      SizedBox(width: 8),
                                      Text('Maximum reached'),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return items;
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: (canAddNote || canAddLink || canAddPhoto) ? Colors.deepPurple : Colors.grey,
                                width: 2,
                              ),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.add,
                              size: 24,
                              color: (canAddNote || canAddLink || canAddPhoto) ? Colors.deepPurple : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Descriptions section
                    if (noteControllers.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Descriptions:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...noteControllers.asMap().entries.map((entry) {
                              int index = entry.key;
                              var controller = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: controller,
                                        decoration: const InputDecoration(
                                          hintText: 'Note...',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(8)),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        ),
                                        maxLines: 2,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                      onPressed: () {
                                        setDialogState(() {
                                          noteControllers.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Links section
                    if (linkControllers.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Links:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...linkControllers.asMap().entries.map((entry) {
                              int index = entry.key;
                              var controller = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: controller,
                                        decoration: const InputDecoration(
                                          hintText: 'Enter URL...',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(8)),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                      onPressed: () {
                                        setDialogState(() {
                                          linkControllers.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Photos section
                    Row(
                      children: [
                        Text(
                          'Photos (${photoPaths.length}/3)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (photoPaths.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: photoPaths.asMap().entries.map((entry) {
                            int idx = entry.key;
                            String path = entry.value;
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _buildPhotoWidget(path, 60, 60),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => removePhoto(idx),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      const Text(
                        'No photos added yet',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                    ],

                    const Text(
                      'Max 3 Descriptions,\nMax 3 Links,\nMax 3 photos, each up to 5 MB',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    String newTitle = titleController.text.trim();
                    if (newTitle.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Please enter a title')),
                      );
                      return;
                    }
                    List<String> notes = noteControllers
                        .map((c) => c.text.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();
                    List<String> links = linkControllers
                        .map((c) => c.text.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();
                    print('💾 Saving: title="$newTitle", photos=$photoPaths');
                    onSave(newTitle, notes, links, photoPaths);
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ========== PHOTO VIEWER ==========
  void _showPhotoViewer(BuildContext context, String path) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: _buildPhotoWidget(
                  path,
                  double.infinity,
                  double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== PHOTO WIDGET BUILDER ==========
  Widget _buildPhotoWidget(String path, double width, double height, {BoxFit fit = BoxFit.cover}) {
    if (path.startsWith('base64:')) {
      try {
        final base64Str = path.substring(7);
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stack) {
            print('❌ Image.memory error: $error');
            return Container(
              width: width,
              height: height,
              color: Colors.red[100],
              child: const Icon(Icons.broken_image, color: Colors.red),
            );
          },
        );
      } catch (e) {
        print('❌ Base64 decode error: $e');
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.error, color: Colors.red),
        );
      }
    } else {
      return Image.file(
        File(path),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stack) {
          print('❌ Image.file error for: $path');
          return Container(
            width: width,
            height: height,
            color: Colors.red[100],
            child: const Icon(Icons.broken_image, color: Colors.red),
          );
        },
      );
    }
  }

  // ================= YOUTUBE LINK CHECK =================
  bool _isYouTubeLink(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('youtube.com') ||
        lowerUrl.contains('youtu.be') ||
        lowerUrl.contains('youtube-nocookie.com');
  }

  // ================= YOUTUBE LAUNCHER =================
  String _extractVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([^&\n?#]+)',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1) ?? '';
  }

  Future<void> _playVideo(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No URL provided')),
      );
      return;
    }

    String cleanUrl = url.trim();
    if (_isYouTubeLink(url)) {
      String videoId = _extractVideoId(url);
      if (videoId.isNotEmpty) {
        cleanUrl = 'https://www.youtube.com/watch?v=$videoId';
      }
    }
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'https://$cleanUrl';
    }

    try {
      final Uri uri = Uri.parse(cleanUrl);
      bool launched = false;

      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        // fallback
      }

      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (e) {
          // ignore
        }
      }

      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open URL: $cleanUrl'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================= RECURSIVE SHARE (including all subtasks and their photos) =================
  void _shareTodo(Todo todo) async {
    final buffer = StringBuffer();
    final List<XFile> photoFiles = [];

    Future<void> collect(Todo t, int level) async {
      final indent = '  ' * level;
      buffer.writeln('$indent📌 ${t.title}');
      if (t.isCompleted) buffer.writeln('$indent  ✅ Completed');
      else buffer.writeln('$indent  ⏳ Pending');

      if (t.notes.isNotEmpty) {
        buffer.writeln('$indent  📝 Notes:');
        for (var note in t.notes) {
          buffer.writeln('$indent    • $note');
        }
      }
      if (t.links.isNotEmpty) {
        buffer.writeln('$indent  🔗 Links:');
        for (var link in t.links) {
          buffer.writeln('$indent    • $link');
        }
      }

      // Collect photos from this todo
      for (var photoPath in t.photos) {
        try {
          if (photoPath.startsWith('base64:')) {
            final bytes = base64Decode(photoPath.substring(7));
            final tempDir = await getTemporaryDirectory();
            final tempFile = File('${tempDir.path}/photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
            await tempFile.writeAsBytes(bytes);
            photoFiles.add(XFile(tempFile.path));
          } else {
            final file = File(photoPath);
            if (await file.exists()) {
              photoFiles.add(XFile(file.path));
            }
          }
        } catch (e) {
          print('⚠️ Error adding photo: $e');
        }
      }

      // Recurse into subtasks
      for (var sub in t.subTodos) {
        await collect(sub, level + 1);
      }
    }

    await collect(todo, 0);

    final text = buffer.toString();

    // Try to share with photos on all platforms
    try {
      if (photoFiles.isEmpty) {
        await Share.share(text);
      } else {
        await Share.shareXFiles(photoFiles, text: text);
      }
    } catch (e) {
      // Fallback: share just text (likely on desktop where file sharing is not supported)
      await Share.share(text);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photos could not be attached on this platform – text only.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
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
            onEditTodo: _showEditDialog,
            onDeleteTodo: deleteTodo,
            onAddSubTodo: _showAddSubDialog,
            onMainListReorder: handleMainListReorder,
            onSubTaskReorder: handleSubTaskReorderWithinParent,
            onDeleteSelected: deleteSelected,
            saveData: saveData,
            onPlayVideo: _playVideo,
            isYouTubeLink: _isYouTubeLink,
            buildPhotoWidget: _buildPhotoWidget,
            onPhotoTap: _showPhotoViewer,
            onShare: _shareTodo, // SHARE CALLBACK (now recursive)
          ),
          Container(),
          RecycleBinPage(
            key: const ValueKey('recycle_bin'),
            recycleBin: recycleBin,
            onRestore: restoreFromBin,
            onDeletePermanently: permanentlyDelete,
            onRestoreAll: restoreAllFromBin,
            onEmptyBin: emptyBin,
            onPlayVideo: _playVideo,
            isYouTubeLink: _isYouTubeLink,
            buildPhotoWidget: _buildPhotoWidget,
            onPhotoTap: _showPhotoViewer,
          ),
          FilterPage(
            key: ValueKey('filter_${filterType}_$completionFilter'),
            currentFilter: filterType,
            currentStatus: completionFilter,
            onFilterChanged: (value) {
              if (value != null && mounted) {
                setState(() {
                  filterType = value;
                });
              }
            },
            onStatusChanged: (value) {
              if (value != null && mounted) {
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
          color: Colors.deepPurple[700]!,
          buttonBackgroundColor: Colors.deepPurple[700]!,
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
  final Function(Todo) onEditTodo;
  final Function(Todo) onDeleteTodo;
  final Function(Todo) onAddSubTodo;
  final Function(int, int) onMainListReorder;
  final Function(Todo, Todo) onSubTaskReorder;
  final Function(List<String>) onDeleteSelected;
  final VoidCallback saveData;
  final Function(String) onPlayVideo;
  final bool Function(String) isYouTubeLink;
  final Widget Function(String, double, double, {BoxFit fit}) buildPhotoWidget;
  final void Function(BuildContext, String) onPhotoTap;
  final void Function(Todo) onShare; // SHARE

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
    required this.onPlayVideo,
    required this.isYouTubeLink,
    required this.buildPhotoWidget,
    required this.onPhotoTap,
    required this.onShare,
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
    if (!mounted) return;
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
    if (!mounted) return;
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
    if (!mounted) return;
    setState(() {
      selectedIds.clear();
      isSelectionMode = false;
    });
  }

  void _deleteSelected() {
    if (selectedIds.isEmpty) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Selected'),
        content: Text('Are you sure you want to delete ${selectedIds.length} item(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (!mounted) return;
              widget.onDeleteSelected(selectedIds.toList());
              setState(() {
                selectedIds.clear();
                isSelectionMode = false;
              });
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ================= BUILD TODO ITEM (with photos) =================
  Widget buildTodoItem(Todo todo, int level) {
    if (!_expandedState.containsKey(todo.id)) _expandedState[todo.id] = false;
    bool isDragTarget = dragTargetParent == todo;

    List<Widget> noteWidgets = [];
    for (var note in todo.notes) {
      if (note.trim().isNotEmpty) {
        noteWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.note, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    note,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    List<Widget> linkWidgets = [];
    for (var link in todo.links) {
      if (link.trim().isNotEmpty) {
        bool isYouTube = widget.isYouTubeLink(link);
        linkWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            child: Row(
              children: [
                Icon(
                  isYouTube ? Icons.play_circle_filled : Icons.link,
                  size: 20,
                  color: isYouTube ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    link,
                    style: TextStyle(
                      fontSize: 11,
                      color: isYouTube ? Colors.red : Colors.blue,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isYouTube ? Icons.play_arrow : Icons.open_in_new,
                    size: 18,
                    color: isYouTube ? Colors.red : Colors.blue,
                  ),
                  onPressed: () => widget.onPlayVideo(link),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: isYouTube ? 'Play' : 'Open',
                ),
              ],
            ),
          ),
        );
      }
    }

    List<Widget> photoWidgets = [];
    for (var path in todo.photos) {
      if (path.isNotEmpty) {
        photoWidgets.add(
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: GestureDetector(
              onTap: () => widget.onPhotoTap(context, path),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: widget.buildPhotoWidget(path, 50, 50),
              ),
            ),
          ),
        );
      }
    }

    Widget listTile = ListTile(
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
                child: Icon(Icons.done_all, size: 16, color: Colors.deepPurple),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 16),
            padding: EdgeInsets.zero,
            onSelected: (value) {
              switch (value) {
                case 'add':
                  widget.onAddSubTodo(todo);
                  break;
                case 'edit':
                  widget.onEditTodo(todo);
                  break;
                case 'share':
                  widget.onShare(todo);
                  break;
                case 'delete':
                  _showDeleteConfirmDialog(todo);
                  break;
                case 'expand':
                  if (mounted) {
                    setState(() {
                      _expandedState[todo.id] = !(_expandedState[todo.id] ?? false);
                    });
                  }
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
              menuItems.add(
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share, size: 18),
                      SizedBox(width: 8),
                      Text('Share'),
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
    );

    List<Widget> children = [listTile];
    if (noteWidgets.isNotEmpty) children.addAll(noteWidgets);
    if (linkWidgets.isNotEmpty) children.addAll(linkWidgets);
    if (photoWidgets.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: photoWidgets,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Card(
        color: isDragTarget ? Colors.deepPurple[50] : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 1,
        child: Padding(
          padding: EdgeInsets.only(left: level * 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...children,
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
              if (mounted) {
                setState(() {
                  dragTargetParent = null;
                });
              }
            },
            child: DragTarget<Todo>(
              onAccept: (dragged) {
                if (dragged.isSubTask && subtask.isSubTask && dragged.parentId == subtask.parentId) {
                  widget.onSubTaskReorder(dragged, subtask);
                }
                if (mounted) {
                  setState(() {
                    dragTargetParent = null;
                  });
                }
              },
              onWillAccept: (dragged) {
                if (dragged != null &&
                    dragged.id != subtask.id &&
                    dragged.isSubTask &&
                    subtask.isSubTask &&
                    dragged.parentId == subtask.parentId) {
                  if (mounted) {
                    setState(() {
                      dragTargetParent = subtask;
                    });
                  }
                  return true;
                }
                return false;
              },
              onLeave: (dragged) {
                if (mounted) {
                  setState(() {
                    dragTargetParent = null;
                  });
                }
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

  void _showDeleteConfirmDialog(Todo todo) {
    List<String> parentChain = [];
    Todo? currentParent = _findParentOfTodo(todo);
    while (currentParent != null) {
      parentChain.insert(0, currentParent.id);
      currentParent = _findParentOfTodo(currentParent);
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (!mounted) return;
              todo.parentChain = parentChain.isNotEmpty ? parentChain : null;
              widget.onDeleteTodo(todo);
              Navigator.pop(dialogContext);
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
        title: const Text(
          '4th Gen Indexing ToDos',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple[700],
        actions: [
          if (isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all, color: Colors.white),
              onPressed: _selectAll,
              tooltip: 'Select All',
            ),
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: _clearSelection,
              tooltip: 'Clear Selection',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
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
              cursorColor: Colors.deepPurple,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, size: 18, color: Colors.deepPurple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                isDense: true,
                hintStyle: TextStyle(color: Colors.grey.shade600),
              ),
              style: const TextStyle(color: Colors.deepPurple),
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    searchQuery = value;
                  });
                }
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
  final Function(String) onPlayVideo;
  final bool Function(String) isYouTubeLink;
  final Widget Function(String, double, double, {BoxFit fit}) buildPhotoWidget;
  final void Function(BuildContext, String) onPhotoTap;

  const RecycleBinPage({
    super.key,
    required this.recycleBin,
    required this.onRestore,
    required this.onDeletePermanently,
    required this.onRestoreAll,
    required this.onEmptyBin,
    required this.onPlayVideo,
    required this.isYouTubeLink,
    required this.buildPhotoWidget,
    required this.onPhotoTap,
  });

  @override
  State<RecycleBinPage> createState() => _RecycleBinPageState();
}

class _RecycleBinPageState extends State<RecycleBinPage> {
  void _confirmRestore(Todo todo) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore Item'),
        content: Text('Are you sure you want to restore "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (mounted) widget.onRestore(todo);
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _confirmPermanentDelete(Todo todo) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Permanently Delete'),
        content: Text(
          'Are you sure you want to permanently delete "${todo.title}"?\n\nThis action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogContext);
              if (mounted) widget.onDeletePermanently(todo);
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _confirmRestoreAll() {
    if (widget.recycleBin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recycle bin is empty')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore All'),
        content: Text('Are you sure you want to restore all ${widget.recycleBin.length} items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (mounted) widget.onRestoreAll();
            },
            child: const Text('Restore All'),
          ),
        ],
      ),
    );
  }

  void _confirmEmptyBin() {
    if (widget.recycleBin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recycle bin is already empty')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Empty Recycle Bin'),
        content: Text(
          'Are you sure you want to permanently delete all ${widget.recycleBin.length} items?\n\nThis action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogContext);
              if (mounted) widget.onEmptyBin();
            },
            child: const Text('Empty Bin'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recycle Bin',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple[700],
        actions: [
          if (widget.recycleBin.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.restore, color: Colors.white),
              onPressed: _confirmRestoreAll,
              tooltip: 'Restore All',
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              onPressed: _confirmEmptyBin,
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

          List<Widget> noteWidgets = [];
          for (var note in todo.notes) {
            if (note.trim().isNotEmpty) {
              noteWidgets.add(
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          note,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }

          List<Widget> linkWidgets = [];
          for (var link in todo.links) {
            if (link.trim().isNotEmpty) {
              bool isYouTube = widget.isYouTubeLink(link);
              linkWidgets.add(
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  child: Row(
                    children: [
                      Icon(
                        isYouTube ? Icons.play_circle_filled : Icons.link,
                        size: 20,
                        color: isYouTube ? Colors.red : Colors.blue,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          link,
                          style: TextStyle(
                            fontSize: 11,
                            color: isYouTube ? Colors.red : Colors.blue,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isYouTube ? Icons.play_arrow : Icons.open_in_new,
                          size: 18,
                          color: isYouTube ? Colors.red : Colors.blue,
                        ),
                        onPressed: () => widget.onPlayVideo(link),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: isYouTube ? 'Play' : 'Open',
                      ),
                    ],
                  ),
                ),
              );
            }
          }

          List<Widget> photoWidgets = [];
          for (var path in todo.photos) {
            if (path.isNotEmpty) {
              photoWidgets.add(
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: GestureDetector(
                    onTap: () => widget.onPhotoTap(context, path),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: widget.buildPhotoWidget(path, 50, 50),
                    ),
                  ),
                ),
              );
            }
          }

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          todo.title,
                          style: TextStyle(
                            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.restore, color: Colors.green),
                        onPressed: () => _confirmRestore(todo),
                        tooltip: 'Restore',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        onPressed: () => _confirmPermanentDelete(todo),
                        tooltip: 'Delete Permanently',
                      ),
                    ],
                  ),
                  ...noteWidgets,
                  ...linkWidgets,
                  if (photoWidgets.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: photoWidgets,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
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
      if (mounted) {
        setState(() {
          _filter = widget.currentFilter;
        });
      }
    }
    if (widget.currentStatus != oldWidget.currentStatus) {
      if (mounted) {
        setState(() {
          _status = widget.currentStatus;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Filter & Status',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple[700],
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
              if (newValue != null && mounted) {
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
              if (newValue != null && mounted) {
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
              if (newValue != null && mounted) {
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
              if (newValue != null && mounted) {
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
              if (newValue != null && mounted) {
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
              if (newValue != null && mounted) {
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
      activeColor: Colors.deepPurple,
      dense: true,
    );
  }
}