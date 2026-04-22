part of '../main.dart';

// ─── PAYMENT SIMULATION SCREEN ───────────────────────────────────────────────
// Collects billing info for UX purposes only.
// No payment data is stored or transmitted to any payment processor.

class PaymentScreen extends StatefulWidget {
  final MarketplaceItem item;
  final int buyerId;
  final int sellerId;

  const PaymentScreen({
    super.key,
    required this.item,
    required this.buyerId,
    required this.sellerId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Billing fields
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _addressCtrl  = TextEditingController();
  final _cityCtrl     = TextEditingController();
  final _zipCtrl      = TextEditingController();

  // Card fields (simulated — never transmitted)
  final _cardCtrl     = TextEditingController();
  final _expiryCtrl   = TextEditingController();
  final _cvvCtrl      = TextEditingController();

  bool _processing = false;
  _PayStep _step = _PayStep.form;
  String? _offerId;
  String? _txnId;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _zipCtrl.dispose();
    _cardCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  String _formatCard(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  String _formatExpiry(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 2) return digits;
    return '${digits.substring(0, 2)}/${digits.substring(2, digits.length.clamp(2, 4))}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _processing = true; _error = null; });

    try {
      // Step 1 — create offer
      final offer = await createOffer(
        listingId: int.tryParse(widget.item.id) ?? 0,
        buyerId:   widget.buyerId,
        sellerId:  widget.sellerId,
        amount:    widget.item.price,
      );
      _offerId = offer['offer_id']?.toString();

      // Step 2 — simulate processing
      await Future.delayed(const Duration(milliseconds: 1200));
      final payment = await processPayment(
        offerId: _offerId ?? '',
        userId:  widget.buyerId,
      );
      _txnId = payment['transaction_id']?.toString();

      if (!mounted) return;
      setState(() { _step = _PayStep.success; _processing = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _processing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        title: const Text('Payment', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: cNavBg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _step == _PayStep.success
          ? _SuccessView(txnId: _txnId ?? '', item: widget.item, onDone: () => Navigator.pop(context))
          : _FormView(
              formKey:     _formKey,
              item:        widget.item,
              nameCtrl:    _nameCtrl,
              emailCtrl:   _emailCtrl,
              addressCtrl: _addressCtrl,
              cityCtrl:    _cityCtrl,
              zipCtrl:     _zipCtrl,
              cardCtrl:    _cardCtrl,
              expiryCtrl:  _expiryCtrl,
              cvvCtrl:     _cvvCtrl,
              processing:  _processing,
              error:       _error,
              formatCard:  _formatCard,
              formatExpiry: _formatExpiry,
              onSubmit:    _submit,
            ),
    );
  }
}

enum _PayStep { form, success }

// ─── FORM VIEW ───────────────────────────────────────────────────────────────

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final MarketplaceItem item;
  final TextEditingController nameCtrl, emailCtrl, addressCtrl, cityCtrl, zipCtrl;
  final TextEditingController cardCtrl, expiryCtrl, cvvCtrl;
  final bool processing;
  final String? error;
  final String Function(String) formatCard;
  final String Function(String) formatExpiry;
  final VoidCallback onSubmit;

  const _FormView({
    required this.formKey,
    required this.item,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.addressCtrl,
    required this.cityCtrl,
    required this.zipCtrl,
    required this.cardCtrl,
    required this.expiryCtrl,
    required this.cvvCtrl,
    required this.processing,
    required this.error,
    required this.formatCard,
    required this.formatExpiry,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Simulation banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SIMULATION ONLY — No real payment will be charged. '
                    'Your card details are never stored or transmitted.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.5),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // Order summary card
            _SectionCard(
              title: 'Order Summary',
              icon: Icons.receipt_long_outlined,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: Image.network(
                        item.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: cPlaceholder,
                          child: const Icon(Icons.image_not_supported, color: cMuted, size: 22),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cText)),
                        const SizedBox(height: 4),
                        Text(item.condition,
                            style: const TextStyle(fontSize: 12, color: cMuted)),
                      ],
                    ),
                  ),
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: cRed),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Billing info
            _SectionCard(
              title: 'Billing Information',
              icon: Icons.person_outline_rounded,
              child: Column(
                children: [
                  _PayField(
                    ctrl: nameCtrl,
                    label: 'Full Name',
                    hint: 'Jane Smith',
                    icon: Icons.person_outline_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 10),
                  _PayField(
                    ctrl: emailCtrl,
                    label: 'Email Address',
                    hint: 'jane@example.com',
                    icon: Icons.email_outlined,
                    keyboard: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  _PayField(
                    ctrl: addressCtrl,
                    label: 'Street Address',
                    hint: '123 Main St',
                    icon: Icons.home_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      flex: 2,
                      child: _PayField(
                        ctrl: cityCtrl,
                        label: 'City',
                        hint: 'Montclair',
                        icon: Icons.location_city_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PayField(
                        ctrl: zipCtrl,
                        label: 'ZIP',
                        hint: '07042',
                        icon: Icons.markunread_mailbox_outlined,
                        keyboard: TextInputType.number,
                        validator: (v) => (v == null || v.trim().length < 5) ? 'Invalid' : null,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment info (simulated)
            _SectionCard(
              title: 'Payment Details (Simulated)',
              icon: Icons.credit_card_outlined,
              child: Column(
                children: [
                  _PayField(
                    ctrl: cardCtrl,
                    label: 'Card Number',
                    hint: '1234 5678 9012 3456',
                    icon: Icons.credit_card_outlined,
                    keyboard: TextInputType.number,
                    onChanged: (v) {
                      final formatted = (() {
                        final digits = v.replaceAll(RegExp(r'\D'), '');
                        final buf = StringBuffer();
                        for (int i = 0; i < digits.length && i < 16; i++) {
                          if (i > 0 && i % 4 == 0) buf.write(' ');
                          buf.write(digits[i]);
                        }
                        return buf.toString();
                      })();
                      if (formatted != v) {
                        cardCtrl.value = cardCtrl.value.copyWith(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      }
                    },
                    validator: (v) {
                      final digits = (v ?? '').replaceAll(' ', '');
                      return digits.length < 16 ? 'Enter a 16-digit card number' : null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: _PayField(
                        ctrl: expiryCtrl,
                        label: 'Expiry',
                        hint: 'MM/YY',
                        icon: Icons.calendar_today_outlined,
                        keyboard: TextInputType.number,
                        onChanged: (v) {
                          final digits = v.replaceAll(RegExp(r'\D'), '');
                          String formatted = digits;
                          if (digits.length > 2) {
                            formatted = '${digits.substring(0, 2)}/${digits.substring(2, digits.length.clamp(2, 4))}';
                          }
                          if (formatted != v) {
                            expiryCtrl.value = expiryCtrl.value.copyWith(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
                            );
                          }
                        },
                        validator: (v) {
                          final digits = (v ?? '').replaceAll('/', '');
                          return digits.length < 4 ? 'Enter MM/YY' : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PayField(
                        ctrl: cvvCtrl,
                        label: 'CVV',
                        hint: '123',
                        icon: Icons.lock_outline_rounded,
                        keyboard: TextInputType.number,
                        maxLength: 4,
                        validator: (v) => ((v ?? '').length < 3) ? 'Enter CVV' : null,
                      ),
                    ),
                  ]),
                ],
              ),
            ),

            if (error != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cRedLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cRed.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded, color: cRed, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(error!,
                      style: const TextStyle(color: cRedDark, fontSize: 13))),
                ]),
              ),
            ],
            const SizedBox(height: 24),

            // Pay button
            GestureDetector(
              onTap: processing ? null : onSubmit,
              child: AnimatedContainer(
                duration: kFast,
                height: 52,
                decoration: BoxDecoration(
                  gradient: processing
                      ? null
                      : const LinearGradient(colors: [cRed, cRedDark],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                  color: processing ? cMuted : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: processing ? null : [
                    BoxShadow(color: cRed.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Center(
                  child: processing
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            SizedBox(width: 10),
                            Text('Processing...', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_rounded, color: Colors.white, size: 17),
                            const SizedBox(width: 8),
                            Text(
                              'Pay \$${item.price.toStringAsFixed(2)} (Simulated)',
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'No real charge will be made',
                style: TextStyle(fontSize: 11, color: cMuted),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── SUCCESS VIEW ─────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final String txnId;
  final MarketplaceItem item;
  final VoidCallback onDone;

  const _SuccessView({required this.txnId, required this.item, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF27AE60), Color(0xFF1E8449)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF27AE60).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('Payment Simulated!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: cText)),
            const SizedBox(height: 8),
            Text(
              'Your simulated payment for "${item.title}" was processed successfully.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: cMuted, height: 1.6),
            ),
            const SizedBox(height: 20),

            // Transaction details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TxnRow(label: 'Transaction ID', value: txnId),
                  const SizedBox(height: 8),
                  _TxnRow(label: 'Amount', value: '\$${item.price.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _TxnRow(label: 'Status', value: 'Completed'),
                  const SizedBox(height: 8),
                  _TxnRow(label: 'Date', value: _formatNow()),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Reminder: This was a simulation. No real charge was made. '
                'Contact the seller to arrange the physical exchange of the item.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.5),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNow() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

class _TxnRow extends StatelessWidget {
  final String label, value;
  const _TxnRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: cMuted, fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(fontSize: 12, color: cText, fontWeight: FontWeight.w700)),
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
            const Text(
              'Please describe why you are requesting a refund:',
              style: TextStyle(fontSize: 13, color: cMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Item not as described, seller no-show, etc.',
                hintStyle: const TextStyle(color: cMuted, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: cBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: cBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: cRed, width: 2)),
                filled: true,
                fillColor: cBg,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: cRedDark, fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: submitting
                ? null
                : () async {
                    if (reasonCtrl.text.trim().isEmpty) {
                      setDialogState(() => error = 'Please provide a reason.');
                      return;
                    }
                    setDialogState(() { submitting = true; error = null; });
                    try {
                      await requestRefund(
                        offerId: offerId,
                        userId:  userId,
                        reason:  reasonCtrl.text.trim(),
                      );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text('Refund request submitted for review.'),
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    } catch (e) {
                      setDialogState(() {
                        error = e.toString().replaceFirst('Exception: ', '');
                        submitting = false;
                      });
                    }
                  },
            style: ElevatedButton.styleFrom(
                backgroundColor: cRed, foregroundColor: Colors.white),
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

// ─── HELPER WIDGETS ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 15, color: cRed),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cText)),
          ]),
          const SizedBox(height: 12),
          Divider(height: 1, color: cBorder),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PayField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final IconData icon;
  final TextInputType keyboard;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLength;

  const _PayField({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboard = TextInputType.text,
    this.validator,
    this.onChanged,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLength: maxLength,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 16, color: cMuted),
        hintStyle: const TextStyle(color: cMuted, fontSize: 13),
        labelStyle: const TextStyle(fontSize: 13, color: cMuted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: cBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: cBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: cRed, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: cRedDark)),
        filled: true,
        fillColor: cBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        counterText: '',
      ),
    );
  }
}
