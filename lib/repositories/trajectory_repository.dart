import '../models/trajectory.dart';
import '../services/api_service.dart';
import '../utils/result.dart';

class TrajectoryRepository {
  final ApiService _apiService;

  TrajectoryRepository(this._apiService);

  Future<Result<List<Trajectory>, Exception>> getTrajectories() async {
    return await _apiService.fetchTrajectories();
  }

  Future<Result<Trajectory, Exception>> createTrajectory(Trajectory trajectory) async {
    return await _apiService.createTrajectory(trajectory);
  }

  Future<Result<Trajectory, Exception>> updateTrajectory(Trajectory trajectory) async {
    return await _apiService.updateTrajectory(trajectory);
  }

  Future<Result<void, Exception>> deleteTrajectory(String id) async {
    return await _apiService.deleteTrajectory(id);
  }
}
