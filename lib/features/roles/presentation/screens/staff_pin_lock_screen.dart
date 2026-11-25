import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../cubit/auth_role_cubit.dart';

/// Professional Kiosk / POS Lock Screen with PIN Keypad Authentication
class StaffPinLockScreen extends StatefulWidget {
  const StaffPinLockScreen({super.key});

  @override
  State<StaffPinLockScreen> createState() => _StaffPinLockScreenState();
}

class _StaffPinLockScreenState extends State<StaffPinLockScreen> {
  String _pin = '';
  bool _isLoading = false;
  String? _errorMessage;
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_pin.length >= 6 || _isLoading) return;
    setState(() {
      _errorMessage = null;
      _pin += digit;
    });

    if (_pin.length >= 4) {
      _checkPinAuto();
    }
  }

  Future<void> _checkPinAuto() async {
    final currentInput = _pin.trim();
    if (currentInput.length < 4 || _isLoading) return;

    final success = await context.read<AuthRoleCubit>().loginWithPin(currentInput);
    if (!mounted) return;

    if (success) {
      setState(() {
        _isLoading = false;
        _pin = '';
        _errorMessage = null;
      });
    } else if (currentInput.length >= 6) {
      // Reached maximum length (6) and was not valid
      setState(() {
        _isLoading = false;
        _pin = '';
        _errorMessage = 'كود PIN غير صالح أو تم إيقاف الموظف';
      });
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _errorMessage = null;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  void _onClear() {
    setState(() {
      _errorMessage = null;
      _pin = '';
    });
  }

  Future<void> _trySubmit() async {
    if (_pin.trim().isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await context.read<AuthRoleCubit>().loginWithPin(_pin.trim());

    if (!mounted) return;

    if (success) {
      setState(() {
        _isLoading = false;
        _pin = '';
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = false;
        _pin = '';
        _errorMessage = 'كود PIN غير صالح أو تم إيقاف الموظف';
      });
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace) {
      _onBackspace();
    } else if (key == LogicalKeyboardKey.escape) {
      _onClear();
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      _trySubmit();
    } else {
      final char = event.character;
      if (char != null && RegExp(r'^[0-9]$').hasMatch(char)) {
        _onDigitPressed(char);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: KeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              width: 440,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Branding & Icon
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColor.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.point_of_sale_rounded,
                      size: 40,
                      color: AppColor.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'EGO VAPE STORE',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'نظام إدارة المتجر ونقاط البيع POS',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Enter PIN prompt
                  Text(
                    'أدخل كود الموظف للدخول',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PIN Dots Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final isFilled = index < _pin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled
                              ? AppColor.primary
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          border: Border.all(
                            color: isFilled
                                ? AppColor.primary
                                : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                            width: 1.5,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),

                  // Error Message
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(),
                    )
                  else ...[
                    // Keypad Grid
                    const SizedBox(height: 8),
                    _buildKeypad(isDark),
                  ],

                  const SizedBox(height: 20),
                  Text(
                    'يمكنك استخدام لوحة المفاتيح الفعلية لإدخال الكود مباشرة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(bool isDark) {
    final buttonBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final buttonBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    Widget buildButton({
      required Widget child,
      required VoidCallback onTap,
      Color? bg,
    }) {
      return Material(
        color: bg ?? buttonBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: buttonBorder),
            ),
            child: child,
          ),
        ),
      );
    }

    Widget buildDigit(String digit) {
      return buildButton(
        onTap: () => _onDigitPressed(digit),
        child: Text(
          digit,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: buildDigit('1')),
            const SizedBox(width: 12),
            Expanded(child: buildDigit('2')),
            const SizedBox(width: 12),
            Expanded(child: buildDigit('3')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: buildDigit('4')),
            const SizedBox(width: 12),
            Expanded(child: buildDigit('5')),
            const SizedBox(width: 12),
            Expanded(child: buildDigit('6')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: buildDigit('7')),
            const SizedBox(width: 12),
            Expanded(child: buildDigit('8')),
            const SizedBox(width: 12),
            Expanded(child: buildDigit('9')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: buildButton(
                onTap: _onClear,
                child: const Text(
                  'مسح',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: buildDigit('0')),
            const SizedBox(width: 12),
            Expanded(
              child: buildButton(
                onTap: _onBackspace,
                child: Icon(
                  Icons.backspace_outlined,
                  size: 20,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _pin.length >= 4 ? _trySubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              disabledForegroundColor: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            icon: const Icon(Icons.login_rounded, size: 20),
            label: const Text(
              'تسجيل الدخول',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
