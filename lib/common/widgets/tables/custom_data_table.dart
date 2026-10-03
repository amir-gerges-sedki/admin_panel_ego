import 'package:flutter/material.dart';
import '../../../core/constant/app_colors.dart';
import '../../../core/constant/app_sizes.dart';
import '../../../core/helper/helper_fun.dart';
import '../../../core/localization/app_localizations.dart';

class DataTableColumn {
  final String label;
  final bool isNumeric;
  final double? width;
  final void Function(int columnIndex, bool ascending)? onSort;
  final String? tooltip;

  const DataTableColumn({
    required this.label,
    this.isNumeric = false,
    this.width,
    this.onSort,
    this.tooltip,
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
  final int? sortColumnIndex;
  final bool sortAscending;
  final bool? showCheckboxColumn;
  final ValueChanged<bool?>? onSelectAll;

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
    this.sortColumnIndex,
    this.sortAscending = true,
    this.showCheckboxColumn,
    this.onSelectAll,
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
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 680;

                final searchWidget = widget.onSearchChanged != null
                    ? SizedBox(
                        width: isCompact ? null : (constraints.maxWidth > 950 ? 220 : 170),
                        height: 36,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() => _currentPage = 0);
                            widget.onSearchChanged?.call(val);
                          },
                          style: const TextStyle(fontSize: 12.5),
                          decoration: InputDecoration(
                            hintText: resolvedSearchHint,
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 17,
                              color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 15),
                                    tooltip: 'clear_search'.tr,
                                    splashRadius: 14,
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _currentPage = 0);
                                      widget.onSearchChanged?.call('');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isDark ? AppColor.darkBorder : AppColor.lightBorder.withValues(alpha: 0.6),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColor.primary,
                                width: 1.2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            isDense: true,
                          ),
                        ),
                      )
                    : null;

                final actions = Row(
                  mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    if (searchWidget != null)
                      isCompact ? Expanded(child: searchWidget) : searchWidget,
                    if (widget.filterWidget != null) ...[
                      const SizedBox(width: AppSizes.sm),
                      widget.filterWidget!,
                    ],
                    if (widget.trailingHeaderAction != null) ...[
                      const SizedBox(width: AppSizes.sm),
                      widget.trailingHeaderAction!,
                    ],
                  ],
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 16,
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
                      const SizedBox(height: AppSizes.sm),
                      actions,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColor.textPrimaryDark : AppColor.textPrimaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    actions,
                  ],
                );
              },
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
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: isDark ? 0.10 : 0.07),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.emptyIcon ?? Icons.inbox_outlined,
                        size: 28,
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
            LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;

                // Dynamically distribute column spacing to gracefully fill available page width
                final columnCount = widget.columns.length;
                final dynamicSpacing = columnCount > 1
                    ? ((availableWidth - (columnCount * 80)) / (columnCount + 1))
                        .clamp(AppSizes.md, 70.0)
                    : AppSizes.lg;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: availableWidth,
                    ),
                    child: DataTable(
                      showCheckboxColumn: widget.showCheckboxColumn ?? (widget.onSelectAll != null),
                      onSelectAll: widget.onSelectAll,
                      headingRowHeight: 44,
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 52,
                      horizontalMargin: AppSizes.md,
                      columnSpacing: dynamicSpacing,
                      sortColumnIndex: widget.sortColumnIndex,
                      sortAscending: widget.sortAscending,
                      headingTextStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.2,
                        color: isDark ? AppColor.textSecondaryDark : AppColor.textSecondaryLight,
                      ),
                      headingRowColor: WidgetStateProperty.all(
                        isDark ? AppColor.darkSubCard : AppColor.lightSubCard.withValues(alpha: 0.6),
                      ),
                      columns: widget.columns.map((c) {
                        return DataColumn(
                          label: Text(
                            c.label,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          numeric: c.isNumeric,
                          onSort: c.onSort,
                          tooltip: c.tooltip,
                        );
                      }).toList(),
                      rows: currentRows,
                    ),
                  ),
                );
              },
            ),

          const Divider(height: 1),

          // Pagination Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 8),
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
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColor.textMutedDark : AppColor.textMutedLight,
                  ),
                ),
                Builder(
                  builder: (context) {
                    final isRtl = Directionality.of(context) == TextDirection.rtl;
                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColor.darkSubCard : AppColor.lightSubCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? AppColor.darkBorder : AppColor.lightBorder,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isRtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                              size: 18,
                            ),
                            tooltip: 'previous_page'.tr,
                            visualDensity: VisualDensity.compact,
                            splashRadius: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: _currentPage > 0
                                ? () => setState(() => _currentPage--)
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
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
                          ),
                          IconButton(
                            icon: Icon(
                              isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                              size: 18,
                            ),
                            tooltip: 'next_page'.tr,
                            visualDensity: VisualDensity.compact,
                            splashRadius: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: _currentPage < totalPages - 1
                                ? () => setState(() => _currentPage++)
                                : null,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
