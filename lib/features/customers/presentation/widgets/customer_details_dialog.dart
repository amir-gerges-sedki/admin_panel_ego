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
import 'adjust_customer_points_dialog.dart';

class CustomerDetailsDialog extends StatelessWidget {
  final CustomerModel customer;

  const CustomerDetailsDialog({super.key, required this.customer});

  static void show(BuildContext context, CustomerModel customer) {
    UnifiedModalSheet.show(
      context: context,
      title: customer.name,
      subtitle: '${customer.email} • ${'customer_role'.tr}: ${customer.role.toUpperCase()}',
      icon: Icons.person_outline_rounded,
      maxWidth: 550,
      content: CustomerDetailsDialog(customer: customer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomerCubit>();

    return StreamBuilder<CustomerModel?>(
      stream: cubit.watchCustomer(customer),
      initialData: customer,
      builder: (context, snapshot) {
        final currentCustomer = snapshot.data ?? customer;

        // Sync update with parent cubit so customer table also reflects latest data
        if (snapshot.hasData && snapshot.data != null && snapshot.data != customer) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              cubit.updateCustomerLocally(snapshot.data!);
            }
          });
        }

        return _CustomerDetailsContent(customer: currentCustomer);
      },
    );
  }
}

class _CustomerDetailsContent extends StatelessWidget {
  final CustomerModel customer;

  const _CustomerDetailsContent({required this.customer});

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final firstLetter = customer.name.isNotEmpty ? customer.name.substring(0, 1).toUpperCase() : 'U';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Header Card
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColor.primary,
                backgroundImage: customer.image.isNotEmpty ? NetworkImage(customer.image) : null,
                onBackgroundImageError:
                    customer.image.isNotEmpty ? (exception, stackTrace) {} : null,
                child: customer.image.isEmpty
                    ? Text(
                        firstLetter,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                      )
                    : null,
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                            ),
                          ),
                        ),
                        // Live stream indicator badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColor.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColor.success.withValues(alpha: 0.25), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: AppColor.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColor.success,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customer.email,
                      style: TextStyle(fontSize: 12, color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.phone.isNotEmpty
                          ? '${customer.city} • ${AppFormatters.formatPhone(customer.phone)}'
                          : '${customer.city} • -',
                      style: const TextStyle(fontSize: 11, color: AppColor.textMutedDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.md),

        // Activity Stats
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                'total_orders'.tr,
                '${customer.totalOrders}',
                Icons.shopping_bag_outlined,
                AppColor.primary,
                isDark,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: _buildMetricTile(
                'lifetime_spend'.tr,
                AppFormatters.formatEGP(customer.totalSpent),
                Icons.account_balance_wallet_outlined,
                AppColor.success,
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),

        // Loyalty Points Card
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
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
                      'loyalty_points'.tr,
                      style: const TextStyle(fontSize: 11.5, color: AppColor.textMutedDark, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${customer.loyaltyPoints} ${'points_count'.trParams({'count': ''})}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    Text(
                      'points_value_egp'.trParams({
                        'amount': AppFormatters.formatEGP(LoyaltyService.calculateDiscount(customer.loyaltyPoints)),
                      }),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.amber[300] : const Color(0xFFB45309),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => AdjustCustomerPointsDialog.show(context, customer),
                icon: const Icon(Icons.edit_rounded, size: 14),
                label: Text('adjust_points_btn'.tr, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber[800],
                  side: BorderSide(color: Colors.amber.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.md),

        // Join Date
        Text(
          '${'member_since'.tr}: ${AppFormatters.formatDate(customer.createdAt)}',
          style: const TextStyle(fontSize: 12, color: AppColor.textMutedDark),
        ),
      ],
    );
  }

  Widget _buildMetricTile(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(title, style: const TextStyle(fontSize: 11, color: AppColor.textMutedDark)),
        ],
      ),
    );
  }
}
