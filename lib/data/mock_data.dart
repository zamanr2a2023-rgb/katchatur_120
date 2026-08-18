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
