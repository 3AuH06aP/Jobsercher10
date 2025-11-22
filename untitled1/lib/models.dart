class Resume {
  final int id;
  final String userId;
  final String fullName;
  final String position;
  final String skills;
  final String experience;

  Resume({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.position,
    required this.skills,
    required this.experience,
  });

  Resume.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        userId = json['user_id'],
        fullName = json['full_name'],
        position = json['position'] ?? '',
        skills = json['skills'],
        experience = json['experience'];
}

class Vacancy {
  final int id;
  final String title;
  final String company;
  final String city;
  final String? salary;
  final String description;

  Vacancy(
      {required this.id,
      required this.title,
      required this.company,
      required this.city,
      this.salary,
      required this.description});

  Vacancy.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'],
        company = json['company'],
        city = json['city'],
        salary = json['salary'],
        description = json['description'];
}

class Application {
  final int id;
  final int vacancyId;
  final int resumeId;
  final String status;
  final Vacancy vacancy;
  final Resume resume;

  Application.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        vacancyId = json['vacancy_id'],
        resumeId = json['resume_id'],
        status = json['status'],
        vacancy = Vacancy.fromJson(json['vacancies']),
        resume = Resume.fromJson(json['resumes']);
}
