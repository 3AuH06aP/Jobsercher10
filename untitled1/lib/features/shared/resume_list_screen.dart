import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models.dart';
import 'resume_detail_screen.dart';

class ResumeListScreen extends StatelessWidget {
  const ResumeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Future<List<Resume>> resumesFuture = Supabase.instance.client
        .from('resumes')
        .select()
        .then((data) => (data as List).map((json) => Resume.fromJson(json)).toList());

    return Scaffold(
      appBar: AppBar(
        title: const Text('База резюме'),
      ),
      body: FutureBuilder<List<Resume>>(
        future: resumesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Резюме не найдены.'));
          }
          final resumes = snapshot.data!;
          return ListView.builder(
            itemCount: resumes.length,
            itemBuilder: (context, index) {
              final resume = resumes[index];
              return ListTile(
                title: Text(resume.fullName),
                subtitle: Text(resume.position),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ResumeDetailScreen(resume: resume)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
