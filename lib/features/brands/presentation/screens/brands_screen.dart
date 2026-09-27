import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_sizes.dart';
import '../../../../core/helper/responsive_helper.dart';
import '../../../../core/localization/app_localizations.dart';
import '../cubit/brand_cubit.dart';
import '../widgets/brand_metric_cards.dart';
import '../widgets/brand_table.dart';

/// Unified Brands Management Screen for EGO Admin Panel.
///
/// Coordinates KPI metric cards and the reorderable brand management table.
class BrandsScreen extends StatelessWidget {
  const BrandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return BlocConsumer<BrandCubit, BrandState>(
      listener: (context, state) {
        if (state is BrandError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColor.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is BrandLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is BrandLoaded) {
          final allBrands = state.brands;

          // Compute quick brand metrics
          final totalBrands = allBrands.length;
          final featuredBrands = allBrands.where((b) => b.isFeatured).length;
          final totalProducts = allBrands.fold<int>(
            0,
            (sum, b) => sum + b.productsCount,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI Metric Summary Cards
                BrandMetricCards(
                  isDesktop: isDesktop,
                  totalBrands: totalBrands,
                  featuredBrands: featuredBrands,
                  totalProducts: totalProducts,
                ),
                const SizedBox(height: AppSizes.lg),

                // Unified Reorderable Table
                BrandTable(state: state),
              ],
            ),
          );
        }

        return Center(
          child: ElevatedButton(
            onPressed: () => context.read<BrandCubit>().loadBrands(),
            child: Text('reload'.tr),
          ),
        );
      },
    );
  }
}
