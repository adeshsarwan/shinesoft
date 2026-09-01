/// User profile returned by `GET /auth/profile`.
class UserProfile {
  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.phone,
    this.avatarUrl,
    this.isPremium = false,
    this.subscriptionPlan,
    this.renewalDate,
    this.billingCycle,
    this.subscriptionAmount,
    this.subscriptionAmountFormatted,
    this.subscriptionCurrency,
    this.paymentMethod,
  });

  final String id;
  final String name;
  final String email;
  final String? role;
  final String? phone;
  final String? avatarUrl;
  final bool isPremium;
  final String? subscriptionPlan;
  final DateTime? renewalDate;
  final String? billingCycle;
  final double? subscriptionAmount;
  final String? subscriptionAmountFormatted;
  final String? subscriptionCurrency;
  final String? paymentMethod;

  /// Whether this profile should not see ads (matches Settings subscription UI).
  bool get grantsAdFreeAccess {
    if (isPremium) return true;

    final plan = (subscriptionPlan ?? '').toLowerCase().trim();
    if (plan.isNotEmpty) {
      final isExplicitFree = plan == 'free' ||
          plan == 'free plan' ||
          (plan.contains('free') &&
              !plan.contains('ads-free') &&
              !plan.contains('ads free') &&
              !plan.contains('ads_free'));
      if (!isExplicitFree &&
          (plan.contains('premium') ||
              plan.contains('pro') ||
              plan.contains('paid') ||
              plan.contains('yearly') ||
              plan.contains('annual') ||
              plan.contains('ads-free') ||
              plan.contains('ads free') ||
              plan.contains('ads_free'))) {
        return true;
      }
    }

    if (renewalDate != null &&
        renewalDate!.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
      return true;
    }

    if ((subscriptionAmount ?? 0) > 0) {
      if (plan.isEmpty || !plan.contains('free')) return true;
    }

    return false;
  }

  /// Best-effort premium detection from API maps (profile or login `data`).
  static bool inferPremiumFromMap(Map<String, dynamic> json) {
    bool parseBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.toLowerCase();
        return s == 'true' || s == '1' || s == 'yes' || s == 'active';
      }
      return false;
    }

    bool planNameIsPremium(String raw) {
      final plan = raw.toLowerCase();
      if (plan.isEmpty) return false;
      if (plan == 'free' || plan == 'free plan') return false;
      return plan.contains('premium') ||
          plan.contains('ads-free') ||
          plan.contains('ads free') ||
          plan.contains('ads_free') ||
          plan.contains('pro') ||
          plan == 'paid' ||
          plan.contains('yearly') ||
          plan.contains('annual');
    }

    for (final key in [
      'isPremium',
      'is_premium',
      'hasPremium',
      'has_premium',
      'isSubscribed',
      'is_subscribed',
      'hasSubscription',
      'has_subscription',
      'adsFree',
      'ads_free',
      'adFree',
      'ad_free',
    ]) {
      if (parseBool(json[key])) return true;
    }

    final nestedUser = json['user'];
    if (nestedUser is Map) {
      if (inferPremiumFromMap(Map<String, dynamic>.from(nestedUser))) return true;
    }

    final sub = json['subscription'];
    if (sub is Map) {
      final m = Map<String, dynamic>.from(sub);
      final plan = (m['plan'] ??
              m['planName'] ??
              m['name'] ??
              m['type'] ??
              m['tier'] ??
              '')
          .toString();
      if (planNameIsPremium(plan)) return true;

      final status =
          (m['status'] ?? m['state'] ?? m['subscriptionStatus'] ?? '')
              .toString()
              .toLowerCase();
      if (status == 'active' ||
          status == 'trialing' ||
          status == 'paid' ||
          status == 'subscribed') {
        if (!plan.toLowerCase().contains('free') || planNameIsPremium(plan)) {
          return true;
        }
      }

      if (parseBool(m['isActive']) ||
          parseBool(m['active']) ||
          parseBool(m['isPremium'])) {
        return true;
      }
    }

    final plan =
        (json['plan'] ?? json['subscriptionPlan'] ?? json['planName'] ?? '')
            .toString();
    if (planNameIsPremium(plan)) return true;

    final role = (json['role'] ?? json['userType'] ?? json['accountType'] ?? '')
        .toString()
        .toLowerCase();
    if (role == 'premium' ||
        role == 'subscriber' ||
        role == 'paid' ||
        role == 'pro') {
      return true;
    }

    return false;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v == null ? '' : v.toString();
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is int) {
        final ms = v < 1000000000000 ? v * 1000 : v;
        return DateTime.fromMillisecondsSinceEpoch(ms);
      }
      if (v is String && v.trim().isNotEmpty) {
        return DateTime.tryParse(v.trim());
      }
      return null;
    }

    double? parseAmount(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    String? firstNonEmpty(List<dynamic> values) {
      for (final v in values) {
        final text = v?.toString().trim() ?? '';
        if (text.isNotEmpty) return text;
      }
      return null;
    }

    final subscriptionRaw = json['subscription'];
    final sub = subscriptionRaw is Map
        ? Map<String, dynamic>.from(subscriptionRaw)
        : const <String, dynamic>{};
    final paymentRaw = json['payment'];
    final payment = paymentRaw is Map
        ? Map<String, dynamic>.from(paymentRaw)
        : const <String, dynamic>{};
    return UserProfile(
      id: s(json['_id'] ?? json['id']),
      name: s(json['name'] ?? json['fullName']),
      email: s(json['email']),
      role: json['role'] == null ? null : s(json['role']),
      phone: json['phone'] != null
          ? s(json['phone'])
          : (json['mobile'] != null ? s(json['mobile']) : null),
      avatarUrl: json['avatar'] != null
          ? s(json['avatar'])
          : (json['image'] != null
              ? s(json['image'])
              : (json['profileImage'] != null ? s(json['profileImage']) : null)),
      isPremium: inferPremiumFromMap(json),
      subscriptionPlan: firstNonEmpty([
        sub['plan'],
        sub['type'],
        sub['tier'],
        json['subscriptionPlan'],
        json['plan'],
      ]),
      renewalDate: parseDate(
        sub['renewalDate'] ??
            sub['nextBillingDate'] ??
            sub['currentPeriodEnd'] ??
            sub['expiresAt'] ??
            sub['endDate'] ??
            json['renewalDate'] ??
            json['nextBillingDate'],
      ),
      billingCycle: firstNonEmpty([
        sub['interval'],
        sub['billingCycle'],
        sub['cycle'],
        sub['duration'],
      ]),
      subscriptionAmount: parseAmount(
        sub['amount'] ??
            sub['price'] ??
            sub['monthlyCost'] ??
            sub['cost'] ??
            payment['amount'] ??
            json['subscriptionAmount'],
      ),
      subscriptionAmountFormatted: firstNonEmpty([
        sub['amountFormatted'],
        sub['formattedAmount'],
        payment['amountFormatted'],
        payment['formattedAmount'],
        json['subscriptionAmountFormatted'],
        json['amountFormatted'],
      ]),
      subscriptionCurrency: firstNonEmpty([
        sub['currency'],
        payment['currency'],
        json['currency'],
      ]),
      paymentMethod: firstNonEmpty([
        sub['paymentMethod'],
        sub['method'],
        payment['method'],
        json['paymentMethod'],
        json['lastPaymentMethod'],
      ]),
    );
  }

  /// Two-letter initials from [name], falling back to [email] local-part.
  String get initials {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        final a = parts[0].isNotEmpty ? parts[0][0] : '';
        final b = parts[1].isNotEmpty ? parts[1][0] : '';
        return ('$a$b').toUpperCase();
      }
      if (trimmed.length >= 2) {
        return trimmed.substring(0, 2).toUpperCase();
      }
      if (trimmed.isNotEmpty) return trimmed[0].toUpperCase();
    }
    final e = email.trim();
    if (e.isEmpty) return '?';
    final local = e.split('@').first;
    if (local.length >= 2) return local.substring(0, 2).toUpperCase();
    return local[0].toUpperCase();
  }

  /// Primary line for headers when [name] is empty.
  String get displayName {
    if (name.trim().isNotEmpty) return name.trim();
    if (email.isNotEmpty) return email;
    return 'User';
  }
}
