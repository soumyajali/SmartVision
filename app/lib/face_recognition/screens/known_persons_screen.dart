import 'package:flutter/material.dart';
import '../services/face_database_service.dart';

class KnownPersonsScreen extends StatefulWidget {
  const KnownPersonsScreen({super.key});

  @override
  State<KnownPersonsScreen> createState() => _KnownPersonsScreenState();
}

class _KnownPersonsScreenState extends State<KnownPersonsScreen> {
  final FaceDatabaseService _dbService = FaceDatabaseService();
  List<Person> _persons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPersons();
  }

  Future<void> _loadPersons() async {
    final persons = await _dbService.getAllPersons();
    setState(() {
      _persons = persons;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Face Database")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _persons.isEmpty
              ? const Center(child: Text("No faces registered yet."))
              : ListView.builder(
                  itemCount: _persons.length,
                  itemBuilder: (context, index) {
                    final p = _persons[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(p.name),
                      subtitle: Text("ID: ${p.id} | Added: ${p.createdAt.split('T').first}"),
                      onTap: () {
                        Navigator.pushNamed(
                          context, 
                          '/person_details', 
                          arguments: p
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/add_person');
          _loadPersons(); // Refresh after adding
        },
        icon: const Icon(Icons.person_add),
        label: const Text("Register Face"),
      ),
    );
  }
}
