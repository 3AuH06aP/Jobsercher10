import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models.dart';

class MyApplicationScreen extends StatefulWidget {
  const MyApplicationScreen({super.key});

  @override
  State<MyApplicationScreen> createState() => _MyApplicationScreenState();
}

class _MyApplicationScreenState extends State<MyApplicationScreen> {
  late Future<List<Application>> _applicationsFuture;

  @override
  void initState() {
    super.initState();
    _applicationsFuture = _getApplications();
  }

  Future<List<Application>> _getApplications() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final response = await Supabase.instance
        .client
        .from('applications')
        .select('*, vacancies(*), resumes(*)')
        .eq('user_id', userId);
    return (response as List).map((json) => Application.fromJson(json)).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои отклики')),
      body: FutureBuilder<List<Application>>(
        future: _applicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Вы еще не откликались на вакансии.'));
          }
          final applications = snapshot.data!;
          return ListView.builder(
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];
              return ListTile(
                title: Text(app.vacancy.title),
                subtitle: Text('Статус: ${_statusToString(app.status)}'),
                trailing: Text(app.vacancy.company),
              );
            },
          );
        },
      ),
    );
  }
}
