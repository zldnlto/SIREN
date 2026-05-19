class User {
  const User({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.role,
  });

  final String id;
  final String employeeId;
  final String name;
  final String role;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        employeeId: json['employee_id'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
      );
}
