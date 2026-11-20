# MiCut 디자인 시스템 — 사용자 제공 기준

기록일: 2026-11-06. 출처: 사용자가 이 채팅에 제공한 Overview, Color, Spacing, Typography, Components 전문. 아래는 모든 적용 규칙과 수치를 정리한 구현 참조본이다.

이 문서는 새 디자인의 요구사항이며 현재 구현 완료를 뜻하지 않는다. 기존 DESIGN.md의 회색 와이어프레임·추정 수치와 다를 경우 새 디자인 적용에는 이 문서를 우선한다. 실제 적용값의 최종 기준은 Figma 변수·스타일·컴포넌트다. Figma 내용을 아직 읽지 못했으므로 문서에 없는 값은 추정하지 않는다. 런타임 적용 시 DESIGN.md도 함께 갱신한다.

Figma: https://www.figma.com/design/gaEquzyI3Y2S9lGKfjgaRR/미컷?node-id=176-4374
Overview: https://app.notion.com/p/Overview-40f6817cb9838060971fe0c34984d2df
Color: https://app.notion.com/p/Color-40f6817cb9838012a62ff54b7c272e22
Typography: https://app.notion.com/p/Typography-40f6817cb9838058ae76f6768b0f6790
Spacing: https://app.notion.com/p/Spacing-40f6817cb983802eb00cc53a4b5328b6
Components: https://app.notion.com/p/Components-40f6817cb98380978e10e89401c0bb98

## Overview

디자인과 개발에서 동일한 기준을 사용한다. 같은 역할에는 같은 스타일과 컴포넌트를 사용한다.

- 단색: 속성에 맞는 Semantic 컬러 변수.
- 그라데이션: 등록된 Paint Style.
- 내부 여백과 요소 사이 간격: 같은 spacing/* Primitive.
- 모서리: radius/* Primitive.
- 타이포그래피: 역할에 맞는 Text Style.
- 새 컴포넌트를 만들기 전에 등록된 컴포넌트·변형을 확인하고 제공된 속성을 사용한다.

참조 체계: KRDS의 Primitive → Semantic 구조 및 역할 구분, Tailwind CSS의 컬러 단계 및 수치 스케일. 이를 근거로 미제공 값을 자동 채우지 않는다.
KRDS: https://www.figma.com/ko-kr/community/file/1452915208095182951/krds-v1-0-0

| 관리 방식 | 구분 | 내용 |
| --- | --- | --- |
| Variable Collection | primitive | 원본 색상, 간격, 반경, typography/font-family |
| Variable Collection | semantic | UI 용도별 컬러 |
| Text Style | 타이포그래피 | 서체, 크기, 두께, 줄 간격, 자간 |
| Paint Style | 그라데이션 | 색상 스톱, 방향, 분포 |
| Component | 반복 UI | 공통 구조, 변형, 변경 가능한 속성 |

명칭: 색상은 {색상명}/{단계}, 숫자는 {종류}/{값}, Semantic은 color/{속성}/{역할 또는 표현}[/{세부 표현}], Text Style은 {역할}/{크기}-{두께}. 특수 서체는 display/36-dunggeunmo처럼 구분한다. 크기 숫자는 px다.

## Color

팔레트: primary(주요 브랜드), secondary(보조 브랜드), gray(중립), red(오류·위험), green(성공·완료).
Primary·Secondary·Red·Green 단계: 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950. Gray는 0을 추가한 12단계.

Semantic 속성: bg(배경), text(텍스트), icon(아이콘), border(경계선). 같은 색상이라도 역할이 다르면 별도 Semantic 변수를 유지한다.

| 표현 | 의미 |
| --- | --- |
| default | 역할의 기본 표현 |
| subtle | 역할의 보조 표현 |
| bolder | 역할의 강한 표현 |
| inverse | 기본과 반대 밝기 |
| disabled | 비활성 |
| selected | 선택 상태 |
| placeholder | 콘텐츠 전 자리 표시 배경 |
| primary | 주요 브랜드 강조 |
| secondary | 보조 브랜드 강조 |
| danger | 오류·위험 행동 |
| success | 성공·완료 |

| Semantic 변수 | Primitive | 현재 값 |
| --- | --- | --- |
| color/bg/default | gray/0 | #FEFEFE |
| color/bg/subtle | gray/100 | #F4F4F5 |
| color/bg/inverse | gray/950 | #09090B |
| color/bg/disabled | gray/200 | #E4E4E7 |
| color/bg/placeholder | gray/600 | #52525B |
| color/text/default | gray/950 | #09090B |
| color/text/subtle | gray/500 | #71717A |
| color/text/inverse | gray/0 | #FEFEFE |
| color/text/disabled | gray/400 | #A1A1AA |
| color/icon/default | gray/950 | #09090B |
| color/icon/subtle | gray/300 | #D4D4D8 |
| color/icon/inverse | gray/0 | #FEFEFE |
| color/icon/disabled | gray/400 | #A1A1AA |
| color/icon/selected | gray/700 | #3F3F46 |
| color/border/default | gray/500 | #71717A |
| color/border/subtle | gray/200 | #E4E4E7 |
| color/border/bolder | gray/700 | #3F3F46 |
| color/border/disabled | gray/400 | #A1A1AA |

bg/inverse는 어두운 배경이며 text/inverse·icon/inverse는 그 위의 밝은 전경이다. 배경과 전경 대비를 확인한다. 보조 정보는 subtle, 비활성은 disabled를 사용한다.

### 그라데이션과 CTA

| Paint Style | 종류 | 참조 스톱 | 용도 |
| --- | --- | --- | --- |
| gra/bg | Linear | primary/300 → primary/100 | 주요 CTA |
| gra/radial | Radial | primary/400 → primary/100 | 하단 내비게이션 촬영 버튼 |

방향·분포는 등록된 스타일을 따른다. 그라데이션 위 텍스트·아이콘에는 별도 Semantic을 적용한다.

- 페이지 하단 플로팅 CTA·주요 행동: Primary Gradient. 현재 Primary 기본 버튼은 그라데이션이다.
- Bottom sheet·모달 강조/확인: Primary 단색.
- Bottom sheet·모달 중립 행동 및 설정·시스템 단독 일반 CTA: Tertiary; color/bg/default 또는 color/bg/subtle.
- 로그아웃·탈퇴·신고·차단 및 삭제 등 위험 행동의 최종 실행: Danger; color/bg/danger/default.
- 비활성 CTA: color/bg/disabled.

## Spacing 및 Radius

내부 여백(Padding)과 요소 사이 간격(Gap)은 같은 spacing/{값}을 사용하며 숫자는 px다.

Spacing: 0, 2, 4, 6, 8, 10, 12, 16, 20, 24, 32.
Radius: radius/10, radius/12, radius/16, radius/20, radius/24.

| 대상 | 기준 |
| --- | --- |
| 기본 화면 여백 | 20px |
| 콘텐츠 사이 기본 간격 | 20px |
| 모달 주요 요소 간격 | 16px |
| CTA 내부 요소 간격 | 8px |
| 컬렉션 카드 내부 요소 간격 | 8px |
| 하단 내비게이션 아이콘·레이블 간격 | 4px |

별도 기준이 없는 화면은 20px을 적용한다. 주요 블록 간격은 화면 레이아웃, 내부 여백·세부 간격은 컴포넌트 정의를 따른다. 콘텐츠에 따라 등록 스케일 안에서 조정할 수 있다. 같은 역할·구조에는 같은 spacing/radius를 적용하며 실제 컴포넌트 값은 Figma를 따른다.

## Typography

기본 UI: Pretendard Regular(400), Medium(500), SemiBold(600). 일부 강조 제목: Bold(700). 컬렉션 획득 등 특수 연출: DungGeunMo Regular.

역할: heading(화면·섹션·카드·모달 제목), body(본문·설명·안내·처리 상태·오류), label(버튼·탭·내비게이션·선택 항목·입력 항목명), detail(짧은 보조 설명·메타정보), display(특수 연출).

기본 크기: 24, 20, 18, 16, 14, 12, 11, 10px. 추가 크기: 36, 32, 13, 8px.

공통 스타일의 짝수 크기는 semibold/medium/regular 3종이다. 현재 사용하지 않는 두께도 유지한다. 예외 크기·별도 속성은 필요한 스타일만 유지한다. 표는 역할별 크기 내림차순, 같은 크기는 두께 내림차순으로 관리한다.

| 역할 | 크기(px) | 두께 | 줄 간격 | 자간 |
| --- | --- | --- | --- | --- |
| heading | 24, 20, 18, 16, 14, 12 | semibold, medium, regular | 140% | -2% |
| body | 24, 20 | semibold, medium, regular | 140% | -2% |
| body | 18, 16, 14 | semibold, medium, regular | 150% | -2% |
| label | 18, 16, 14, 12, 10 | semibold, medium, regular | 140% | -2% |
| label | 11 | regular만 | 140% | -2% |
| detail | 14, 12, 10 | semibold, medium, regular | 140% | -2% |

각 행은 해당 크기·두께 조합의 {역할}/{크기}-{두께} 스타일을 정의한다(예: heading/24-semibold, body/16-regular). Body 24/20을 150%로 임의 통일하지 않는다. 같은 역할·위계에는 같은 스타일을 적용하며 화면에 맞추려고 크기·자간을 임의 변경하지 않는다. 텍스트 색상은 color/text/* Semantic을 사용한다.

## Components

| 분류 | 등록 컴포넌트 |
| --- | --- |
| 버튼 | CTA1, CTA2 |
| 내비게이션 | TopBar, TabBar |
| 사진·카드 | Photo, CollectionCard |
| 촬영 컨트롤 | ratio, flash, timer, camera |
| 안내·로딩 | info, modal, loading |

| 구성 | 기준 |
| --- | --- |
| 모달 내부 여백 | 사방 20px |
| 모달 주요 요소 간격 | 16px |
| 모달 배경 | color/bg/default |
| 모달 버튼 | 1개 또는 2개 |
| 갤러리 편집·삭제 하단 버튼 영역 | 상단·좌우 20px, 하단 32px |
| Info 배경 | color/bg/default |
| Info 상하 여백 | 24px |
| Info 좌우 여백 | 20px |
| Info 안내 문구 | body/18-semibold |
| Info 버튼 | 1개 또는 2개 |

같은 역할에는 같은 컴포넌트·변형을 사용한다. 텍스트·컬러·아이콘·간격은 Figma를 따른다. 주요·중립·위험·비활성을 구분하며 일부 예외 상황에서는 컴포넌트 변형을 허용한다.

## Figma에서 추가 확인할 사항

- Primary, Secondary, Red, Green 전체 실제 색상값과 미제공 Gray 단계.
- 브랜드·danger·success Semantic의 실제 Primitive 매핑.
- 그라데이션 방향·분포·정확한 스톱 위치.
- CTA1/CTA2 등 컴포넌트 크기·반경·변형·속성 및 상태별 전경색.
- 화면별 레이아웃·아이콘·정적 에셋과 추가/특수 타이포그래피의 전체 속성.

미확정 항목을 기존 scaffold-brand의 임시 시안이나 Tailwind 기본값으로 확정하지 않는다. 컬렉션 획득 연출의 스타일 정의는 서버 기능 구현·카드 지급 지원의 근거가 아니다.
