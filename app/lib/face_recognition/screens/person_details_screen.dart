import 'package:flutter/material.dart';
import '../services/face_database_service.dart';

class PersonDetailsScreen extends StatefulWidget {
  final Person person;
  const PersonDetailsScreen({super.key, required this.person});

  @override
  State<PersonDetailsScreen> createState() => _PersonDetailsScreenState();
}

class _PersonDetailsScreenState extends State<PersonDetailsScreen> {
  final FaceDatabaseService _dbService = FaceDatabaseService();
  int _embeddingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final embeddings = await _dbService.getEmbeddingsForPerson(widget.person.id!);
    setState(() {
      _embeddingCount = embeddings.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.person.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                child: Text(widget.person.name[0].toUpperCase(), style: const TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 24),
            Text("ID: ${widget.person.id}", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text("Registered On: ${widget.person.createdAt}", style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text("Face Embeddings Saved: $_embeddingCount", style: Theme.of(context).textTheme.bodyLarge),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Additional images could be added here later
                },
                icon: const Icon(Icons.add_a_photo),
                label: const Text("Add Another Face Angle"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
