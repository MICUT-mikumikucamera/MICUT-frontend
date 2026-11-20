/// 컬렉션 포즈 목록. 서버가 `result.card_ids` 로 내려주는 ID와 맞춘다.
/// 이름이 원본에서 확인되지 않은 기존 ID는 원본 미확인 표기(???)를 유지한다.
class Pose {
  const Pose(this.id, this.name);
  final String id;
  final String name;
  int get number => int.tryParse(id) ?? 0;
}

const kPoses = <Pose>[
  Pose('001', '브이'),
  Pose('002', '하트'),
  Pose('003', '???'),
  Pose('004', '???'),
  Pose('005', '???'),
  Pose('006', '???'),
  Pose('007', '???'),
  Pose('008', '???'),
  Pose('009', '???'),
];
