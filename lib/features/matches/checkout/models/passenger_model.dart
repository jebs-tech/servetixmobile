class Passenger {
  String name;
  String email;
  String phone;
  String gender;
  String category;

  Passenger({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.gender = '',
    this.category = '',
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "email": email,
      "phone": phone,
      "gender": gender,
      "category": category,
    };
  }
}
