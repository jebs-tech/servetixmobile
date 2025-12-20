class Passenger {
  String name;
  String email;
  String phone;
  String gender;
  String category;

  Passenger({
    required this.name,
    this.email = '',
    this.phone = '',
    this.gender = '',
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'gender': gender,
        'category': category,
      };
}
