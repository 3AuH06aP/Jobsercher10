import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models.dart';

class CreateVacancyScreen extends StatefulWidget {
  final Vacancy? vacancy;
  const CreateVacancyScreen({super.key, this.vacancy});

  @override
  State<CreateVacancyScreen> createState() => _CreateVacancyScreenState();
}

class _CreateVacancyScreenState extends State<CreateVacancyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _cityController = TextEditingController();
  final _salaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.vacancy != null) {
      _titleController.text = widget.vacancy!.title;
      _companyController.text = widget.vacancy!.company;
      _cityController.text = widget.vacancy!.city;
      _salaryController.text = widget.vacancy!.salary ?? '';
      _descriptionController.text = widget.vacancy!.description;
    }
  }

  Future<void> _saveVacancy() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final Map<String, dynamic> data = {
          'user_id': userId,
          'title': _titleController.text,
          'company': _companyController.text,
          'city': _cityController.text,
          'salary': _salaryController.text,
          'description': _descriptionController.text,
        };
        if (widget.vacancy != null) {
          data['id'] = widget.vacancy!.id;
        }

        await Supabase.instance.client.from('vacancies').upsert(data);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Вакансия успешно сохранена')));
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _cityController.dispose();
    _salaryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vacancy == null ? 'Новая вакансия' : 'Редактирование'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Название вакансии'),
                validator: (v) => v!.isEmpty ? 'Введите название' : null,
              ),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(labelText: 'Компания'),
                validator: (v) => v!.isEmpty ? 'Введите название' : null,
              ),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Город'),
                validator: (v) => v!.isEmpty ? 'Введите город' : null,
              ),
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(labelText: 'Зарплата (например, 100 000 руб.)'),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Описание вакансии'),
                maxLines: 5,
                validator: (v) => v!.isEmpty ? 'Добавьте описание' : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _saveVacancy,
                      child: const Text('Сохранить'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
