import '../datasources/reports_remote_data_source.dart';
import '../models/erp_report_models.dart';

abstract class ReportsRepository {
  Future<ComprehensiveErpReportModel> getComprehensiveReport({
    required DateTime startDate,
    required DateTime endDate,
    String? branchId,
  });
}

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteDataSource remoteDataSource;

  ReportsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ComprehensiveErpReportModel> getComprehensiveReport({
    required DateTime startDate,
    required DateTime endDate,
    String? branchId,
  }) {
    return remoteDataSource.getComprehensiveReport(
      startDate: startDate,
      endDate: endDate,
      branchId: branchId,
    );
  }
}
