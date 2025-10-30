class TrainerProfileData {
  TrainerProfileData({
    required this.name,
    required this.title,
    required this.bio,
    required this.email,
    required this.phone,
    required this.location,
    this.clients = 24,
    this.plans = 33,
    this.rating = 4.9,
  });

  String name;
  String title;
  String bio;
  String email;
  String phone;
  String location;
  int clients;
  int plans;
  double rating;
}

class ProfileStore {
  static TrainerProfileData trainer = TrainerProfileData(
    name: 'Coach Jason Miller',
    title: 'Certified Personal Trainer',
    bio: 'Passionate fitness coach specializing in strength training and nutrition. Helping clients transform their lives for 8+ years.',
    email: 'jason.miller@activextra.com',
    phone: '+1 (555) 123-4567',
    location: 'Los Angeles, CA',
  );
}


