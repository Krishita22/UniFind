part of '../main.dart';

// ─── PAYMENT METHOD ───────────────────────────────────────────────────────────

enum _PayMethod { card, applePay, googlePay }

// ─── SCREEN ───────────────────────────────────────────────────────────────────

class PaymentScreen extends StatefulWidget {
  final MarketplaceItem item;
  final int buyerId;
  final int sellerId;
  final String buyerEmail;

  const PaymentScreen({
    super.key,
    required this.item,
    required this.buyerId,
    required this.sellerId,
    required this.buyerEmail,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with SingleTickerProviderStateMixin {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl    = TextEditingController();
  final _zipCtrl     = TextEditingController();
  final _cardCtrl    = TextEditingController();
  final _expiryCtrl  = TextEditingController();
  final _cvvCtrl     = TextEditingController();

  _PayMethod _method   = _PayMethod.card;
  bool _processing     = false;
  bool _submitted      = false;
  String? _error;
  String _detectedBrand = '';   // visa / mastercard / amex / discover / ''

  late final AnimationController _btnAnim;
  late final Animation<double>    _btnScale;

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = widget.buyerEmail;
    _btnAnim  = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _btnScale = Tween<double>(begin: 1.0, end: 0.97).animate(
        CurvedAnimation(parent: _btnAnim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _addressCtrl.dispose();
    _cityCtrl.dispose(); _zipCtrl.dispose();   _cardCtrl.dispose();
    _expiryCtrl.dispose(); _cvvCtrl.dispose(); _btnAnim.dispose();
    super.dispose();
  }

  // ── card brand detection ──────────────────────────────────────────────────

  String _detectBrand(String digits) {
    if (digits.startsWith('4'))                                  return 'visa';
    if (RegExp(r'^5[1-5]').hasMatch(digits))                     return 'mastercard';
    if (RegExp(r'^2(2[2-9]|[3-6]|7[01]|720)').hasMatch(digits)) return 'mastercard';
    if (RegExp(r'^3[47]').hasMatch(digits))                      return 'amex';
    if (RegExp(r'^6(011|5)').hasMatch(digits))                   return 'discover';
    return '';
  }

  // ── card number formatting ────────────────────────────────────────────────

  void _formatCard(String v) {
    final digits = v.replaceAll(RegExp(r'\D'), '');
    final brand  = _detectBrand(digits);
    // Amex: 4-6-5 grouping; others: 4-4-4-4
    final groups = brand == 'amex' ? [4, 6, 5] : [4, 4, 4, 4];
    final buf = StringBuffer();
    int pos = 0;
    for (final g in groups) {
      if (pos >= digits.length) break;
      if (buf.isNotEmpty) buf.write(' ');
      buf.write(digits.substring(pos, (pos + g).clamp(0, digits.length)));
      pos += g;
    }
    final formatted = buf.toString();
    if (formatted != v) {
      _cardCtrl.value = _cardCtrl.value.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    if (brand != _detectedBrand) setState(() => _detectedBrand = brand);
  }

  void _formatExpiry(String v) {
    final digits = v.replaceAll(RegExp(r'\D'), '');
    String formatted = digits;
    if (digits.length > 2) {
      formatted = '${digits.substring(0, 2)}/${digits.substring(2, digits.length.clamp(2, 4))}';
    }
    if (formatted != v) {
      _expiryCtrl.value = _expiryCtrl.value.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  // ── submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_method == _PayMethod.card && !_formKey.currentState!.validate()) return;
    await _btnAnim.forward();
    await _btnAnim.reverse();
    setState(() { _processing = true; _error = null; });

    try {
      final billingAddress = _method == _PayMethod.card
          ? '${_addressCtrl.text.trim()}, ${_cityCtrl.text.trim()} ${_zipCtrl.text.trim()}'
          : '';
      final buyerName  = _method == _PayMethod.card ? _nameCtrl.text.trim()  : '';
      final buyerEmail = _method == _PayMethod.card ? _emailCtrl.text.trim() : widget.buyerEmail;

      final offer = await createOffer(
        listingId:      int.tryParse(widget.item.id) ?? 0,
        buyerId:        widget.buyerId,
        sellerId:       widget.sellerId,
        amount:         widget.item.price,
        buyerName:      buyerName,
        buyerEmail:     buyerEmail,
        billingAddress: billingAddress,
        itemTitle:      widget.item.title,
      );

      try {
        await sendPaymentInvoice(
          offerId:        offer['offer_id']?.toString() ?? '',
          buyerEmail:     buyerEmail,
          buyerName:      buyerName,
          itemTitle:      widget.item.title,
          itemPrice:      widget.item.price,
          itemCategory:   widget.item.category,
          itemCondition:  widget.item.condition,
          itemImage:      widget.item.image,
          billingAddress: billingAddress,
        );
      } catch (_) {
        // Invoice email failure is non-fatal — proceed to confirmation
      }

      if (!mounted) return;
      setState(() { _submitted = true; _processing = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _processing = false;
      });
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _OrderConfirmationPage(
        item:       widget.item,
        buyerEmail: _method == _PayMethod.card ? _emailCtrl.text.trim() : widget.buyerEmail,
        onDone:     () => Navigator.pop(context),
      );
    }

    return Scaffold(
      backgroundColor: cNavBg,
      body: Column(
        children: [
          // ── dark header ──────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: _buildHeader(context),
          ),

          // ── white card body ──────────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: cBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── express checkout ─────────────────────────────
                      _buildExpressCheckout(),
                      const SizedBox(height: 20),

                      // ── divider ──────────────────────────────────────
                      _OrDivider(),
                      const SizedBox(height: 20),
                      _buildCardForm(),

                      // ── error ─────────────────────────────────────────
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        _ErrorBanner(message: _error!),
                      ],

                      const SizedBox(height: 24),

                      // ── pay button ────────────────────────────────────
                      _buildPayButton(),

                      const SizedBox(height: 16),

                      // ── secure note ───────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_rounded, size: 11, color: Colors.grey.shade400),
                          const SizedBox(width: 5),
                          Text(
                            'Secured by UniFind · 256-bit encryption',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // back + logo row
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.white),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(Icons.shield_rounded, size: 12, color: Colors.greenAccent.shade200),
                  const SizedBox(width: 4),
                  Text('Secure checkout',
                      style: TextStyle(fontSize: 11, color: Colors.greenAccent.shade200, fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // item row
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 52, height: 52,
                  child: Image.network(
                    widget.item.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.white.withValues(alpha: 0.1),
                      child: const Icon(Icons.image_not_supported, color: Colors.white38, size: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 3),
                    Text(widget.item.condition,
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55))),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '\$${widget.item.price.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // pending notice
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, size: 13, color: Colors.white.withValues(alpha: 0.6)),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Payment is held until the meetup is marked complete.',
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7), height: 1.4),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ── express checkout ──────────────────────────────────────────────────────

  Future<void> _expressCheckout(_PayMethod method) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ExpressConfirmSheet(item: widget.item, method: method),
    );
    if (confirmed != true || !mounted) return;
    setState(() { _method = method; });
    await _submit();
  }

  Widget _buildExpressCheckout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('EXPRESS CHECKOUT',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: cMuted, letterSpacing: 1.0)),
        const SizedBox(height: 10),
        // Apple Pay — full width, authentic black pill
        _ApplePayButton(onTap: () => _expressCheckout(_PayMethod.applePay)),
        const SizedBox(height: 10),
        // Google Pay — full width, white with border
        _GooglePayButton(onTap: () => _expressCheckout(_PayMethod.googlePay)),
      ],
    );
  }

  // ── card form ─────────────────────────────────────────────────────────────

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── contact ──────────────────────────────────────────────────────
        _FieldLabel('Contact information'),
        const SizedBox(height: 8),
        _StripeField(
          ctrl: _emailCtrl,
          hint: 'Email address',
          keyboard: TextInputType.emailAddress,
          icon: Icons.email_outlined,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 8),
        _StripeField(
          ctrl: _nameCtrl,
          hint: 'Full name',
          icon: Icons.person_outline_rounded,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
        ),
        const SizedBox(height: 20),

        // ── card details ──────────────────────────────────────────────────
        _FieldLabel('Card information'),
        const SizedBox(height: 8),

        // card number — top of rounded group
        _StripeField(
          ctrl: _cardCtrl,
          hint: '1234 1234 1234 1234',
          keyboard: TextInputType.number,
          onChanged: _formatCard,
          suffix: _CardBrandIcon(brand: _detectedBrand),
          radius: const BorderRadius.vertical(top: Radius.circular(10)),
          validator: (v) {
            final d = (v ?? '').replaceAll(' ', '');
            return d.length < 15 ? 'Enter a valid card number' : null;
          },
        ),

        // expiry + cvv — bottom row of rounded group
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _StripeField(
                  ctrl: _expiryCtrl,
                  hint: 'MM / YY',
                  keyboard: TextInputType.number,
                  onChanged: _formatExpiry,
                  radius: const BorderRadius.only(bottomLeft: Radius.circular(10)),
                  joinTop: true,
                  validator: (v) {
                    final d = (v ?? '').replaceAll('/', '');
                    return d.length < 4 ? 'Enter MM/YY' : null;
                  },
                ),
              ),
              Expanded(
                child: _StripeField(
                  ctrl: _cvvCtrl,
                  hint: 'CVV',
                  keyboard: TextInputType.number,
                  maxLength: 4,
                  joinTop: true,
                  joinLeft: true,
                  radius: const BorderRadius.only(bottomRight: Radius.circular(10)),
                  suffix: Icon(Icons.credit_card_rounded, size: 16, color: Colors.grey.shade400),
                  validator: (v) => ((v ?? '').length < 3) ? 'CVV required' : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── billing ───────────────────────────────────────────────────────
        _FieldLabel('Billing address'),
        const SizedBox(height: 8),
        _StripeField(
          ctrl: _addressCtrl,
          hint: 'Street address',
          icon: Icons.home_outlined,
          radius: const BorderRadius.vertical(top: Radius.circular(10)),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
        ),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: _StripeField(
                  ctrl: _cityCtrl,
                  hint: 'City',
                  joinTop: true,
                  radius: const BorderRadius.only(bottomLeft: Radius.circular(10)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              Expanded(
                flex: 2,
                child: _StripeField(
                  ctrl: _zipCtrl,
                  hint: 'ZIP',
                  joinTop: true,
                  joinLeft: true,
                  keyboard: TextInputType.number,
                  radius: const BorderRadius.only(bottomRight: Radius.circular(10)),
                  validator: (v) => ((v ?? '').trim().length < 5) ? 'Invalid ZIP' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── pay button (card only) ────────────────────────────────────────────────

  Widget _buildPayButton() {
    return ScaleTransition(
      scale: _btnScale,
      child: GestureDetector(
        onTap: _processing ? null : _submit,
        child: AnimatedContainer(
          duration: kFast,
          height: 52,
          decoration: BoxDecoration(
            color: _processing ? cMuted : cNavBg,
            borderRadius: BorderRadius.circular(10),
            boxShadow: _processing ? null : [
              BoxShadow(
                color: cNavBg.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: _processing
                ? const Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    SizedBox(width: 10),
                    Text('Processing...', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  ])
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.lock_rounded, size: 15, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Buy — \$${widget.item.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ]),
          ),
        ),
      ),
    );
  }
}

// ─── APPLE PAY BUTTON ────────────────────────────────────────────────────────

class _ApplePayButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ApplePayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apple, color: Colors.white, size: 22),
            SizedBox(width: 6),
            Text(
              'Pay',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── GOOGLE PAY BUTTON ───────────────────────────────────────────────────────

class _GooglePayButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GooglePayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDADCE0), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GPayLogo(),
            const SizedBox(width: 6),
            const Text(
              'Pay',
              style: TextStyle(
                color: Color(0xFF3C4043),
                fontSize: 17,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── EXPRESS CONFIRM SHEET ────────────────────────────────────────────────────

class _ExpressConfirmSheet extends StatelessWidget {
  final MarketplaceItem item;
  final _PayMethod method;
  const _ExpressConfirmSheet({required this.item, required this.method});

  @override
  Widget build(BuildContext context) {
    final isApple = method == _PayMethod.applePay;
    return Container(
      decoration: const BoxDecoration(
        color: cBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCDD5DF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // logo
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: isApple ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: isApple ? null : Border.all(color: const Color(0xFFDADCE0)),
            ),
            child: Center(
              child: isApple
                  ? const Icon(Icons.apple, color: Colors.white, size: 28)
                  : _GPayLogo(),
            ),
          ),
          const SizedBox(height: 14),

          Text(
            isApple ? 'Apple Pay' : 'Google Pay',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: cText),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: cMuted),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${item.price.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: cText),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Held until meetup is marked complete',
              style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 24),

          // confirm button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isApple ? Colors.black : cNavBg,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isApple) ...[
                    const Icon(Icons.apple, size: 20),
                    const SizedBox(width: 4),
                    const Text('Pay', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
                  ] else ...[
                    _GPayLogo(),
                    const SizedBox(width: 6),
                    const Text('Pay', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: cMuted, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// ─── GOOGLE PAY LOGO ──────────────────────────────────────────────────────────

class _GPayLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        children: [
          TextSpan(text: 'G', style: TextStyle(color: Color(0xFF4285F4))),
          TextSpan(text: 'o', style: TextStyle(color: Color(0xFFEA4335))),
          TextSpan(text: 'o', style: TextStyle(color: Color(0xFFFBBC05))),
          TextSpan(text: 'g', style: TextStyle(color: Color(0xFF4285F4))),
          TextSpan(text: 'l', style: TextStyle(color: Color(0xFF34A853))),
          TextSpan(text: 'e', style: TextStyle(color: Color(0xFFEA4335))),
        ],
      ),
    );
  }
}

// ─── STRIPE-STYLE FIELD ───────────────────────────────────────────────────────

class _StripeField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final TextInputType keyboard;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Widget? suffix;
  final IconData? icon;
  final BorderRadius radius;
  final bool joinTop;
  final bool joinLeft;
  final int? maxLength;

  const _StripeField({
    required this.ctrl,
    required this.hint,
    this.keyboard = TextInputType.text,
    this.validator,
    this.onChanged,
    this.suffix,
    this.icon,
    this.radius = const BorderRadius.all(Radius.circular(10)),
    this.joinTop  = false,
    this.joinLeft = false,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:  ctrl,
      keyboardType: keyboard,
      onChanged:   onChanged,
      validator:   validator,
      maxLength:   maxLength,
      style: const TextStyle(fontSize: 14, color: cText, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText:       hint,
        counterText:    '',
        prefixIcon:     icon != null ? Icon(icon, size: 16, color: cMuted) : null,
        suffixIcon:     suffix != null ? Padding(padding: const EdgeInsets.only(right: 10), child: suffix) : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 14),
        filled:     true,
        fillColor:  Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: Color(0xFFCDD5DF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: joinTop || joinLeft ? Colors.transparent : const Color(0xFFCDD5DF),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: cRed, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: Color(0xFFDF1B41)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: Color(0xFFDF1B41), width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFDF1B41)),
      ),
    );
  }
}

// ─── CARD BRAND ICON ──────────────────────────────────────────────────────────

class _CardBrandIcon extends StatelessWidget {
  final String brand;
  const _CardBrandIcon({required this.brand});

  @override
  Widget build(BuildContext context) {
    if (brand.isEmpty) {
      return Icon(Icons.credit_card_rounded, size: 18, color: Colors.grey.shade400);
    }
    const labels = {'visa': 'VISA', 'mastercard': 'MC', 'amex': 'AMEX', 'discover': 'DISC'};
    const colors = {
      'visa':       Color(0xFF1A1F71),
      'mastercard': Color(0xFFEB001B),
      'amex':       Color(0xFF007BC1),
      'discover':   Color(0xFFFF6600),
    };
    final label = labels[brand];
    final color = colors[brand];
    if (label == null || color == null) return Icon(Icons.credit_card_rounded, size: 18, color: Colors.grey.shade400);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.3)),
    );
  }
}

// ─── OR DIVIDER ───────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('Or pay with card',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: Colors.grey.shade500, letterSpacing: 0.3)),
      ),
      Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
    ]);
  }
}

// ─── FIELD LABEL ─────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: cMuted, letterSpacing: 0.4));
  }
}

// ─── ERROR BANNER ────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDF1B41).withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, size: 15, color: Color(0xFFDF1B41)),
        const SizedBox(width: 8),
        Expanded(child: Text(message,
            style: const TextStyle(fontSize: 12, color: Color(0xFFDF1B41)))),
      ]),
    );
  }
}

// ─── ORDER CONFIRMATION PAGE ──────────────────────────────────────────────────

class _OrderConfirmationPage extends StatelessWidget {
  final MarketplaceItem item;
  final String buyerEmail;
  final VoidCallback onDone;

  const _OrderConfirmationPage({
    required this.item,
    required this.buyerEmail,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      body: Column(
        children: [
          // ── branded header ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [cNavBg, cRedDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
                child: Column(
                  children: [
                    // success circle
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Order Received',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\$${item.price.toStringAsFixed(2)} · ${item.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.75)),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Text(
                        'Pending · Awaiting meetup',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── body ──────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                children: [
                  // email confirmation banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF93C5FD).withValues(alpha: 0.7)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.mark_email_read_outlined, size: 20, color: Color(0xFF2563EB)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Invoice sent', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E40AF))),
                            const SizedBox(height: 2),
                            Text(
                              buyerEmail,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB)),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // what happens next card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cBorder),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.timeline_rounded, size: 17, color: cRed),
                          ),
                          const SizedBox(width: 10),
                          const Text('What happens next',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cText)),
                        ]),
                        const SizedBox(height: 20),
                        _ConfirmStep(n: 1, text: 'Arrange a meetup with the seller via UniFind Messages.'),
                        _ConfirmStep(n: 2, text: 'Meet up in person and exchange the item.'),
                        _ConfirmStep(n: 3, text: 'Mark the meetup as completed — your payment is processed.'),
                        _ConfirmStep(n: 4, last: true, text: 'A payment confirmation email will be sent to you.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // payment held notice
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A).withValues(alpha: 0.8)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.account_balance_wallet_outlined, size: 18, color: Color(0xFFD97706)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Your payment is securely held and will only be released once the meetup is confirmed complete.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.5),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 32),

                  // back to marketplace button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: onDone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cNavBg,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.storefront_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Back to Marketplace', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Questions? Reach us through the UniFind app.',
                    style: TextStyle(fontSize: 11, color: cMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmStep extends StatelessWidget {
  final int n;
  final String text;
  final bool last;
  const _ConfirmStep({required this.n, required this.text, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26, height: 26,
              decoration: const BoxDecoration(color: cNavBg, shape: BoxShape.circle),
              child: Center(
                child: Text('$n',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ),
            if (!last)
              Container(width: 1.5, height: 32, color: cBorder),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 4, bottom: last ? 0 : 8),
            child: Text(text, style: const TextStyle(fontSize: 13, color: cMuted, height: 1.5)),
          ),
        ),
      ],
    );
  }
}

// ─── REFUND DIALOG ────────────────────────────────────────────────────────────

Future<void> showRefundDialog({
  required BuildContext context,
  required String offerId,
  required int userId,
}) async {
  final reasonCtrl = TextEditingController();
  bool submitting = false;
  String? error;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Request Refund',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please describe why you are requesting a refund:',
                style: TextStyle(fontSize: 13, color: cMuted)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Item not as described, seller no-show, etc.',
                hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 13),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCDD5DF))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCDD5DF))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: cRed, width: 1.5)),
                filled: true,
                fillColor: cBg,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: Color(0xFFDF1B41), fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: submitting ? null : () async {
              if (reasonCtrl.text.trim().isEmpty) {
                setDialogState(() => error = 'Please provide a reason.');
                return;
              }
              setDialogState(() { submitting = true; error = null; });
              try {
                await requestRefund(offerId: offerId, userId: userId, reason: reasonCtrl.text.trim());
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Refund request submitted for review.'),
                      behavior: SnackBarBehavior.floating));
                }
              } catch (e) {
                setDialogState(() {
                  error = e.toString().replaceFirst('Exception: ', '');
                  submitting = false;
                });
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: cNavBg, foregroundColor: Colors.white),
            child: submitting
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Submit'),
          ),
        ],
      ),
    ),
  );
  reasonCtrl.dispose();
}
