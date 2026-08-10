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
    required this.icon,
  });

  final String name;
  final String description;
  final String icon;
}

const member = Member(
  firstName: 'John',
  fullName: 'John Doe',
  email: 'john.doe@email.com',
  phone: '+351 900 000 000',
  status: 'Active',
  memberId: 'BJZ-2048',
  tier: 'Bajatzu Member',
  memberSince: 'Mar 2024',
);

const donationPresets = [10, 20, 50, 100];

const socials = [
  SocialLink(
    name: 'Facebook',
    description: 'Visit our Facebook',
    icon: 'facebook',
  ),
  SocialLink(
    name: 'Google',
    description: 'Visit our Google page',
    icon: 'google',
  ),
  SocialLink(
    name: 'TripAdvisor',
    description: 'Visit us on TripAdvisor',
    icon: 'tripadvisor',
  ),
];
