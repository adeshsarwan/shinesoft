import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/intl.dart';
import 'package:videodownloader/core/constants/prefs_constants.dart';
import 'package:videodownloader/core/state/premium_state.dart';
import 'package:videodownloader/core/storage/shared_preferences/shared_prefs.dart';
import 'package:videodownloader/core/theme/color_utility.dart';
import 'package:videodownloader/l10n/app_localizations.dart';
import 'package:videodownloader/screens/auth/login_screen.dart';
import 'package:videodownloader/screens/home_screen/home_screen.dart';
import 'package:videodownloader/services/api_client/api_client.dart';
import 'package:videodownloader/services/models/stripe_payment_model/get_plans_model.dart';
import 'package:videodownloader/services/stripe_services/create_payment_intent_service/create_payment_intent_service.dart';
import 'package:videodownloader/services/stripe_services/get_plans_service/get_plans_service.dart';
import 'package:videodownloader/services/stripe_services/payment_status_service/payment_status_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String selectedPlan = "yearly";

  bool _isLoading = false;

  final ApiClient _apiClient = ApiClient();
  late final GetPlansService _getPlansService;
  late final CreatePaymentIntentService _createPaymentIntentService;
  late final PaymentStatusService _paymentStatusService;

  Map<String, Data> _plansByType = {};

  @override
  void initState() {
    super.initState();
    _getPlansService = GetPlansService(apiClient: _apiClient);
    _createPaymentIntentService =
        CreatePaymentIntentService(apiClient: _apiClient);
    _paymentStatusService = PaymentStatusService(apiClient: _apiClient);
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final model = await _getPlansService.getPlans();
    if (!mounted || model?.data == null) return;
    final map = <String, Data>{};
    for (final p in model!.data!) {
      final t = p.planType;
      if (t != null && t.isNotEmpty) {
        map[t] = p;
      }
    }
    setState(() => _plansByType = map);
  }

  Data? _plan(String planType) => _plansByType[planType];

  String _displayPriceForPlan(String planType) {
    final p = _plan(planType);
    final amountStr = p?.amount;
    final currency = (p?.currency ?? 'usd').toUpperCase();
    if (amountStr == null || amountStr.isEmpty) {
      return '—';
    }
    final amount = double.tryParse(amountStr);
    if (amount == null) {
      return '—';
    }
    try {
      return NumberFormat.simpleCurrency(name: currency).format(amount);
    } catch (_) {
      return '—';
    }
  }

  bool _canPayForSelectedPlan() {
    final p = _plan(selectedPlan);
    return p?.id != null &&
        p!.id!.isNotEmpty &&
        p.amount != null &&
        p.amount!.isNotEmpty;
  }

  String? _extractClientSecret(dynamic root) {
    if (root is! Map) return null;
    final map = Map<String, dynamic>.from(root);
    final direct = map['client_secret'];
    if (direct is String && direct.isNotEmpty) return direct;
    final data = map['data'];
    if (data is Map) {
      final d = Map<String, dynamic>.from(data);
      final cs = d['client_secret'];
      if (cs is String && cs.isNotEmpty) return cs;
      final pi = d['payment_intent'];
      if (pi is Map) {
        final pic = pi['client_secret'];
        if (pic is String && pic.isNotEmpty) return pic;
      }
    }
    return null;
  }

  String? _extractPaymentIntentId(dynamic root) {
    if (root is! Map) return null;
    final map = Map<String, dynamic>.from(root);
    final direct = map['payment_intent_id'];
    if (direct is String && direct.isNotEmpty) return direct;
    final data = map['data'];
    if (data is Map) {
      final d = Map<String, dynamic>.from(data);
      final id = d['payment_intent_id'];
      if (id is String && id.isNotEmpty) return id;
    }
    return null;
  }

  Future<({String clientSecret, String paymentIntentId})?>
      _createPaymentIntentResult(Data plan) async {
    final planId = plan.id;
    if (planId == null || planId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid plan. Please try again.')),
        );
      }
      return null;
    }

    final response =
        await _createPaymentIntentService.createPaymentIntent(planId);
    if (response['success'] != true) {
      if (mounted) {
        final msg = response['message']?.toString() ??
            'Could not start payment. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
      return null;
    }
    final payload = response['data'];
    final secret = _extractClientSecret(payload);
    final paymentIntentId = _extractPaymentIntentId(payload);
    if (secret == null ||
        secret.isEmpty ||
        paymentIntentId == null ||
        paymentIntentId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid payment response. Please try again.'),
          ),
        );
      }
      return null;
    }
    await SharedPrefs.saveData(
      PrefsConstants.lastPaymentIntentId,
      paymentIntentId,
    );
    return (clientSecret: secret, paymentIntentId: paymentIntentId);
  }

  bool _isUserLoggedInWithToken() {
    final loggedIn = SharedPrefs.getData(PrefsConstants.isLoggedIn) == true;
    final token = SharedPrefs.getData(PrefsConstants.accessToken) as String?;
    return loggedIn && token != null && token.isNotEmpty;
  }

  Future<void> _makePayment() async {
    if (_isLoading) return;

    if (!_isUserLoggedInWithToken()) {
      if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to continue'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (context) => const LoginScreen()),
      );
      return;
    }

    final plan = _plan(selectedPlan);
    if (plan == null || !_canPayForSelectedPlan()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plans are still loading. Please wait a moment.'),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final intent = await _createPaymentIntentResult(plan);
      if (intent == null) {
        return;
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: intent.clientSecret,
          merchantDisplayName: 'SnapDock',
        ),
      );

      await _displayPaymentSheet(intent.paymentIntentId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment setup failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatAmount(dynamic amountRaw, dynamic currencyRaw) {
    final currency = currencyRaw?.toString().toUpperCase();
    final amount = double.tryParse(amountRaw?.toString() ?? '');
    if (amount == null) return amountRaw?.toString() ?? '—';
    if (currency == null || currency.isEmpty) return amount.toString();
    try {
      return NumberFormat.simpleCurrency(name: currency).format(amount);
    } catch (_) {
      return '$amount $currency';
    }
  }

  Future<void> _showPaymentStatusDialog({
    required String paymentIntentId,
  }) async {
    final response = await _paymentStatusService.getPaymentStatus(paymentIntentId);
    if (!mounted) return;

    String status = '—';
    String amount = '—';
    String productName = '—';

    if (response['success'] == true) {
      final root = response['data'];
      if (root is Map) {
        final rootMap = Map<String, dynamic>.from(root);
        final data = rootMap['data'];
        final dataMap =
            data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

        status = (dataMap['status'] ?? rootMap['status'] ?? '—').toString();
        amount = _formatAmount(dataMap['amount'], dataMap['currency']);
        productName = (dataMap['product_name'] ??
                dataMap['product'] ??
                dataMap['plan_name'] ??
                '—')
            .toString();
      }
    } else {
      status = 'Failed';
      productName = response['message']?.toString() ?? '—';
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ColorUtils.hexToColor("C7DCFF"),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Status: $status',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Amount: $amount',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Product: $productName',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: GradientHelper.mainGradient(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomePageScreen()),
      (route) => false,
    );
  }

  Future<void> _displayPaymentSheet(String paymentIntentId) async {
    try {
      await Stripe.instance.presentPaymentSheet();

      PremiumState.isPremium.value = true;
      await SharedPrefs.saveData(PrefsConstants.isPremiumUser, true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Successful')),
        );
        await _showPaymentStatusDialog(paymentIntentId: paymentIntentId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed or cancelled: $e')),
        );
      }
    }
  }

  String _ongoingOfferLine() {
    final price = _displayPriceForPlan('yearly');
    if (price == '—') {
      return 'Auto-renewal — cancel anytime';
    }
    return 'Ongoing offer: $price/year, auto-renewal cancel anytime';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Image.asset('assets/menuicon/backarrow.png',
              height: 30,
              width: 30),
        ),
        title:  Text(
            AppLocalizations.of(context).translate("subscription"),
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const SizedBox(height: 54),
              _premiumHeader(),
              const SizedBox(height: 18),
              _featuresBox(),
              const SizedBox(height: 18),
              _subscriptionPlans(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _ongoingOfferLine(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _continueButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  Widget _premiumHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        /// Background Container (Gradient card)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(left: 16,bottom: 20,top: 20,right: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xff6553A3),
                Color(0xff9451A0),
                Color(0xffC94B9B),
                Color(0xffEE346B),
                Color(0xffF15C22),
                Color(0xffFECD06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const SizedBox(width: 120), // reserve space for the image overlap
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [

                    Padding(
                      padding: EdgeInsets.only(left: 16,right: 0),
                      child: Text(
                        "SnapDock Premium",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Padding(
                      padding: EdgeInsets.only(left: 16,right: 0),
                      child: Text(
                        "Experience without interruptions",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        /// Positioned Image (Overflow style)
        Positioned(
          left: 28,
          top: -50, // pull image upward
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              "assets/images/premium.png",
              height: 154,
              width: 107,
            ),
          ),
        ),
      ],
    );
  }

  Widget _featuresBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
         border: Border.all(color: Colors.grey.shade300, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _FeatureItem(text: "No Ad Interruptions"),
          _FeatureItem(text: "Unlimited batch downloads"),
          _FeatureItem(text: "Background auto download"),
          _FeatureItem(text: "Download without leaving Instagram"),
        ],
      ),
    );
  }

  Widget _subscriptionPlans() {
    return Column(
      children: [
        _planTile("weekly", "Weekly", _displayPriceForPlan("weekly")),
        const SizedBox(height: 12),
        _planTile("monthly", "Monthly", _displayPriceForPlan("monthly")),
        const SizedBox(height: 12),
        _planTile("yearly", "Yearly", _displayPriceForPlan("yearly"),
            highlight: true),
      ],
    );
  }

  Widget _planTile(String id, String title, String price, {bool highlight = false}) {
    final isSelected = selectedPlan == id;
    return InkWell(
      onTap: () => setState(() => selectedPlan = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? Colors.deepPurple.withOpacity(.08) : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text(price, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _continueButton() {
    return GestureDetector(
      onTap: _makePayment,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff6553A3),
              Color(0xff9451A0),
              Color(0xffC94B9B),
              Color(0xffEE346B),
              Color(0xffF15C22),
              Color(0xffFECD06),
            ],
          ),
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        child: Center(
          child: Text(
            AppLocalizations.of(context).translate("continueButton"),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;
  const _FeatureItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            child: Image.asset("assets/images/checkbox.png",height: 24,
              width: 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        ],
      ),
    );
  }
}
