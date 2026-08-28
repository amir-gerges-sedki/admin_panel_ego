import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/tables/custom_data_table.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../cubit/customer_cubit.dart';
import '../widgets/customer_details_dialog.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerCubit, CustomerState>(
      builder: (context, state) {
        if (state is CustomerLoading) {
          return const Center(child: CircularProgressIndicator());
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
                    DataTableColumn(label: 'customer_role'.tr),
                    DataTableColumn(label: 'actions'.tr),
                  ],
                  rows: customers.map((c) {
                    final firstLetter = c.name.isNotEmpty ? c.name.substring(0, 1).toUpperCase() : 'U';
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
                        DataCell(Text(AppFormatters.formatPhone(c.phone))),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (c.role == 'admin' ? AppColor.secondary : AppColor.primary).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
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
