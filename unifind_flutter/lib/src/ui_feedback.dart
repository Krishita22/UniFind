part of '../main.dart';

class _EmptyState extends StatelessWidget {
  final String message;
  final String? cta;
  final VoidCallback? onCta;
  const _EmptyState({required this.message, this.cta, this.onCta});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: cRedLight, shape: BoxShape.circle),
            child: const Icon(Icons.inbox_rounded, color: cRed, size: 32),
          ),
          const SizedBox(height: 14),
          Text(message, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cText)),
          if (cta != null && onCta != null) ...[
            const SizedBox(height: 14),
            _RedButton(label: cta!, icon: Icons.add_rounded, onTap: onCta!),
          ],
        ],
      ),
    );
  }
}
