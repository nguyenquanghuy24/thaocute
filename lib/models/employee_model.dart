class Employee {
  const Employee({
    required this.id,
    required this.employeeCode,
    required this.email,
    required this.name,
    this.role = 'staff',
    this.active = true,
  });
  final String id;
  final String employeeCode;
  final String email;
  final String name;
  final String role;
  final bool active;
  factory Employee.fromMap(String id, Map<String, dynamic> map) => Employee(
    id: id,
    employeeCode: map['employeeCode'] as String? ?? '',
    email: map['email'] as String? ?? '',
    name: map['name'] as String? ?? '',
    role: map['role'] as String? ?? 'staff',
    active: map['active'] as bool? ?? true,
  );
  Map<String, dynamic> toMap() => {
    'employeeCode': employeeCode,
    'email': email,
    'name': name,
    'role': role,
    'active': active,
  };
}
