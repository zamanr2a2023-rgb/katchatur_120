class Member {
  const Member({
    required this.firstName,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.status,
    required this.memberId,
    required this.tier,
    required this.memberSince,
  });

  final String firstName;
  final String fullName;
  final String email;
  final String phone;
  final String status;
  final String memberId;
  final String tier;
  final String memberSince;
}

class SocialLink {
  const SocialLink({
    required this.name,
    required this.description,
    required this.url,
  });

  final String name;
  final String description;
  final String url;
}

const member = Member(
  firstName: 'John',
  fullName: 'John Doe',
  email: 'john.doe@email.com',
  phone: '+351 900 000 000',
  status: 'Active',
  memberId: 'BJZ-2048',
  tier: 'Founding Member',
  memberSince: 'Mar 2024',
);

const donationPresets = [10, 20, 50, 100];

const socials = [
  SocialLink(
    name: 'Facebook',
    description: 'News, evenings and events',
    url: 'https://facebook.com',
  ),
  SocialLink(
    name: 'Google',
    description: 'Leave a review',
    url: 'https://google.com',
  ),
  SocialLink(
    name: 'TripAdvisor',
    description: 'Share your visit',
    url: 'https://tripadvisor.com',
  ),
  SocialLink(
    name: 'Instagram',
    description: 'Plates, kitchen & atmosphere',
    url: 'https://instagram.com',
  ),
];
