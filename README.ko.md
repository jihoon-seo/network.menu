# network.menu

[English](README.md)

Gen5W 헤드유닛에서 국내 펌웨어가 Kia Connect 화면만 보여 주는 자리에 **설정 > 데이터/네트워크**
메뉴(**Wi-Fi**, **핫스팟** 탭 포함)를 되살리는 [NEMESIS](https://github.com/xwtk/hmg_nemesis) 패키지입니다.

> **시험한 차량은 한 대뿐입니다:** 펌웨어 `DE22EV.KOR.0000.V039.001.260902` (onebin `de22ev_kr`).
> 비공식 프로젝트입니다. [면책](#면책)을 읽어 주세요.

## 왜 필요한가

설정 앱은 기능 `com.hkmc.software.wifihotspot`이 있을 때만 Kia Connect 화면 대신 "데이터/네트워크"
(Kia Connect + Wi-Fi + 핫스팟 탭)를 보여 주고, Wi-Fi 탭은 `android.hardware.wifi`도 필요합니다. 국내 onebin의
`featurexml.cfg`는 모두 `-/system/etc/permissions/com.hkmc.software.wifihotspot.xml` 줄로 핫스팟 기능을 지우고,
이미지에는 그 기능 파일도 없습니다.

## 하는 일

설치 시(NEMESIS에서 root로):

1. 바꿀 파일을 모두 `/data/nemesis/backup/network.menu/`에 스냅샷합니다(없던 파일은 "없음"으로 기록).
2. `/system/onebin/*/featurexml.cfg` 중 해당 줄이 있는 파일에서 `wifihotspot` 제거 줄을 `#`으로 주석 처리합니다.
   다른 줄, CRLF 줄바꿈, 다른 onebin은 그대로 둡니다.
3. `/system/etc/permissions/`에 `com.hkmc.software.wifihotspot.xml`, `android.hardware.wifi.xml`을 추가합니다.
4. PackageManager가 기능을 다시 읽도록 재부팅합니다.

제거하면 스냅샷을 바이트 단위로 그대로 되돌리고, 없던 파일은 지웁니다.
[wireless.projection](https://github.com/xwtk/hmg_nemesis/tree/main/Sources/packages/wireless-projection)이
설치돼 있으면 그 패키지도 쓰는 `android.hardware.wifi.xml`은 남겨 둡니다. 설치된 상태에서 업데이트해도 처음
스냅샷이 유지됩니다.

메뉴만 켜는 것입니다. Wi-Fi 탭은 헤드유닛에 Wi-Fi 칩이 있어야 동작합니다(시험한 차에는 있으며, 드라이버는
Wi-Fi를 켤 때 올라옵니다).

## 필요 조건

- 헤드유닛에 [NEMESIS](https://github.com/xwtk/hmg_nemesis).
- 국내(`*_kr`) onebin. 다른 onebin은 경고와 함께 설치되며 시험하지 않았습니다.

## 설치

[Releases](../../releases)에서 받습니다:

| 파일 | 내용 |
|---|---|
| `network.menu-<버전>.USB.zip` | USB 구성: `NEMESIS.data` + `packages/`, 사용 안내 |
| `network.menu-<버전>.zip` | NEMESIS 패키지 자체 |
| `SHA256SUMS` | 두 파일의 체크섬 |

1. USB zip 안의 `NEMESIS.data`와 `packages` 폴더를 USB 최상위에 놓습니다.
2. 시동을 켜고 1분쯤 기다린 뒤 USB를 꽂고 NEMESIS에서 설치(또는 업데이트)를 확인합니다.
3. 헤드유닛이 스스로 재부팅되고, 설정에 "데이터/네트워크"가 나타납니다.

제거는 NEMESIS Manager에서 한 뒤 헤드유닛을 재부팅합니다. 차량 로그: `/data/nemesis/network.menu.log`.

## 빌드와 테스트

```
./build.sh          # -> dist/ (Python 3 필요)
./tests/run.sh      # PC 테스트: 가짜 /system, /data 에서 설치·업데이트·제거
```

PC 테스트는 `NM_SYS` / `NM_DATA`를 가짜 트리로 지정해 패키지 스크립트를 그대로 실행하고, 제거 후 원래
바이트로 돌아오는지까지 파일마다 확인합니다.

## 면책

개인 취미로 만든 비공식 프로젝트이며 현대자동차그룹, 기아, 현대모비스, NEMESIS 제작자와 관련이 없고 승인받지
않았습니다. `/system`의 파일을 바꾸므로 실패하면 헤드유닛이 이상하게 동작할 수 있고, 수정으로 보증을 받지 못할 수
있습니다. 차량 한 대, 펌웨어 하나에서만 시험했습니다. 사용에 따른 책임은 사용자에게 있으며 어떠한 보증도 없습니다
([LICENSE](LICENSE)).

## 라이선스

[GNU AGPL-3.0](LICENSE). 스크립트는 xwtk/hmg_nemesis의 wireless-projection 패키지(AGPL-3.0)를 수정한 것입니다
([NOTICE](NOTICE.md)).
