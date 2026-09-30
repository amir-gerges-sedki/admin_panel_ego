import 'package:flutter/material.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/damaged_stock_model.dart';

class DamagedStockDetailsDialog extends StatelessWidget {
  final DamagedStockModel record;

  const DamagedStockDetailsDialog({super.key, required this.record});

  static void show(BuildContext context, DamagedStockModel record) {
    showDialog<void>(
      context: context,
      builder: (ctx) => DamagedStockDetailsDialog(record: record),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg)),
      backgroundColor: isDark ? AppColor.darkCard : Colors.white,
      child: Container(
        width: 550,
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: record.reason.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                      ),
                      child: Icon(record.reason.icon, color: record.reason.color, size: 24),
                    ),
                    const SizedBox(width: AppSizes.sm + 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'damaged_item_details'.tr,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          AppFormatters.formatDateTime(record.createdAt),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            const Divider(height: 1),
            const SizedBox(height: AppSizes.md),

            // Product & Variation Info
            _buildDetailRow(
              isDark: isDark,
              icon: Icons.inventory_2_rounded,
              title: 'product_name'.tr,
              value: record.productTitle,
              isBold: true,
            ),
            if (record.variationSku.isNotEmpty) ...[
              const SizedBox(height: AppSizes.sm),
              _buildDetailRow(
                isDark: isDark,
                icon: Icons.qr_code_rounded,
                title: 'sku_barcode'.tr,
                value: record.variationSku,
              ),
            ],
            if (record.variationAttributes.isNotEmpty) ...[
              const SizedBox(height: AppSizes.sm),
              _buildDetailRow(
                isDark: isDark,
                icon: Icons.tune_rounded,
                title: 'product_variation'.tr,
                value: record.variationAttributes.entries
                    .map((e) => '${e.key}: ${e.value}')
                    .join(' | '),
              ),
            ],

            const SizedBox(height: AppSizes.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSizes.sm),

            // Quantity & Cost Metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    isDark: isDark,
                    title: 'damage_quantity'.tr,
                    value: '${record.quantity} ${"units".tr}',
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: _buildMetricTile(
                    isDark: isDark,
                    title: 'cost_price_per_unit'.tr,
                    value: AppFormatters.formatEGP(record.costPrice),
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: _buildMetricTile(
                    isDark: isDark,
                    title: 'total_damage_financial_loss'.tr,
                    value: AppFormatters.formatEGP(record.totalLoss),
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSizes.md),

            // Reason Badge & Recorded By
            _buildDetailRow(
              isDark: isDark,
              icon: record.reason.icon,
              title: 'damage_reason'.tr,
              value: record.reason.labelKey.tr,
              valueColor: record.reason.color,
            ),
            const SizedBox(height: AppSizes.sm),
            _buildDetailRow(
              isDark: isDark,
              icon: Icons.person_outline_rounded,
              title: 'recorded_by'.tr,
              value: record.recordedBy,
            ),

            if (record.notes.isNotEmpty) ...[
              const SizedBox(height: AppSizes.sm),
              _buildDetailRow(
                isDark: isDark,
                icon: Icons.notes_rounded,
                title: 'notes_and_explanation'.tr,
                value: record.notes,
              ),
            ],

            const SizedBox(height: AppSizes.lg),

            // Close Button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                  ),
                ),
                child: Text('close'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required bool isDark,
    required IconData icon,
    required String title,
    required String value,
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight),
        const SizedBox(width: 8),
        Text(
          '$title: ',
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? (isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required bool isDark,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
