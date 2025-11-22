import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models.dart';

class CreateResumeScreen extends StatefulWidget {
  final Resume? resume;
  const CreateResumeScreen({super.key, this.resume});

  @override
  State<CreateResumeScreen> createState() => _CreateResumeScreenState();
}

class _CreateResumeScreenState extends State<CreateResumeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _positionController = TextEditingController();
  final _skillsController = TextEditingController();
  final _experienceController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.resume != null) {
      _fullNameController.text = widget.resume!.fullName;
      _positionController.text = widget.resume!.position;
      _skillsController.text = widget.resume!.skills;
      _experienceController.text = widget.resume!.experience;
    }
  }

  Future<void> _saveResume() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final Map<String, dynamic> data = {
          'user_id': userId,
          'full_name': _fullNameController.text,
          'position': _positionController.text,
          'skills': _skillsController.text,
          'experience': _experienceController.text,
        };
        if (widget.resume != null) {
          data['id'] = widget.resume!.id;
        }
        await Supabase.instance.client.from('resumes').upsert(data);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Резюме успешно сохранено')));
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
    _fullNameController.dispose();
    _positionController.dispose();
    _skillsController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.resume == null ? 'Создание резюме' : 'Редактирование')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Полное имя'),
                validator: (v) => v!.isEmpty ? 'Введите имя' : null,
              ),
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(labelText: 'Желаемая должность'),
                validator: (v) => v!.isEmpty ? 'Введите должность' : null,
              ),
              TextFormField(
                controller: _skillsController,
                decoration: const InputDecoration(labelText: 'Навыки'),
                validator: (v) => v!.isEmpty ? 'Введите навыки' : null,
              ),
              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(labelText: 'Опыт работы'),
                maxLines: 5,
                validator: (v) => v!.isEmpty ? 'Введите опыт' : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(onPressed: _saveResume, child: const Text('Сохранить')),
            ],
          ),
        ),
      ),
    );
  }
}
