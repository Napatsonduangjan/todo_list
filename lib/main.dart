import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF1EE947)),
        useMaterial3: true,
      ),
      home: const TodaApp(),
    );
  }
}

class TodaApp extends StatefulWidget {
  const TodaApp({
    super.key,
  });

  @override
  State<TodaApp> createState() => _TodaAppState();
}

class _TodaAppState extends State<TodaApp> {
  late TextEditingController _nameController;
  late TextEditingController _noteController;
  bool _status = false; // ตัวแปรสำหรับสถานะ

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void addTodoHandle(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add new task"),
          content: SizedBox(
            width: 300,
            height: 240,
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Task Name",
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Note",
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<bool>(
                  value: _status,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Status",
                  ),
                  items: [
                    DropdownMenuItem(
                      value: true,
                      child: Text("True"),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text("False"),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _status = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                CollectionReference tasks = FirebaseFirestore.instance.collection("Task");
                tasks.add({
                  'name': _nameController.text,
                  'note': _noteController.text,
                  'status': _status,
                }).then((_) {
                  print("Task added successfully");
                }).catchError((onError) {
                  print("Failed to add task: $onError");
                });

                // Clear the text fields and reset status
                _nameController.clear();
                _noteController.clear();
                setState(() {
                  _status = false;
                });
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void editTodoHandle(BuildContext context, DocumentSnapshot task) {
    _nameController.text = task['name']; // กำหนดค่าเริ่มต้นสำหรับการแก้ไข
    _noteController.text = task['note'];
    _status = task['status'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit task"),
          content: SizedBox(
            width: 300,
            height: 240,
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Task Name",
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Note",
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<bool>(
                  value: _status,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Status",
                  ),
                  items: [
                    DropdownMenuItem(
                      value: true,
                      child: Text("True"),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text("False"),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _status = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                CollectionReference tasks = FirebaseFirestore.instance.collection("Task");
                tasks.doc(task.id).update({
                  'name': _nameController.text,
                  'note': _noteController.text,
                  'status': _status,
                }).then((_) {
                  print("Task updated successfully");
                }).catchError((onError) {
                  print("Failed to update task: $onError");
                });

                // Clear the text fields and reset status
                _nameController.clear();
                _noteController.clear();
                setState(() {
                  _status = false;
                });
                Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void deleteTodoHandle(BuildContext context, DocumentSnapshot task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete task"),
          content: const Text("Are you sure you want to delete this task?"),
          actions: [
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance.collection("Task").doc(task.id).delete().then((_) {
                  print("Task deleted successfully");
                }).catchError((onError) {
                  print("Failed to delete task: $onError");
                });
                Navigator.pop(context); // ปิด dialog หลังลบเสร็จ
              },
              child: const Text("Delete"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // ปิด dialog ถ้าไม่ต้องการลบ
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Todo"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("Task").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data?.docs.length,
              itemBuilder: (context, index) {
                var task = snapshot.data?.docs[index];
                return Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task?["name"] ?? "No Name",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Note: ${task?["note"] ?? "No Note"}",
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Status: ${task?["status"] ?? "No Status"}",
                                style: const TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            editTodoHandle(context, task!); // เรียกฟังก์ชันแก้ไข
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            deleteTodoHandle(context, task!); // เรียกฟังก์ชันลบ
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text("No data"));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addTodoHandle(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
