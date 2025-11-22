import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models.dart';
import 'create_vacancy_screen.dart';
import 'vacancy_applications_screen.dart';

class MyVacanciesScreen extends StatefulWidget {
  const MyVacanciesScreen({super.key});

  @override
  State<MyVacanciesScreen> createState() => _MyVacanciesScreenState();
}

class _MyVacanciesScreenState extends State<MyVacanciesScreen> {
  late Future<List<Vacancy>> _vacanciesFuture;

  @override
  void initState() {
    super.initState();
    _loadVacancies();
  }

  void _loadVacancies() {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    _vacanciesFuture = Supabase.instance
        .client
        .from('vacancies')
        .select()
        .eq('user_id', userId)
        .then((data) => (data as List).map((json) => Vacancy.fromJson(json)).toList());
    setState(() {});
  }

  Future<void> _deleteVacancy(int vacancyId) async {
    try {
      await Supabase.instance.client.from('vacancies').delete().eq('id', vacancyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Вакансия удалена')));
      }
      _loadVacancies();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои вакансии')),
      body: FutureBuilder<List<Vacancy>>(
        future: _vacanciesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('У вас еще нет вакансий.'));
          }
          final vacancies = snapshot.data!;
          return ListView.builder(
            itemCount: vacancies.length,
            itemBuilder: (context, index) {
              final vacancy = vacancies[index];
              return ListTile(
                title: Text(vacancy.title),
                subtitle: Text(vacancy.company),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.people),
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => VacancyApplicationsScreen(vacancy: vacancy)))),
                    IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => CreateVacancyScreen(vacancy: vacancy)),
                          );
                          _loadVacancies();
                        }),
                    IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteVacancy(vacancy.id)),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreateVacancyScreen()));
          _loadVacancies();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
