import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teenple_frontend/features/auth/api/school_api.dart';
import 'package:teenple_frontend/features/auth/models/school_model.dart';
import 'package:teenple_frontend/features/auth/provider/signup_school_provider.dart';

void main() {
  group('SignupSchoolNotifier', () {
    test('입력 변경 후 늦게 도착한 이전 검색 결과를 버린다', () async {
      final api = _ControllableSchoolApi();
      final notifier = SignupSchoolNotifier(api);

      final oldSearch = notifier.searchSchools('오');
      notifier.updateKeyword('오남');

      api.complete(
        '오',
        const [
          SchoolModel(id: 1, name: '오산고등학교', regionName: '서울특별시'),
        ],
      );
      await oldSearch;

      expect(notifier.state.keyword, '오남');
      expect(notifier.state.schools, isEmpty);
      expect(notifier.state.isLoading, isFalse);
    });

    test('가장 최근 검색 결과만 상태에 반영한다', () async {
      final api = _ControllableSchoolApi();
      final notifier = SignupSchoolNotifier(api);

      final oldSearch = notifier.searchSchools('오');
      notifier.updateKeyword('오남');
      final latestSearch = notifier.searchSchools('오남');

      api.complete(
        '오남',
        const [
          SchoolModel(id: 1223, name: '오남고등학교', regionName: '경기도'),
        ],
      );
      await latestSearch;

      api.complete(
        '오',
        const [
          SchoolModel(id: 239, name: '오산고등학교', regionName: '서울특별시'),
        ],
      );
      await oldSearch;

      expect(notifier.state.schools, hasLength(1));
      expect(notifier.state.schools.single.id, 1223);
      expect(notifier.state.schools.single.name, '오남고등학교');
    });

    test('학교 선택 시 표시 목록을 유지하고 진행 중 요청만 무효화한다', () async {
      final api = _ControllableSchoolApi();
      final notifier = SignupSchoolNotifier(api);

      final search = notifier.searchSchools('오산고');
      api.complete(
        '오산고',
        const [
          SchoolModel(id: 239, name: '오산고등학교', regionName: '서울특별시'),
          SchoolModel(id: 1224, name: '오산고등학교', regionName: '경기도'),
        ],
      );
      await search;

      notifier.selectSchoolName('오산고등학교');

      expect(notifier.state.keyword, '오산고등학교');
      expect(notifier.state.schools, hasLength(2));
    });
  });

  test('SchoolModel이 학교 식별자와 지역 정보를 함께 파싱한다', () {
    final school = SchoolModel.fromJson({
      'id': 1224,
      'name': '오산고등학교',
      'regionId': 9,
      'regionName': '경기도',
    });

    expect(school.id, 1224);
    expect(school.name, '오산고등학교');
    expect(school.regionId, 9);
    expect(school.regionName, '경기도');
  });
}

class _ControllableSchoolApi extends SchoolApi {
  _ControllableSchoolApi() : super(Dio());

  final Map<String, Completer<List<SchoolModel>>> _requests = {};

  @override
  Future<List<SchoolModel>> searchSchools(String keyword) {
    final completer = Completer<List<SchoolModel>>();
    _requests[keyword] = completer;
    return completer.future;
  }

  void complete(String keyword, List<SchoolModel> schools) {
    _requests[keyword]!.complete(schools);
  }
}
