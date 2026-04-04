import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider — holds the tenant's public menu URL
// ─────────────────────────────────────────────────────────────────────────────

final qrMenuUrlProvider = StateProvider<String?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class QrMenuPage extends ConsumerWidget {
  /// The public menu url, e.g. https://app.lumluay.com/menu/my-cafe
  final String menuUrl;
  final String tenantName;

  const QrMenuPage({
    super.key,
    required this.menuUrl,
    required this.tenantName,
  });

  static const routePath = '/qr-menu';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share QR',
            onPressed: () => _shareUrl(context),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tenantName,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Scan to view our menu',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
              SizedBox(height: 24.h),

              // QR Code
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: menuUrl,
                  version: QrVersions.auto,
                  size: 240.r,
                  backgroundColor: Colors.white,
                  errorStateBuilder: (ctx, err) => SizedBox(
                    width: 240.r,
                    height: 240.r,
                    child: Center(
                      child: Text('QR Error: $err',
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // URL display + copy
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        menuUrl,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copy link',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: menuUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copied!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _shareUrl(context),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareUrl(BuildContext context) {
    Share.share(
      menuUrl,
      subject: 'Scan our QR menu — $tenantName',
    );
  }
}
