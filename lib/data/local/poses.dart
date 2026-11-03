/// 컬렉션 포즈 목록. 서버가 `result.card_ids` 로 내려주는 ID와 맞춘다.
/// 실제 목록은 AI/기획팀 확정 후 교체.
class Pose {
  const Pose(this.id, this.name);
  final String id;
  final String name;
  int get number => int.tryParse(id) ?? 0;
}

const kPoses = <Pose>[
  Pose('001', '브이'),
  Pose('002', '하트'),
  Pose('003', '꽃밭'),
  Pose('004', '응원 자세'),
  Pose('005', '점프'),
  Pose('006', '앉기'),
  Pose('007', '손 흔들기'),
  Pose('008', '윙크'),
  Pose('009', '노래'),
];
