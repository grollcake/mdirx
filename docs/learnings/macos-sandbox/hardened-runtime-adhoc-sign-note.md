# Hardened Runtime + ad-hoc 서명의 "Disabling hardened runtime" note 는 정상

## 상황 / 의도

스캐폴딩 통과 조건에서 `ENABLE_HARDENED_RUNTIME=YES` 를 명시한 뒤 `xcodebuild build` 를 돌렸더니 로그 끝에 다음 메시지가 출력됨:

```
note: Disabling hardened runtime with ad-hoc codesigning. (in target 'MdirX' from project 'MdirX')
```

처음엔 "통과 조건의 Hardened Runtime ON 이 사실상 꺼진 것 아닌가" 의심이 들었다.

## 올바른 해결

로컬 dev 빌드에서 Xcode 가 ad-hoc 서명(`-`)을 쓸 때만 Hardened Runtime 을 **임시로** 비활성화하는 정상 동작. Build Settings 의 `ENABLE_HARDENED_RUNTIME=YES` 는 그대로 살아 있으며, **Developer ID 서명으로 아카이브할 때 자동으로 재활성**된다. Notarization 단계(M5)에서 검증되므로 스캐폴딩 통과 조건에서는 무시해도 된다.

→ note 와 warning 은 다르며, `grep -c "warning:"` 결과는 0 이므로 "0 warning" 통과 조건은 충족.

## 참고

- 커밋 `49f908b`
- Apple: Hardened Runtime 은 archive/release 빌드 + 정식 서명에서만 enforce
