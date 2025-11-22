import 'package:flutter/material.dart';

import '../../models.dart';

class VacancyDetailScreen extends StatelessWidget {
  final Vacancy vacancy;

  const VacancyDetailScreen({super.key, required this.vacancy});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(vacancy.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(vacancy.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(vacancy.company, style: Theme.of(context).textTheme.titleLarge),
            if (vacancy.salary != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(vacancy.salary!, style: Theme.of(context).textTheme.titleMedium),
              ),
            Text(vacancy.city, style: Theme.of(context).textTheme.bodyMedium),
            const Divider(height: 32),
            Text(vacancy.description),
          ],
        ),
      ),
    );
  }
}
