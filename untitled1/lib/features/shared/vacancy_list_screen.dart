import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models.dart';
import 'vacancy_detail_screen.dart';

class VacancyListScreen extends StatefulWidget {
  const VacancyListScreen({super.key});

  @override
  State<VacancyListScreen> createState() => _VacancyListScreenState();
}

class _VacancyListScreenState extends State<VacancyListScreen> {
  late Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = Future.wait([_getVacancies(), _getUserApplications()]);
  }

  Future<List<Vacancy>> _getVacancies() async {
    final response = await Supabase.instance.client.from('vacancies').select();
    return (response as List).map((json) => Vacancy.fromJson(json)).toList();
  }

  Future<List<Application>> _getUserApplications() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final response = await Supabase.instance.client.from('applications').select('*, vacancies(*), resumes(*)').eq('user_id', userId);
    return (response as List).map((json) => Application.fromJson(json)).toList();
  }

  Future<void> _applyToVacancy(Vacancy vacancy) async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final resumes = await Supabase.instance
        .client
        .from('resumes')
        .select()
        .eq('user_id', userId)
        .then((data) => (data as List).map((json) => Resume.fromJson(json)).toList());

    if (!mounted) return;

    if (resumes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала создайте хотя бы одно резюме')),
      );
      return;
    }

    final selectedResume = await showDialog<Resume>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите резюме для отклика'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: resumes.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(resumes[index].fullName),
                subtitle: Text(resumes[index].position),
                onTap: () => Navigator.of(context).pop(resumes[index]),
              );
            },
          ),
        ),
      ),
    );

    if (selectedResume != null) {
      try {
        await Supabase.instance.client.from('applications').insert({
          'vacancy_id': vacancy.id,
          'user_id': userId,
          'resume_id': selectedResume.id,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Вы успешно откликнулись!')));
          setState(() {
             _dataFuture = Future.wait([_getVacancies(), _getUserApplications()]);
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вакансии'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          
          final vacancies = snapshot.data![0] as List<Vacancy>;
          final userApplications = snapshot.data![1] as List<Application>;
          final appliedVacancyIds = userApplications.map((app) => app.vacancyId).toSet();

          if (vacancies.isEmpty) {
            return const Center(child: Text('Вакансии не найдены.'));
          }

          return ListView.builder(
            itemCount: vacancies.length,
            itemBuilder: (context, index) {
              final vacancy = vacancies[index];
              final hasApplied = appliedVacancyIds.contains(vacancy.id);

              return ListTile(
                title: Text(vacancy.title),
                subtitle: Text('${vacancy.company}, ${vacancy.city}'),
                trailing: hasApplied 
                  ? const Text('Вы откликнулись', style: TextStyle(color: Colors.green)) 
                  : ElevatedButton(child: const Text('Откликнуться'), onPressed: () => _applyToVacancy(vacancy)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VacancyDetailScreen(vacancy: vacancy)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
