import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/dialogs/unified_modal_sheet.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/customer_model.dart';
import 'package:admin_panel_ego/features/customers/domain/services/loyalty_service.dart';
import '../cubit/customer_cubit.dart';

class AdjustCustomerPointsDialog extends StatefulWidget {
  final CustomerModel customer;

  const AdjustCustomerPointsDialog({super.key, required this.customer});

  static Future<void> show(BuildContext context, CustomerModel customer) {
    return UnifiedModalSheet.show(
      context: context,
      title: 'adjust_points_title'.tr,
      subtitle: customer.name,
      icon: Icons.stars_rounded,
      maxWidth: 480,
      content: BlocProvider.value(
        value: context.read<CustomerCubit>(),
        child: AdjustCustomerPointsDialog(customer: customer),
      ),
    );
  }

  @override
  State<AdjustCustomerPointsDialog> createState() => _AdjustCustomerPointsDialogState();
}

class _AdjustCustomerPointsDialogState extends State<AdjustCustomerPointsDialog> {
  final TextEditingController _pointsDeltaController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _pointsDeltaController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final customer = widget.customer;
    final currentPoints = customer.loyaltyPoints;
    final discountVal = LoyaltyService.calculateDiscount(currentPoints);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Current Points Banner
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'current_points_balance'.trParams({'points': '$currentPoints'}),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'points_value_egp'.trParams({'amount': AppFormatters.formatEGP(discountVal)}),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.amber[300] : const Color(0xFFB45309),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.md),

        // Quick bonus chips
        Text(
          'quick_bonus_gift'.tr,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _buildQuickChip(20),
            _buildQuickChip(50),
            _buildQuickChip(100),
            _buildQuickChip(200),
            _buildQuickChip(500),
          ],
        ),
        const SizedBox(height: AppSizes.md),

        // Points Delta Input
        TextField(
          controller: _pointsDeltaController,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: InputDecoration(
            labelText: 'points_adjustment_delta'.tr,
            hintText: '+50 أو -20',
            prefixIcon: const Icon(Icons.exposure_rounded, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: AppSizes.md),

        // Reason Input
        TextField(
          controller: _reasonController,
          decoration: InputDecoration(
            labelText: 'reason'.tr,
            hintText: 'adjustment_reason_hint'.tr,
            prefixIcon: const Icon(Icons.notes_rounded, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: AppSizes.lg),

        // Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
              child: Text('cancel'.tr),
            ),
            const SizedBox(width: AppSizes.sm),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _saveAdjustment,
              icon: _isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text('save_points_adjustment'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickChip(int points) {
    return ActionChip(
      label: Text(
        '+$points ${'points_count'.trParams({'count': ''})}',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
      ),
      avatar: const Icon(Icons.add_rounded, size: 14, color: AppColor.primary),
      onPressed: () {
        setState(() {
          _pointsDeltaController.text = points.toString();
        });
      },
    );
  }

  Future<void> _saveAdjustment() async {
    final rawText = _pointsDeltaController.text.trim().replaceAll('+', '');
    final delta = int.tryParse(rawText);
    if (delta == null || delta == 0) {
      HelperFun.showNotificationAlert(
        title: 'error'.tr,
        message: 'invalid_points_delta'.tr,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final reason = _reasonController.text.trim();

    try {
      await context.read<CustomerCubit>().adjustCustomerPoints(
            customerId: widget.customer.id,
            pointsDelta: delta,
            reason: reason.isNotEmpty ? reason : null,
          );

      if (mounted) {
        Navigator.of(context).pop();
        HelperFun.showNotificationAlert(
          title: 'success'.tr,
          message: 'points_adjusted_success'.tr,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        HelperFun.showNotificationAlert(
          title: 'error'.tr,
          message: e.toString(),
        );
      }
    }
  }
}
