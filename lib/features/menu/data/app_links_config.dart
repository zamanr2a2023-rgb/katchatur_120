class AppSocialLink {
  const AppSocialLink({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.icon,
    this.enabled = true,
    this.order = 0,
  });

  final String id;
  final String name;
  final String description;
  final String url;
  final String icon;
  final bool enabled;
  final int order;

  factory AppSocialLink.fromMap(Map<String, dynamic> data, {String? id}) {
    return AppSocialLink(
      id: id ?? (data['id'] as String?) ?? '',
      name: (data['name'] as String?) ?? 'Link',
      description: (data['description'] as String?) ?? '',
      url: (data['url'] as String?) ?? '',
      icon: (data['icon'] as String?) ?? 'link',
      enabled: data['enabled'] as bool? ?? true,
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'url': url,
      'icon': icon,
      'enabled': enabled,
      'order': order,
    };
  }
}

class AppLinksConfig {
  const AppLinksConfig({
    required this.menuUrl,
    required this.socials,
  });

  final String menuUrl;
  final List<AppSocialLink> socials;

  static const defaults = AppLinksConfig(
    menuUrl: 'https://menus.menulingua.com/142416/en',
    socials: [
      AppSocialLink(
        id: 'facebook',
        name: 'Facebook',
        description: 'Visit our Facebook',
        url: 'https://www.facebook.com/bistrobajatzu/',
        icon: 'facebook',
        order: 1,
      ),
      AppSocialLink(
        id: 'instagram',
        name: 'Instagram',
        description: 'Follow us on Instagram',
        url:
            'https://www.instagram.com/bajatzu?igsh=MXBuajlndG1zZ3UyZA%3D%3D&utm_source=qr',
        icon: 'instagram',
        order: 2,
      ),
      AppSocialLink(
        id: 'google',
        name: 'Google',
        description: 'Visit our Google page',
        url: 'https://share.google/xKFPYqu61yus8Zwws',
        icon: 'google',
        order: 3,
      ),
      AppSocialLink(
        id: 'tripadvisor',
        name: 'TripAdvisor',
        description: 'Visit us on TripAdvisor',
        url:
            'https://www.tripadvisor.com/Restaurant_Review-g188672-d2649018-Reviews-Bajatzu-Ostend_West_Flanders_Province.html',
        icon: 'tripadvisor',
        order: 4,
      ),
    ],
  );

  factory AppLinksConfig.fromMap(Map<String, dynamic> data) {
    final rawSocials = data['socials'];
    final socials = <AppSocialLink>[];

    if (rawSocials is List) {
      for (final item in rawSocials) {
        if (item is Map<String, dynamic>) {
          socials.add(AppSocialLink.fromMap(item));
        } else if (item is Map) {
          socials.add(
            AppSocialLink.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    socials.sort((a, b) => a.order.compareTo(b.order));

    return AppLinksConfig(
      menuUrl: (data['menuUrl'] as String?)?.trim().isNotEmpty == true
          ? (data['menuUrl'] as String).trim()
          : defaults.menuUrl,
      socials: socials.isEmpty ? defaults.socials : socials,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuUrl': menuUrl,
      'socials': socials.map((s) => s.toMap()).toList(),
    };
  }

  List<AppSocialLink> get enabledSocials =>
      socials.where((s) => s.enabled && s.url.trim().isNotEmpty).toList();
}
