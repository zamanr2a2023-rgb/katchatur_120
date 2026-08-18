class DonateConfig {
  const DonateConfig({
    required this.title,
    required this.description,
    required this.currency,
    required this.presets,
    required this.defaultAmount,
    required this.paymentProvider,
    required this.paymentSubtitle,
    required this.paymentDisclaimer,
    required this.memberBenefitPercent,
    required this.memberBenefitTitle,
    required this.memberBenefitDescription,
  });

  final String title;
  final String description;
  final String currency;
  final List<int> presets;
  final int defaultAmount;
  final String paymentProvider;
  final String paymentSubtitle;
  final String paymentDisclaimer;
  final int memberBenefitPercent;
  final String memberBenefitTitle;
  final String memberBenefitDescription;

  static const defaults = DonateConfig(
    title: 'Support Our Chef',
    description:
        'If you enjoyed your experience at Bajatzu, you can show your appreciation with a donation.',
    currency: '€',
    presets: [10, 20, 50, 100],
    defaultAmount: 20,
    paymentProvider: 'Stripe',
    paymentSubtitle:
        'Card details are handled securely by Stripe, never by Bajatzu.',
    paymentDisclaimer:
        'You will complete payment on the secure Stripe checkout page.',
    memberBenefitPercent: 5,
    memberBenefitTitle: 'Enjoy 5% Off',
    memberBenefitDescription:
        'As a Bajatzu member, you receive 5% off when visiting the restaurant.',
  );

  factory DonateConfig.fromMap(Map<String, dynamic> data) {
    final rawPresets = data['presets'];
    final presets = <int>[];
    if (rawPresets is List) {
      for (final item in rawPresets) {
        if (item is num) presets.add(item.toInt());
      }
    }

    final percent =
        (data['memberBenefitPercent'] as num?)?.toInt() ??
            defaults.memberBenefitPercent;

    return DonateConfig(
      title: (data['title'] as String?)?.trim().isNotEmpty == true
          ? (data['title'] as String).trim()
          : defaults.title,
      description: (data['description'] as String?)?.trim().isNotEmpty == true
          ? (data['description'] as String).trim()
          : defaults.description,
      currency: (data['currency'] as String?)?.trim().isNotEmpty == true
          ? (data['currency'] as String).trim()
          : defaults.currency,
      presets: presets.isEmpty ? defaults.presets : presets,
      defaultAmount:
          (data['defaultAmount'] as num?)?.toInt() ?? defaults.defaultAmount,
      paymentProvider:
          _stripeProvider((data['paymentProvider'] as String?)?.trim()),
      paymentSubtitle: _withoutSumUp(
        data['paymentSubtitle'] as String?,
        defaults.paymentSubtitle,
      ),
      paymentDisclaimer: _withoutSumUp(
        data['paymentDisclaimer'] as String?,
        defaults.paymentDisclaimer,
      ),
      memberBenefitPercent: percent,
      memberBenefitTitle:
          (data['memberBenefitTitle'] as String?)?.trim().isNotEmpty == true
              ? (data['memberBenefitTitle'] as String).trim()
              : 'Enjoy $percent% Off',
      memberBenefitDescription:
          (data['memberBenefitDescription'] as String?)?.trim().isNotEmpty ==
                  true
              ? (data['memberBenefitDescription'] as String).trim()
              : 'As a Bajatzu member, you receive $percent% off when visiting the restaurant.',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'currency': currency,
      'presets': presets,
      'defaultAmount': defaultAmount,
      'paymentProvider': paymentProvider,
      'paymentSubtitle': paymentSubtitle,
      'paymentDisclaimer': paymentDisclaimer,
      'memberBenefitPercent': memberBenefitPercent,
      'memberBenefitTitle': memberBenefitTitle,
      'memberBenefitDescription': memberBenefitDescription,
    };
  }

  static String _stripeProvider(String? value) {
    if (value == null || value.isEmpty || value.toLowerCase() == 'sumup') {
      return defaults.paymentProvider;
    }
    return value;
  }

  static String _withoutSumUp(String? value, String fallback) {
    final text = value?.trim() ?? '';
    if (text.isEmpty || text.toLowerCase().contains('sumup')) return fallback;
    return text;
  }
}
