import 'package:flutter/material.dart';

import '../../models.dart';

class ResumeDetailScreen extends StatelessWidget {
  final Resume resume;

  const ResumeDetailScreen({super.key, required this.resume});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(resume.fullName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Полное имя: ${resume.fullName}', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('Должность: ${resume.position}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Text('Навыки:', style: Theme.of(context).textTheme.titleSmall),
            Text(resume.skills),
            const SizedBox(height: 16),
            Text('Опыт работы:', style: Theme.of(context).textTheme.titleSmall),
            Text(resume.experience),
          ],
        ),
      ),
    );
  }
}
