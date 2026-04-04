import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Reusable search field with optional barcode scan button.
///
/// Example:
/// ```dart
/// SearchField(
///   onChanged: (q) => doSearch(q),
///   onScan: () => openBarcodeScanner(),
/// )
/// ```
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    this.hintText = 'ค้นหา...',
    this.onChanged,
    this.onSubmitted,
    this.onScan,
    this.autofocus = false,
    this.controller,
  });

  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Called when the barcode scan button is tapped.
  /// If null, the scan button is hidden.
  final VoidCallback? onScan;

  final bool autofocus;
  final TextEditingController? controller;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(() {
      final has = _controller.text.isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_hasText)
              IconButton(
                icon: Icon(Icons.clear, size: 18.sp),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged?.call('');
                },
              ),
            if (widget.onScan != null)
              IconButton(
                icon: Icon(Icons.qr_code_scanner, size: 20.sp),
                tooltip: 'สแกนบาร์โค้ด',
                onPressed: widget.onScan,
              ),
          ],
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
        isDense: true,
      ),
    );
  }
}
