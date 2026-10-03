import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/tables/custom_data_table.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../cubit/customer_cubit.dart';
import '../widgets/customer_details_dialog.dart';
import 'package:admin_panel_ego/features/settings/presentation/widgets/loyalty_settings_dialog.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerCubit, CustomerState>(
      builder: (context, state) {
        if (state is CustomerInitial) {
          context.read<CustomerCubit>().loadCustomers();
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CustomerLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CustomerError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColor.error, size: 36),
                const SizedBox(height: 12),
                Text(state.message, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.read<CustomerCubit>().loadCustomers(),
                  child: Text('reload'.tr),
                ),
              ],
            ),
          );
        }

        if (state is CustomerLoaded) {
          final customers = state.filteredCustomers;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomDataTable(
                  title: 'customers_title'.tr,
                  subtitle: 'customers_subtitle'.tr,
                  searchHint: 'search_customers_hint'.tr,
                  trailingHeaderAction: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColor.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColor.success.withValues(alpha: 0.25), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColor.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColor.success,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => LoyaltySettingsDialog.show(context),
                        icon: const Icon(Icons.stars_rounded, size: 16, color: Color(0xFFF59E0B)),
                        label: Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'قواعد نقاط الولاء'
                              : 'Loyalty Rules',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFF59E0B), width: 1.2),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        tooltip: 'reload'.tr,
                        onPressed: () => context.read<CustomerCubit>().loadCustomers(),
                      ),
                    ],
                  ),
                  onSearchChanged: (q) => context.read<CustomerCubit>().filterCustomers(q),
                  emptyMessage: 'no_customers_found'.tr,
                  emptyIcon: Icons.people_outline_rounded,
                  columns: [
                    DataTableColumn(label: 'customer_name'.tr),
                    DataTableColumn(label: 'email'.tr),
                    DataTableColumn(label: 'phone'.tr),
                    DataTableColumn(label: 'city_col'.tr),
                    DataTableColumn(label: 'total_orders'.tr),
                    DataTableColumn(label: 'lifetime_spend'.tr),
                    DataTableColumn(label: 'loyalty_points'.tr),
                    DataTableColumn(label: 'customer_role'.tr),
                    DataTableColumn(label: 'actions'.tr),
                  ],
                  rows: customers.map((c) {
                    final firstLetter = c.name.trim().isNotEmpty ? c.name.trim().substring(0, 1).toUpperCase() : 'C';
                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: c.role == 'admin' ? AppColor.secondary : AppColor.primary,
                                child: Text(
                                  firstLetter,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: c.role == 'admin' ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        DataCell(Text(c.email)),
                        DataCell(Text(c.phone.isNotEmpty ? AppFormatters.formatPhone(c.phone) : '-')),
                        DataCell(Text(c.city)),
                        DataCell(Text('${c.totalOrders}')),
                        DataCell(
                          Text(
                            AppFormatters.formatEGP(c.totalSpent),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.stars_rounded, size: 14, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  '${c.loyaltyPoints}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.amber),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: (c.role == 'admin' ? AppColor.secondary : AppColor.primary).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              c.role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: c.role == 'admin' ? AppColor.secondary : AppColor.primary,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColor.primary),
                            tooltip: 'view_profile'.tr,
                            onPressed: () => CustomerDetailsDialog.show(context, c),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }

        return Center(
          child: ElevatedButton(
            onPressed: () => context.read<CustomerCubit>().loadCustomers(),
            child: Text('reload'.tr),
          ),
        );
      },
    );
  }
}
