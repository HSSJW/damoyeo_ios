# DAMOYEO - IOS
| 시연영상 : https://youtube.com/shorts/qnH6POEvXPE

## 소개
- 다모여는 Swift와 Firebase 기반의 iOS 네이티브 모바일 애플리케이션입니다.
- 사용자는 모집 게시글 작성을 통해 사람을 모으고 다양한 관심사 게시글에 참여하여 편리하게 팀을 구성할 수 있습니다.

### 기술 스택
- Swift 5.0+: iOS 네이티브 개발 언어
- UIKit: iOS UI 프레임워크
- Firebase:
  - 사용자 인증 (Firebase Authentication)
  - 데이터 저장 및 관리 (Firestore Database)
  - 파일 업로드 및 저장 (Firebase Storage)
  - 실시간 메시징 (Firestore Realtime)
- Gemini AI API: AI 기반 게시물 자동 생성
- Daum 주소 검색 API: 정확한 주소 입력 기능
- WebKit: 주소 검색 웹뷰

#### :bulb: 프로젝트 소개
|본 프로젝트는 iOS 프로그래밍 수업의 개인 프로젝트로 진행되었습니다. Swift와 iOS 네이티브 개발 기술을 학습하고 실제 앱 개발 경험을 쌓기 위해 제작되었습니다.

### 주요 기능
:sparkles 회원가입 및 로그인

Firebase Authentication: 이메일/비밀번호 기반 인증
사용자 정보 관리: 이름, 닉네임, 전화번호, 프로필 이미지
자동 로그인: 로그인 상태 유지 및 자동 인증

:sparkles: AI 게시물 생성 :robot:

자연어 입력: "이번 주말에 한강에서 치킨 먹으면서 친목하고 싶어요"
Gemini AI API: 자연어를 구조화된 게시물로 자동 변환
스마트 추천: 카테고리, 지역, 인원, 비용 자동 제안
실시간 미리보기: 생성된 내용을 즉시 확인 및 수정 가능

:sparkles: 모집 게시글 관리

게시글 작성/수정/삭제: 완전한 CRUD 기능
이미지 업로드: 최대 10장의 사진 첨부 (Camera/Gallery)
다양한 카테고리: 친목, 스포츠, 스터디, 여행, 알바, 게임, 봉사, 헬스, 음악, 기타
정렬 및 필터: 최신순, 가나다순, 카테고리별 필터링
새로고침: Pull-to-refresh 지원

:sparkles: 모집 게시글 상세 기능

상세 정보 확인: 제목, 내용, 장소, 시간, 비용, 모집인원
참여 시스템: 참가 신청/취소, 실시간 참가자 수 확인
참여자 목록: 참가자 리스트 및 개별 채팅 기능
좋아요: 관심 게시물 찜하기
작성자 권한: 본인 게시물 수정/삭제

:sparkles: 실시간 채팅 :speech_balloon:

1:1 채팅: 모집 글 작성자와 지원자 간 개별 채팅
실시간 메시징: Firestore를 활용한 실시간 메시지 전송
채팅방 관리: 고정, 나가기, 읽음 표시
사용자 프로필: 채팅 상대방 프로필 정보 확인

:sparkles: 활동 내역 관리

내 모집: 작성한 게시물 목록 및 관리
참가한 모집: 참여 중인 모임 리스트
찜한 게시물: 좋아요 표시한 게시물 모음
활동 통계: 게시물 작성 수 및 참여 이력

:sparkles: 프로필 관리

개인정보 수정: 프로필 이미지, 닉네임, 전화번호 변경
계정 보안: 비밀번호 변경 및 계정 관리
Firebase Storage: 프로필 이미지 클라우드 저장

:sparkles: 주소 검색 및 위치 기능

다음 주소 검색: WebKit 기반 정확한 주소 입력
상세 주소: 건물명, 랜드마크 등 부가 정보
위치 기반 검색: 지역별 게시물 필터링


개발 학습 과정
이 프로젝트를 통해 다음과 같은 iOS 개발 기술들을 학습하고 적용했습니다:
:apple: iOS 네이티브 개발

UIKit 프레임워크: Auto Layout, UITableView, UICollectionView, UINavigationController
MVC 패턴: Model-View-Controller 아키텍처 적용
Delegate Pattern: 컴포넌트 간 통신 및 데이터 전달
Extension 활용: 코드 재사용성 및 가독성 향상

:fire: Firebase 백엔드 서비스

Firebase Authentication: 사용자 인증 시스템 구현
Firestore Database: NoSQL 데이터베이스 설계 및 CRUD 연산
Firebase Storage: 이미지 파일 업로드 및 관리
실시간 데이터: 채팅 및 게시물 실시간 업데이트

:robot: AI 서비스 연동

Google Gemini API: 자연어 처리 및 구조화된 데이터 생성
REST API 통신: URLSession을 활용한 HTTP 통신
JSON 파싱: Codable 프로토콜 활용한 데이터 변환

:iphone: iOS 고급 기능

WebKit 프레임워크: 다음 주소 검색 API 연동
PHPickerViewController: iOS 14+ 사진 선택 인터페이스
Custom UI Components: 재사용 가능한 UI 컴포넌트 제작
Image Caching: 성능 최적화를 위한 이미지 캐싱 시스템

### ✅ 프로젝트 구조
```
damoyeo/
├── Controller/
│   ├── Auth/
│   │   └── AuthGate.swift
│   ├── Chat/
│   │   ├── ChatViewController.swift
│   │   └── ChatDetailViewController.swift
│   ├── Post/
│   │   ├── PostListViewController.swift
│   │   ├── PostDetailViewController.swift
│   │   ├── CreatePostViewController.swift
│   │   └── AIPostGeneratorViewController.swift
│   └── Profile/
│       ├── ProfileViewController.swift
│       ├── LoginViewController.swift
│       └── EditProfileViewController.swift
├── Model/
│   ├── Post.swift
│   └── ChatModels.swift
├── View/
│   ├── PostTableViewCell.swift
│   ├── ChatRoomCell.swift
│   └── MessageCell.swift
├── Util/
│   ├── FirebaseAIManager.swift
│   ├── ImageCacheManager.swift
│   └── DaumAddressSearchViewController.swift
└── Resources/
    ├── GoogleService-Info.plist
    └── Info.plist
```

### ✅ 학습 성과
:books: iOS 개발 역량 향상

Swift 언어: 옵셔널, 클로저, 프로토콜 등 핵심 개념 숙달
UIKit 마스터: Table View, Collection View, Navigation 등 UI 컴포넌트 활용
Auto Layout: 다양한 화면 크기 대응 및 반응형 UI 구현
Memory Management: ARC 이해 및 메모리 누수 방지

:fire: 백엔드 서비스 연동

Firebase 생태계: 인증, 데이터베이스, 스토리지 통합 활용
NoSQL 데이터베이스: Firestore의 컬렉션-문서 구조 설계
실시간 통신: Snapshot Listener를 활용한 실시간 데이터 동기화

:robot: 최신 기술 도입

AI 서비스 활용: 실제 프로덕트에 AI 기능 통합 경험
API 통신: RESTful API 연동 및 비동기 처리
성능 최적화: 이미지 캐싱, 데이터 로딩 최적화


향후 개선 계획
:rocket: 기능 확장

 푸시 알림: Firebase Cloud Messaging 연동
 지도 연동: 모임 장소 지도 표시 기능
 평가 시스템: 모임 참가자 간 평점 기능
 카테고리 확장: 더 다양한 모임 카테고리 추가

:hammer_and_wrench: 기술적 개선

 SwiftUI 마이그레이션: 최신 UI 프레임워크 도입
 Combine 활용: 반응형 프로그래밍 패턴 적용
 코어 데이터: 오프라인 데이터 캐싱
 테스트 코드: Unit Test 및 UI Test 작성

:iphone: 사용자 경험 향상

 다크 모드: 시스템 테마 대응
 접근성: VoiceOver 및 접근성 기능 지원
 국제화: 다국어 지원
 애니메이션: 부드러운 화면 전환 효과
