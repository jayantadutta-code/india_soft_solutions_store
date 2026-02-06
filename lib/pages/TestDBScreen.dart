import 'package:flutter/material.dart';
import 'package:iss_app/data/local/db_helper.dart';
class TestDBScreen extends StatefulWidget {
  TestDBScreen({super.key});

  @override
  State<TestDBScreen> createState() => _TestDBScreenState();
}

class _TestDBScreenState extends State<TestDBScreen> {
  var titleController = TextEditingController();
  var descController = TextEditingController();

  List<Map<String, dynamic>> allNotes = [];
  DBHelper? dbRef;

  @override
  void initState() {
    super.initState();
    dbRef = DBHelper.getInstance;
    getNotes();
  }

  /// Get all notes from DB
  void getNotes() async {
    allNotes = await dbRef!.getALLNotes();
    setState(() {});
  }

  /// OPEN BOTTOM SHEET (Add or Edit)
  void openNoteSheet({Map<String, dynamic>? note}) {
    final rootContext = context;

    bool isEdit = note != null;

    if (isEdit) {
      titleController.text = note[DBHelper.COLUMN_NOTE_TITLE];
      descController.text = note[DBHelper.COLUMN_NOTE_DESC];
    } else {
      titleController.clear();
      descController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 15,
            right: 15,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: 430,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 15),
                Text(
                  isEdit ? 'Edit Note' : 'Add Note',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: isEdit ? Colors.blue : Colors.orange,
                  ),
                ),
                SizedBox(height: 20),

                /// Title
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                /// Description
                TextField(
                  maxLines: 3,
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                /// Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    /// Submit / Update
                    ElevatedButton(
                      onPressed: () async {
                        var title = titleController.text.trim();
                        var desc = descController.text.trim();

                        if (title.isEmpty || desc.isEmpty) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            SnackBar(
                              content: Text("Fields cannot be empty"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        bool check;

                        if (isEdit) {
                          /// Update
                          check = await dbRef!.updateNote(
                            sno: note![DBHelper.COLUMN_NOTE_SNO],
                            mTitle: title,
                            mDesc: desc,
                          );
                        } else {
                          /// Add
                          check = await dbRef!.addNote(
                            mTitle: title,
                            mDesc: desc,
                          );
                        }

                        if (check) {
                          Navigator.pop(rootContext);
                          getNotes();
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            SnackBar(
                              content: Text(isEdit
                                  ? "Note updated successfully"
                                  : "Note added successfully"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        isEdit ? Colors.blue : Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(isEdit ? 'Update' : 'Submit'),
                    ),

                    /// Reset Button
                    ElevatedButton(
                      onPressed: () {
                        titleController.clear();
                        descController.clear();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text('Reset'),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  /// DELETE NOTE
  void deleteNote(int sno) async {
    bool check = await dbRef!.deleteNote(sno);
    if (check) {
      getNotes();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Note deleted"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notes")),

      body: allNotes.isNotEmpty
          ? ListView.builder(
        itemCount: allNotes.length,
        itemBuilder: (_, index) {
          var note = allNotes[index];
          return Card(
            elevation: 3,
            margin: EdgeInsets.all(8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text("${index+1}"),
              ),

              title: Text(note[DBHelper.COLUMN_NOTE_TITLE]),
              subtitle: Text(note[DBHelper.COLUMN_NOTE_DESC]),

              /// Edit on Tap
              onTap: () {
                openNoteSheet(note: note);
              },

              /// Delete button
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  deleteNote(note[DBHelper.COLUMN_NOTE_SNO]);
                },
              ),
            ),
          );
        },
      )
          : Center(child: Text("No Notes yet!")),

      floatingActionButton: FloatingActionButton(
        onPressed: () => openNoteSheet(),
        child: Icon(Icons.add),
      ),
    );
  }
}
