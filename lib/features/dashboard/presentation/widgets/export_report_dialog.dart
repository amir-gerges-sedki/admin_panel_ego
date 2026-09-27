import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/helper_fun.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/presentation/cubit/order_cubit.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../data/models/dashboard_analytics_model.dart';
import '../../utils/dashboard_report_exporter.dart';

class ExportReportDialog extends StatelessWidget {
  final DashboardAnalyticsModel analytics;

  const ExportReportDialog({super.key, required this.analytics});

  static void show(BuildContext context, {required DashboardAnalyticsModel analytics}) {
    showDialog(
      context: context,
      builder: (_) => ExportReportDialog(analytics: analytics),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);

    // Grab available state dependencies
    final orderState = context.watch<OrderCubit>().state;
    final List<OrderModel> orders =
        orderState is OrderLoaded ? orderState.orders : [];

    final productState = context.watch<ProductCubit>().state;
    final List<ProductModel> products =
        productState is ProductLoaded ? productState.products : [];

    final settingsState = context.watch<SettingsCubit>().state;
    final int threshold = settingsState is SettingsLoaded
        ? settingsState.settings.lowStockThreshold
        : 10;

    return AlertDialog(
      backgroundColor: isDark ? AppColor.darkCard : AppColor.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
            ),
            child: const Icon(
              Icons.file_download_rounded,
              color: AppColor.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'export_report_title'.tr,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'export_report_desc'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: isDark
                        ? AppColor.textSecondaryDark
                        : AppColor.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 580,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Executive Summary
              _buildReportOptionCard(
                context: context,
                isDark: isDark,
                icon: Icons.analytics_outlined,
                color: AppColor.primary,
                title: 'export_executive_summary'.tr,
                subtitle: 'export_executive_summary_desc'.tr,
                badge: 'KPIs & Trends',
                onDownload: () async {
                  Navigator.pop(context);
                  final csv = DashboardReportExporter.generateExecutiveSummaryCsv(
                    analytics: analytics,
                    lowStockThreshold: threshold,
                  );
                  await DashboardReportExporter.downloadReport(
                    fileNamePrefix: 'ego_store_executive_summary',
                    csvContent: csv,
                  );
                  if (context.mounted) {
                    HelperFun.successSnackbar(
                      'export_csv'.tr,
                      'export_download_success'.tr.replaceAll(
                            '{name}',
                            'Executive Summary',
                          ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),

              // 2. Orders & Sales
              _buildReportOptionCard(
                context: context,
                isDark: isDark,
                icon: Icons.shopping_bag_outlined,
                color: AppColor.secondary,
                title: 'export_orders_report'.tr,
                subtitle: 'export_orders_report_desc'.tr,
                badge: '${orders.length} Orders',
                onDownload: () async {
                  Navigator.pop(context);
                  final csv = DashboardReportExporter.generateOrdersReportCsv(
                    orders: orders,
                  );
                  await DashboardReportExporter.downloadReport(
                    fileNamePrefix: 'ego_store_orders_manifest',
                    csvContent: csv,
                  );
                  if (context.mounted) {
                    HelperFun.successSnackbar(
                      'export_csv'.tr,
                      'export_download_success'.tr.replaceAll(
                            '{name}',
                            'Orders & Sales Manifest',
                          ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),

              // 3. Inventory & Stock Health
              _buildReportOptionCard(
                context: context,
                isDark: isDark,
                icon: Icons.inventory_2_outlined,
                color: AppColor.warning,
                title: 'export_inventory_report'.tr,
                subtitle: 'export_inventory_report_desc'.tr,
                badge: '${products.length} Products',
                onDownload: () async {
                  Navigator.pop(context);
                  final csv = DashboardReportExporter.generateInventoryReportCsv(
                    products: products,
                    lowStockThreshold: threshold,
                  );
                  await DashboardReportExporter.downloadReport(
                    fileNamePrefix: 'ego_store_inventory_health',
                    csvContent: csv,
                  );
                  if (context.mounted) {
                    HelperFun.successSnackbar(
                      'export_csv'.tr,
                      'export_download_success'.tr.replaceAll(
                            '{name}',
                            'Inventory Health',
                          ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),

              // 4. Consolidated Master Report
              _buildReportOptionCard(
                context: context,
                isDark: isDark,
                icon: Icons.folder_zip_outlined,
                color: const Color(0xFF10B981),
                title: 'export_master_report'.tr,
                subtitle: 'export_master_report_desc'.tr,
                badge: 'All Datasets',
                onDownload: () async {
                  Navigator.pop(context);
                  final csv = DashboardReportExporter.generateMasterReportCsv(
                    analytics: analytics,
                    orders: orders,
                    products: products,
                    lowStockThreshold: threshold,
                  );
                  await DashboardReportExporter.downloadReport(
                    fileNamePrefix: 'ego_store_master_report',
                    csvContent: csv,
                  );
                  if (context.mounted) {
                    HelperFun.successSnackbar(
                      'export_csv'.tr,
                      'export_download_success'.tr.replaceAll(
                            '{name}',
                            'All-in-One Master Report',
                          ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr),
        ),
      ],
    );
  }

  Widget _buildReportOptionCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onDownload,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColor.textPrimaryDark
                              : AppColor.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColor.textSecondaryDark
                        : AppColor.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.md),
          ElevatedButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.download_rounded, size: 14),
            label: Text('download_csv'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}
