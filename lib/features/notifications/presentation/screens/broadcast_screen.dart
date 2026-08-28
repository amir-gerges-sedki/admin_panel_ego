import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/widgets/tables/custom_data_table.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/formatters/formatters.dart';
import '../../../../core/localization/app_localizations.dart';
import '../cubit/notification_cubit.dart';
import '../widgets/broadcast_composer_dialog.dart';

class BroadcastScreen extends StatelessWidget {
  const BroadcastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        if (state is NotificationLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is NotificationLoaded) {
          final broadcasts = state.filteredBroadcasts;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomDataTable(
                  title: 'broadcasts_title'.tr,
                  subtitle: 'broadcasts_subtitle'.tr,
                  searchHint: 'search_broadcasts_hint'.tr,
                  onSearchChanged: (q) => context.read<NotificationCubit>().filterBroadcasts(q),
                  emptyMessage: 'no_broadcasts_found'.tr,
                  emptyIcon: Icons.campaign_outlined,
                  emptyAction: ElevatedButton.icon(
                    onPressed: () {
                      BroadcastComposerDialog.show(
                        context,
                        onSend: (b) => context.read<NotificationCubit>().sendBroadcast(b),
                      );
                    },
                    icon: const Icon(Icons.campaign_rounded, size: 16),
                    label: Text('compose_broadcast'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  trailingHeaderAction: ElevatedButton.icon(
                    onPressed: () {
                      BroadcastComposerDialog.show(
                        context,
                        onSend: (b) => context.read<NotificationCubit>().sendBroadcast(b),
                      );
                    },
                    icon: const Icon(Icons.campaign_rounded, size: 18),
                    label: Text('compose_broadcast'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
                    ),
                  ),
                  columns: [
                    DataTableColumn(label: 'broadcast_title'.tr, width: 220),
                    DataTableColumn(label: 'notification_body_col'.tr, width: 260),
                    DataTableColumn(label: 'target_audience'.tr),
                    DataTableColumn(label: 'target_destination'.tr),
                    DataTableColumn(label: 'devices_reached'.tr),
                    DataTableColumn(label: 'sent_at'.tr),
                  ],
                  rows: broadcasts.map((b) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              if (b.imageUrl.isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    b.imageUrl,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 32,
                                      height: 32,
                                      color: AppColor.primary.withValues(alpha: 0.1),
                                      child: const Icon(Icons.notifications_active_outlined, size: 16, color: AppColor.primary),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ] else ...[
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColor.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.notifications_active_outlined, size: 16, color: AppColor.primary),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  b.title,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            b.body,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColor.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              b.targetAudience,
                              style: const TextStyle(color: AppColor.primary, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              b.targetScreen,
                              style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 11, fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: AppColor.success, size: 16),
                              const SizedBox(width: 4),
                              Text('devices_count'.trParams({'count': '${b.successCount}'}), style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        DataCell(Text(AppFormatters.formatDateTime(b.sentAt))),
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
            onPressed: () => context.read<NotificationCubit>().loadBroadcasts(),
            child: Text('reload'.tr),
          ),
        );
      },
    );
  }
}
