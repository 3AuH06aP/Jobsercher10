import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'employee/my_applications_screen.dart';
import 'employee/my_resumes_screen.dart';
import 'employer/my_vacancies_screen.dart';
import 'features/shared/resume_list_screen.dart';
import 'features/shared/vacancy_list_screen.dart';

// --- ОСНОВНАЯ ЧАСТЬ ПРИЛОЖЕНИЯ ---

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wkluawbonzgbknkgrcea.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndrbHVhd2JvbnpnYmtua2dyY2VhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM3NDU4MTUsImV4cCI6MjA3OTMyMTgxNX0.AwRpB4bM5Z42HAPzT45nS3QFEw86T-6GVNOv64maNK4',
  );

  final themeNotifier = ThemeNotifier();
  await themeNotifier.loadTheme();

  runApp(ChangeNotifierProvider(create: (_) => themeNotifier, child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'HR-приложение',
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
            useMaterial3: true,
          ),
          themeMode: themeNotifier.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}

// --- УПРАВЛЕНИЕ ТЕМОЙ ---

class ThemeNotifier extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  late ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  ThemeNotifier() {
    _themeMode = ThemeMode.system;
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    _themeMode = ThemeMode.values[themeIndex];
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    _themeMode = themeMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, themeMode.index);
    notifyListeners();
  }
}

// --- ЭКРАНЫ АУТЕНТИФИКАЦИИ И НАВИГАЦИИ ---

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

enum UserRole { employee, employer }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.employee;
  bool _isSigningUp = false;

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
      } on AuthException catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          data: {'role': _selectedRole.name},
        );
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Проверьте свою почту для подтверждения регистрации.')));
          setState(() {
            _isSigningUp = false;
          });
        }
      } on AuthException catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isSigningUp ? 'Регистрация' : 'Вход')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите ваш email';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Пароль'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите ваш пароль';
                    }
                    return null;
                  },
                ),
                if (_isSigningUp)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: SegmentedButton<UserRole>(
                      segments: const [
                        ButtonSegment(value: UserRole.employee, label: Text('Работник')),
                        ButtonSegment(value: UserRole.employer, label: Text('Работодатель')),
                      ],
                      selected: {_selectedRole},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _selectedRole = newSelection.first;
                        });
                      },
                    ),
                  ),
                const SizedBox(height: 20),
                if (_isLoading)
                  const CircularProgressIndicator()
                else if (_isSigningUp)
                  Column(
                    children: [
                      ElevatedButton(onPressed: _signUp, child: const Text('Зарегистрироваться')),
                      TextButton(
                        onPressed: () => setState(() => _isSigningUp = false),
                        child: const Text('Уже есть аккаунт? Войти'),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      ElevatedButton(onPressed: _signIn, child: const Text('Войти')),
                      TextButton(
                        onPressed: () => setState(() => _isSigningUp = true),
                        child: const Text('Нет аккаунта? Зарегистрироваться'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client.from('profiles').select('role').eq('id', userId).maybeSingle();

      setState(() {
        if (data != null) {
          _userRole = data['role'];
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки роли пользователя: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HR-приложение'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userRole == 'employer'
              ? const EmployerHomeScreen()
              : const EmployeeHomeScreen(),
    );
  }
}

// --- ГЛАВНЫЕ ЭКРАНЫ ДЛЯ РОЛЕЙ ---

class EmployeeHomeScreen extends StatelessWidget {
  const EmployeeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VacancyListScreen()),
              );
            },
            child: const Text('Найти работу'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyResumesScreen()),
              );
            },
            child: const Text('Мои резюме'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyApplicationScreen()),
              );
            },
            child: const Text('Мои отклики'),
          ),
        ],
      ),
    );
  }
}

class EmployerHomeScreen extends StatelessWidget {
  const EmployerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyVacanciesScreen()),
              );
            },
            child: const Text('Мои вакансии и отклики'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ResumeListScreen()),
              );
            },
            child: const Text('Найти кандидатов'),
          ),
        ],
      ),
    );
  }
}

// --- ЭКРАН ПРОФИЛЯ ---

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  String? _userRoleForDisplay;

  final _displayNameController = TextEditingController();
  final _positionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _summaryController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    _summaryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client.from('profiles').select().eq('id', userId).maybeSingle();

      if (data != null) {
        _displayNameController.text = data['display_name'] ?? '';
        _userRoleForDisplay = data['role'];
        _positionController.text = data['position'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _summaryController.text = data['summary'] ?? '';
        _cityController.text = data['city'] ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки профиля: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        await Supabase.instance.client.from('profiles').upsert({
          'id': userId,
          'display_name': _displayNameController.text,
          'position': _positionController.text,
          'phone': _phoneController.text,
          'summary': _summaryController.text,
          'city': _cityController.text,
          'updated_at': DateTime.now().toIso8601String(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Профиль успешно обновлен')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка обновления профиля: $e')),
          );
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
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Тёмная тема'),
                        Switch(
                          value: themeNotifier.themeMode == ThemeMode.dark,
                          onChanged: (value) {
                            themeNotifier.setTheme(value ? ThemeMode.dark : ThemeMode.light);
                          },
                        ),
                      ],
                    ),
                    if (_userRoleForDisplay != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Статус: ${_userRoleForDisplay == 'employee' ? 'Работник' : 'Работодатель'}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    const Divider(),
                    TextFormField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(labelText: 'Отображаемое имя'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите отображаемое имя';
                        }
                        return null;
                      },
                    ),
                    if (_userRoleForDisplay == 'employee')
                      TextFormField(
                        controller: _positionController,
                        decoration: const InputDecoration(labelText: 'Должность (например, Разработчик)'),
                      ),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Телефон'),
                    ),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'Город'),
                    ),
                    TextFormField(
                      controller: _summaryController,
                      decoration: const InputDecoration(labelText: 'Краткое описание'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateProfile,
                      child: const Text('Сохранить'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
