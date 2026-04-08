import '../models/post_summary.dart';
import '../models/school_response.dart';

abstract class SchoolRepository {
  Future<SchoolResponse> getSchoolDetail({
    required int schoolId,
    int page = 0,
    int size = 10,
  });

  Future<List<PostSummary>> getPostsByBoard({
    required int boardId,
    int page = 0,
    int size = 10,
  });
}