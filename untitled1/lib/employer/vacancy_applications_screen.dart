import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models.dart';
import '../features/shared/resume_detail_screen.dart';

class VacancyApplicationsScreen extends StatefulWidget {
  final Vacancy vacancy;
  const VacancyApplicationsScreen({super.key, required this.vacancy});

  @override
  State<VacancyApplicationsScreen> createState() => _VacancyApplicationsScreenState();
}

class _VacancyApplicationsScreenState extends State<VacancyApplicationsScreen> {
  late Future<List<Application>> _applicationsFuture;

  @override
  void initState() {
    super.initState();
    _applicationsFuture = _getApplications();
  }

  String _statusToString(String status) {
    switch (status) {
      case 'pending':
        return 'В рассмотрении';
      case 'viewed':
        return 'Просмотрено';
      case 'accepted':
        return 'Принято';
      case 'rejected':
        return 'Отклонено';
      default:
        return 'Неизвестно';
    }
  }

  Future<List<Application>> _getApplications() async {
    final response = await Supabase.instance
        .client
        .from('applications')
        .select('*, resumes(*), vacancies(*)') // resumes needed for applicant name
        .eq('vacancy_id', widget.vacancy.id);
    return (response as List).map((json) => Application.fromJson(json)).toList();
  }

  Future<void> _updateStatus(int applicationId, String newStatus) async {
    try {
      await Supabase.instance.client.from('applications').update({'status': newStatus}).eq('id', applicationId);
      setState(() {
        _applicationsFuture = _getApplications();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Отклики на "${widget.vacancy.title}"')),
      body: FutureBuilder<List<Application>>(
        future: _applicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('На эту вакансию еще нет откликов.'));
          }
          final applications = snapshot.data!;
          return ListView.builder(
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];
              return ListTile(
                title: Text(app.resume.fullName),
                subtitle: Text('Должность: ${app.resume.position}'),
                trailing: app.status == 'pending'
                    ? PopupMenuButton<String>(
                        onSelected: (String newStatus) => _updateStatus(app.id, newStatus),
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(value: 'viewed', child: Text('Просмотрено')),
                          const PopupMenuItem<String>(value: 'accepted', child: Text('Принять')),
                          const PopupMenuItem<String>(value: 'rejected', child: Text('Отклонить')),
                        ],
                        child: const Chip(
                          label: Text('Действие'),
                          backgroundColor: Colors.blue,
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                      )
                    : Chip(label: Text(_statusToString(app.status))),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ResumeDetailScreen(resume: app.resume)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
