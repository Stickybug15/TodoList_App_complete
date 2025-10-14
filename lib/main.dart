import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';

void main () async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To Do List',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreenAccent),
        useMaterial3: true,
      ),
      home: const TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final TextEditingController _taskController = TextEditingController();
  final CollectionReference _todosCollection =
  FirebaseFirestore.instance.collection('todos');

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    if (_taskController.text.trim().isEmpty) return;

    try {
      await _todosCollection.add({
        'task' : _taskController.text.trim(),
        'completed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _taskController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task added Successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _toggleTaskCompletion(String docId, bool currentStatus) async {
    try {
      await _todosCollection.doc(docId).update({
        'completed' : !currentStatus,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteTask (String docId) async {
    try {
      await _todosCollection.doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task Deleted')),
        );
      }
    } catch (e) {
      if (mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My to do list App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _todosCollection
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading tasks'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tasks = snapshot.data!.docs;

                if (tasks.isEmpty) {
                  return const Center(child: Text('No tasks yet.'));
                }

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final doc = tasks[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final task = data['task'] ?? '';
                    final completed = data['completed'] ?? false;
                    final createdAt = data['createdAt'] != null
                        ? (data['createdAt'] as Timestamp).toDate()
                        : null;

                    return ListTile(
                      leading: Checkbox(
                        value: completed,
                        onChanged: (_) =>
                            _toggleTaskCompletion(doc.id, completed),
                      ),
                      title: Text(
                        task,
                        style: TextStyle(
                          decoration: completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      subtitle: createdAt != null
                          ? Text(DateFormat('MMM d, y – hh:mm a')
                          .format(createdAt))
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.blue),
                        onPressed: () => _deleteTask(doc.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(
                      labelText: 'Enter task',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addTask,
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}