# gen_xcode_pbx.py 의 리터럴 `\t` 문자열 vs 실제 탭 혼용

## 상황 / 의도

`scripts/gen_xcode_pbx.py` 는 `pbxproj` 를 f-string 템플릿으로 생성한다. 파일 내부 문자열에 **리터럴 `\t`** (역슬래시+t 두 글자) 시퀀스가 섞여 있는데, 이는 실제 탭 문자(\x09)가 아니다. Edit 툴로 `\t` 를 포함한 라인을 매칭하려 하면 "old_string not found" 오류가 발생한다.

## 잘못된 접근

Edit 툴에 `\t` 가 포함된 old_string 을 그대로 넣어 매칭 시도 → 파일 실제 내용과 불일치로 실패.

## 올바른 해결

파일을 Python 으로 읽어 `repr()` 로 실제 내용을 확인한 뒤, **Python 스크립트**로 직접 치환한다.

```python
# 실제 문자 확인
with open("scripts/gen_xcode_pbx.py", "rb") as f:
    chunk = f.read(500)
print(repr(chunk))
# → b'...\\t...' 이면 리터럴 \t, b'...\t...' 이면 실제 탭

# 치환 예
content = open("scripts/gen_xcode_pbx.py").read()
content = content.replace(
    'old literal \\t line',
    'new literal \\t line'
)
open("scripts/gen_xcode_pbx.py", "w").write(content)
```

일부 엔트리(예: `FR_APPSETTINGS_TEST`)는 실제 탭을 사용하는 경우도 있으므로, 섹션마다 `repr()` 로 먼저 확인해야 한다.

## 참고

- `scripts/gen_xcode_pbx.py`
- 커밋: `feat(pane): rename / new folder / new file (F2 / ⌥K / ⌃N)`
