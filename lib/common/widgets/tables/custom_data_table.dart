import 'package:flutter/material.dart';
import '../../../core/constant/app_colors.dart';
import '../../../core/constant/app_sizes.dart';
import '../../../core/helper/helper_fun.dart';
import '../../../core/localization/app_localizations.dart';

class DataTableColumn {
  final String label;
  final bool isNumeric;
  final double? width;

  const DataTableColumn({
    required this.label,
    this.isNumeric = false,
    this.width,
  });
}

/// Universal Responsive Data Table with Search, Filter, Pagination & Empty State
class CustomDataTable extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<DataTableColumn> columns;
  final List<DataRow> rows;
  final Widget? trailingHeaderAction;
  final Widget? filterWidget;
  final ValueChanged<String>? onSearchChanged;
  final String? searchHint;
  final int rowsPerPage;
  final String? emptyMessage;
  final IconData? emptyIcon;
  final Widget? emptyAction;

  const CustomDataTable({
    super.key,
    required this.title,
    this.subtitle,
    required this.columns,
    required this.rows,
    this.trailingHeaderAction,
    this.filterWidget,
    this.onSearchChanged,
    this.searchHint,
    this.rowsPerPage = 10,
    this.emptyMessage,
    this.emptyIcon,
    this.emptyAction,
  });

  @override
  State<CustomDataTable> createState() => _CustomDataTableState();
}

class _CustomDataTableState extends State<CustomDataTable> {
  int _currentPage = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchInputChanged);
  }

  void _onSearchInputChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant CustomDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final totalRows = widget.rows.length;
    final totalPages = (totalRows / widget.rowsPerPage).ceil();
    if (totalPages > 0 && _currentPage >= totalPages) {
      _currentPage = totalPages - 1;
    } else if (totalRows == 0) {
      _currentPage = 0;
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchInputChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFun.isDarkMode(context);
    final totalRows = widget.rows.length;
    final calculatedPages = (totalRows / widget.rowsPerPage).ceil();
    final totalPages = calculatedPages > 0 ? calculatedPages : 1;

    if (_currentPage >= totalPages) {
      _currentPage = totalPages - 1;
    }
    if (_currentPage < 0) {
      _currentPage = 0;
    }

    final startIndex = (_currentPage * widget.rowsPerPage).clamp(0, totalRows);
    final endIndex = (startIndex + widget.rowsPerPage).clamp(0, totalRows);
    final currentRows = (totalRows > 0 && startIndex < endIndex)
        ? widget.rows.sublist(startIndex, endIndex)
        : <DataRow>[];

    final resolvedSearchHint = widget.searchHint ?? 'search_hint_general'.tr;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : AppColor.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        border: Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Wrap(
              spacing: AppSizes.md,
              runSpacing: AppSizes.md,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (widget.onSearchChanged != null)
                      SizedBox(
                        width: 250,
                        height: 38,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() => _currentPage = 0);
                            widget.onSearchChanged?.call(val);
                          },
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: resolvedSearchHint,
                            prefixIcon: const Icon(Icons.search_rounded, size: 18),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 16),
                                    tooltip: 'clear_search'.tr,
                                    splashRadius: 16,
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _currentPage = 0);
                                      widget.onSearchChanged?.call('');
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            isDense: true,
                          ),
                        ),
                      ),
                    if (widget.filterWidget != null) widget.filterWidget!,
                    if (widget.trailingHeaderAction != null) widget.trailingHeaderAction!,
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Table Content or Clean Empty State
          if (widget.rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.xxl),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: isDark ? 0.12 : 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColor.primary.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        widget.emptyIcon ?? Icons.inbox_outlined,
                        size: 34,
                        color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      widget.emptyMessage ?? 'no_records_found'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (widget.emptyAction != null) ...[
                      const SizedBox(height: AppSizes.md),
                      widget.emptyAction!,
                    ],
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.sizeOf(context).width - 320,
                ),
                child: DataTable(
                  headingRowHeight: 48,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 56,
                  horizontalMargin: AppSizes.md,
                  columnSpacing: AppSizes.lg,
                  headingTextStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                  ),
                  headingRowColor: WidgetStateProperty.all(
                    isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                  ),
                  columns: widget.columns
                      .map((c) => DataColumn(label: Text(c.label), numeric: c.isNumeric))
                      .toList(),
                  rows: currentRows,
                ),
              ),
            ),

          const Divider(height: 1),

          // Pagination Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'showing_entries'.trParams({
                    'start': '${totalRows > 0 ? startIndex + 1 : 0}',
                    'end': '$endIndex',
                    'total': '$totalRows',
                  }),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      onPressed: _currentPage > 0
                          ? () => setState(() => _currentPage--)
                          : null,
                    ),
                    Text(
                      'page_x_of_y'.trParams({
                        'page': '${_currentPage + 1}',
                        'total': '$totalPages',
                      }),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      onPressed: _currentPage < totalPages - 1
                          ? () => setState(() => _currentPage++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
