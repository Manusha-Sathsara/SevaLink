import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SevaLink',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: UserScreen(),
    );
  }
}

class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS, or your IP for real devices
  final String baseUrl = 'http://10.0.2.2:8080/api/test-users';
  List testUsers = [];

  @override
  void initState() {
    super.initState();
    fetchTestUsers();
  }

  Future<void> fetchTestUsers() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        setState(() => testUsers = json.decode(response.body));
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> saveUser(String name, String email, {int? id}) async {
    try {
      final isEditing = id != null;
      final url = isEditing ? '$baseUrl/$id' : baseUrl;
      final response = await (isEditing
          ? http.put(Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'name': name, 'email': email}))
          : http.post(Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'name': name, 'email': email})));

      if (response.statusCode == 200) fetchTestUsers();
    } catch (e) {
      print('Error saving user: $e');
    }
  }

  Future<void> deleteTestUser(int id) async {
    try {
      await http.delete(Uri.parse('$baseUrl/$id'));
      fetchTestUsers();
    } catch (e) {
      print('Error deleting user: $e');
    }
  }

  void showUserDialog({Map? user}) {
    TextEditingController nameCtrl = TextEditingController(text: user?['name']);
    TextEditingController emailCtrl = TextEditingController(
        text: user?['email']);

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(user == null ? 'Add New User' : 'Edit User'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl,
                    decoration: InputDecoration(hintText: 'Name')),
                TextField(controller: emailCtrl,
                    decoration: InputDecoration(hintText: 'Email')),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context),
                  child: Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  saveUser(nameCtrl.text, emailCtrl.text, id: user?['id']);
                  Navigator.pop(context);
                },
                child: Text('Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SevaLink Users')),
      body: testUsers.isEmpty
          ? Center(child: Text('No users found'))
          : ListView.builder(
        itemCount: testUsers.length,
        itemBuilder: (context, index) {
          final user = testUsers[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              title: Text(user['name'] ?? ''),
              subtitle: Text(user['email'] ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => showUserDialog(user: user),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteTestUser(user['id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showUserDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}