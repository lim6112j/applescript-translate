# PreviewTranslate

macOS 미리보기(Preview)에서 PDF를 읽다가 **⌥⌘T** 를 누르면 현재 페이지 전체가 영어 → 한국어로 번역되어 작은 창에 표시됩니다.

- 원본 PDF는 전혀 수정하지 않습니다.
- 영어 원문과 한국어 번역이 문단 단위로 나란히 표시됩니다. `한국어` / `영어 + 한국어` 로 전환할 수 있습니다.
- 번역 창은 항상 위에 떠 있고, 미리보기 옆에 배치됩니다. 옮긴 위치는 다음 실행 때 기억합니다.

## 요구 사항

- macOS 26 이상 (Apple 온디바이스 번역 프레임워크 사용)
- Xcode 26 이상 (Swift 6.4)
- 손쉬운 사용(Accessibility) 권한 — 미리보기의 현재 페이지를 읽기 위해 필요
- 온디바이스 번역 대체 엔진은 **Apple 실리콘(M1 이상)** 에서만 동작합니다.
  Intel Mac에서는 Google 번역만 사용할 수 있습니다 (아래 '번역 엔진' 참고).

## 설치

```bash
./scripts/build-app.sh
cp -R .build/out/PreviewTranslate.app /Applications/
open /Applications/PreviewTranslate.app
```

처음 실행하면 손쉬운 사용 권한 안내가 뜹니다.
**시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용** 에서 `PreviewTranslate` 를 켜 주세요.

> 스크립트는 가능하면 Apple Development 서명 인증서로 서명합니다. 서명이 바뀌면 macOS가
> 권한을 다시 물어보기 때문에, 서명 인증서가 없을 때(ad-hoc)는 재빌드 후 권한을 다시 허용해야 합니다.

## 사용

### 처음 한 번만

1. `PreviewTranslate.app` 을 실행합니다. 메뉴 막대에 책 아이콘이 생기고, 화면 오른쪽에
   번역 창이 하나 뜹니다.
2. 손쉬운 사용 권한 안내가 나오면 **권한 설정 열기** 를 누릅니다.
3. **시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용** 에서 `PreviewTranslate` 를 켭니다.
4. 앱을 한 번 껐다 켜면 준비 끝입니다. 이후로는 로그인할 때마다 직접 실행해 주세요
   (로그인 항목 등록은 **시스템 설정 → 일반 → 로그인 항목** 에서 할 수 있습니다).

권한을 켜기 전에는 창에 "미리보기를 제어하려면 손쉬운 사용 권한이 필요합니다" 라고 표시됩니다.

### 평소 사용법

1. 미리보기에서 PDF를 엽니다.
2. **미리보기 창을 한 번 클릭**해서 포커스를 줍니다. (다른 앱이 앞에 있으면 동작하지 않습니다.)
3. **⌥⌘T** 를 누릅니다.
4. 1~2초 뒤 오른쪽 번역 창에 현재 페이지가 표시됩니다.
5. 다음 페이지로 넘기고 다시 **⌥⌘T** 를 누르면 그 페이지로 갱신됩니다.

번역 창 위쪽에 `파일이름 · 862/1,126페이지` 처럼 어느 페이지를 번역했는지 표시되고,
그 아래에 사용한 엔진(`Google 번역` 또는 `Apple 온디바이스 번역`)이 나옵니다.

### 창 조작

| 동작 | 방법 |
|---|---|
| 현재 페이지 번역 | 미리보기에 포커스를 두고 **⌥⌘T** |
| 한국어만 보기 | 창 상단 **한국어** |
| 원문과 함께 보기 | 창 상단 **영어 + 한국어** (기본값) |
| 번역 복사 | 창 상단 **복사** — 4초 뒤 원래 클립보드 내용으로 되돌아갑니다 |
| 창 위치 옮기기 | 제목 표시줄을 끌어서 이동. 위치는 자동 저장됩니다 |
| 창 닫기 | 왼쪽 위 빨간 버튼. **⌥⌘T** 를 다시 누르면 같은 위치에 열립니다 |
| 번역 창 다시 열기 | 메뉴 막대 책 아이콘 → **번역 창 보기** |
| 앱 종료 | 메뉴 막대 책 아이콘 → **PreviewTranslate 종료** |

번역 창은 항상 다른 창 위에 떠 있고(`⌥⌘T` 로 번역해도 미리보기의 포커스는 빼앗지 않습니다),
데스크스페이스를 바꿔도 따라옵니다.

### 이런 경우에는

| 상황 | 표시 / 해결 |
|---|---|
| 미리보기가 실행 중이 아님 | "미리보기(Preview)가 실행 중이 아닙니다." |
| PDF 문서 창이 없음 | "미리보기에 열린 PDF 문서가 없습니다." |
| 스캔한 이미지 PDF (글자 없음) | "이 페이지에 번역할 텍스트가 없습니다." — OCR이 안 된 스캔본은 번역할 수 없습니다 |
| 이미 한국어인 페이지 | "이 페이지는 이미 한국어입니다." |
| Google이 막히거나 오프라인 | 자동으로 Apple 온디바이스 엔진으로 넘어갑니다. 페이지당 30~45초 걸립니다 |

### 번역 엔진

1. **Google 번역** — 페이지당 약 1초. 비공식 웹 엔드포인트를 사용합니다.
2. **Apple 온디바이스 번역** — 네트워크가 없거나 Google이 막혔을 때 자동 대체.
   완전히 오프라인이고 무료지만 **Apple 실리콘(M1 이상)에서만** 동작합니다.
   이 Mac 기준 초당 약 90자라 페이지당 30~45초 걸립니다.
   한 번에 약 2,500자까지만 번역합니다.

> Intel Mac에는 Neural Engine이 없어 Apple 온디바이스 번역을 쓸 수 없습니다.
> `LanguageAvailability` 는 Intel에서도 언어쌍을 `supported` 로 보고하지만 실제로는
> 언어팩이 설치되지 않아, 앱이 이를 감지해 "이 Mac에서는 Apple 온디바이스 번역을
> 사용할 수 없습니다" 라고 안내합니다. 따라서 Intel Mac에서는 Google 번역이
> 유일한 엔진이고, 네트워크가 없으면 번역할 수 없습니다.

강제로 온디바이스 엔진을 쓰려면 (Apple 실리콘 전용):

```bash
PREVIEWTRANSLATE_ENGINE=apple /Applications/PreviewTranslate.app/Contents/MacOS/PreviewTranslate &
```

시스템 프록시를 우회해 Google에 직접 연결하려면:

```bash
PREVIEWTRANSLATE_BYPASS_PROXY=1 /Applications/PreviewTranslate.app/Contents/MacOS/PreviewTranslate &
```

## 구조

```
Sources/
  PreviewTranslateCore/     # UI 없이 테스트 가능한 순수 로직
    TextCleaning            #   PDF 텍스트 정리 (보이지 않는 문자, 각주 번호, 줄바꿈)
    TextRun / PageLine      #   폰트 정보로 제목·캡션·본문 줄 복원
    SentenceSplitter        #   문장 분리
    TextChunker             #   요청 크기로 묶기
    CharacterBudget         #   온디바이스 엔진용 글자 수 제한
    PreviewTitleParser      #   창 제목에서 현재 페이지 번호
    GoogleResponseParser    #   translate_a/single 응답 파싱
  PreviewTranslate/
    Preview/                #   PDFKit 텍스트 추출, 미리보기 AX 접근
    Translation/            #   Google / Apple 엔진, 폴백 조정자
    UI/                     #   번역 창
    Hotkey/                 #   전역 단축키 (Carbon)
```

## 개발

```bash
swift test                     # 43개 단위 테스트
swift build                    # 디버그 빌드
./scripts/build-app.sh         # .app 번들 생성 (release)
```

### 참고 사항

- `Package.swift` 의 플랫폼은 `26.0` 이어야 합니다. 이 값은 배포 대상(deployment target),
  즉 실행 파일의 `minos` 가 되고, LaunchServices가 번들 실행 전에 이 값을 검사합니다.
  실제 OS보다 높게 잡으면 실행 시 `kLSIncompatibleSystemVersionErr`(-10825,
  "The app cannot run on the current OS version")로 **실행이 거부**됩니다.
  SDK 버전은 이 값과 무관하게 Xcode의 최신 SDK(현재 26.5)가 쓰이므로
  `LanguageAvailability` 동작에는 영향이 없습니다.
  > 터미널에서 실행 파일을 직접 실행하면 이 검사를 건너뛰기 때문에 실행되는 것처럼 보입니다.
  > Finder 더블클릭이나 `open` 으로 실행할 때만 실패합니다.
- Google 엔진은 기본적으로 시스템 프록시 설정(PAC 포함)을 그대로 따릅니다. 인터넷이
  프록시를 통해서만 나가는 네트워크에서는 이게 유일한 경로입니다. 반대로 PAC 프록시가
  이 호스트를 막는 네트워크라면 `PREVIEWTRANSLATE_BYPASS_PROXY=1` 로 직접 연결합니다.
- 미리보기는 선택 영역을 스크립트로 노출하지 않습니다. 그래서 '선택한 텍스트 번역' 대신
  페이지 단위로 번역합니다.
