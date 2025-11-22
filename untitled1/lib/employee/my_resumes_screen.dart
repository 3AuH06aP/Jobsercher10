import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models.dart';
import 'create_resume_screen.dart';

class MyResumesScreen extends StatefulWidget {
  const MyResumesScreen({super.key});

  @override
  State<MyResumesScreen> createState() => _MyResumesScreenState();
}

class _MyResumesScreenState extends State<MyResumesScreen> {
  late Future<List<Resume>> _resumesFuture;

  @override
  void initState() {
    super.initState();
    _loadResumes();
  }

  void _loadResumes() {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    _resumesFuture = Supabase.instance
        .client
        .from('resumes')
        .select()
        .eq('user_id', userId)
        .then((data) => (data as List).map((json) => Resume.fromJson(json)).toList());
    setState(() {});
  }

  Future<void> _deleteResume(int resumeId) async {
    try {
      await Supabase.instance.client.from('resumes').delete().eq('id', resumeId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Резюме удалено')));
      _loadResumes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои резюме')),
      body: FutureBuilder<List<Resume>>(
        future: _resumesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('У вас еще нет резюме.'));
          }
          final resumes = snapshot.data!;
          return ListView.builder(
            itemCount: resumes.length,
            itemBuilder: (context, index) {
              final resume = resumes[index];
              return ListTile(
                title: Text(resume.fullName),
                subtitle: Text(resume.position),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => CreateResumeScreen(resume: resume)),
                        );
                        _loadResumes();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteResume(resume.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreateResumeScreen()));
          _loadResumes();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
