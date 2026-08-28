import 'package:flutter/material.dart';
import '../../../../common/widgets/dialogs/unified_modal_sheet.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/customer_model.dart';

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
                child: Text(
                  firstLetter,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                      ),
                    ),
                    Text(
                      customer.email,
                      style: TextStyle(fontSize: 12, color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${customer.city} • ${AppFormatters.formatPhone(customer.phone)}',
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
