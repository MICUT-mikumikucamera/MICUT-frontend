/// 컬렉션 카드 12장.
///
/// 백엔드 명세 v0.3 `GET /api/v1/collection` 이 돌려주는 `id` / `no` / `name` 과 같다.
/// 서버 응답이 있으면 그쪽을 쓰고, 이 목록은 서버를 못 부를 때의 기본값이다.
class Pose {
  const Pose(this.id, this.no, this.name);

  /// 서버 카드 id (`v_sign` 등). `result.card_ids` 의 값과 같다.
  final String id;

  /// 화면의 `#001` 번호.
  final int no;
  final String name;

  int get number => no;
}

const kPoses = <Pose>[
  Pose('gyaru_peace', 1, '갸루 피스'),
  Pose('v_sign', 2, '브이'),
  Pose('half_heart', 3, '반하트'),
  Pose('full_heart', 4, '완전 하트'),
  Pose('wave', 5, '손 인사'),
  Pose('miku_arms', 6, '미쿠 양팔'),
  Pose('kiss', 7, '뽀뽀'),
  Pose('cheek_poke', 8, '볼콕'),
  Pose('flower_pose', 9, '꽃받침'),
  Pose('gdg_pose', 10, 'GDG 포즈'),
  Pose('alien_fingers', 11, '손가락으로 외계인 따라하기'),
  Pose('leek', 12, '대파 들기'),
];

Pose? poseById(String id) => kPoses.where((p) => p.id == id).firstOrNull;
