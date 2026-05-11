**🌐 Languages:** [日本語](README.md) · [English](README.en.md) · **한국어**

# claude-code-statusline

[Claude Code](https://docs.claude.com/en/docs/claude-code) 용 커스텀 statusline. 다음 정보를 한 줄로 표시합니다:

- 현재 사용자 · 작업 디렉토리 · git 브랜치 (PS1 스타일)
- Claude 버전 · 모델 이름
- 토큰 사용량 (`12.8k` 형식으로 포맷)
- 컨텍스트 윈도우 사용률 (색상 코딩: 🟢 ≤60% / 🟡 61–80% / 🔴 >80%)
- 세션의 코드 변경량 (`+추가행 / -삭제행`)

## 미리보기

```
myuser:/home/myuser/proj (main) | Claude 2.1.140 | Claude Opus 4.7 | 🪙 12.8k toks | 🧠 42.5% | ✏️ +127/-43
```

## 필요 사항

- `jq` — JSON 파서 (statusline은 stdin에서 JSON을 읽음)
- `awk` — 숫자 포매팅과 색상 임계값 처리용
- Bash 4+ (WSL 및 Git Bash on Windows에서 동작. 네이티브 cmd/PowerShell은 **미지원**)

```bash
# Ubuntu/WSL
sudo apt install -y jq

# macOS
brew install jq
```

---

## 설치 방법

3가지 설치 경로를 지원합니다. 대부분의 경우 **방식 B** (curl 원라이너)가 권장됩니다.

### 방식 A — 파일 수동 복사

설치 전에 모든 줄을 직접 확인하고 싶은 분 대상.

1. 스크립트 다운로드:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/slo-oww/claude-code-statusline/main/statusline.sh \
     -o ~/.claude/statusline.sh
   chmod +x ~/.claude/statusline.sh
   ```

2. `~/.claude/settings.json`에 다음 블록 추가 (기존 설정이 있다면 병합):

   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "bash $HOME/.claude/statusline.sh"
     }
   }
   ```

3. Claude Code 재시작 또는 새 세션 시작.

### 방식 B / C-1 — curl 원라이너 (권장)

한 줄로 완료. 스크립트 자동 설치, settings의 `statusLine` 병합 (기존 파일 백업), 출력 검증까지 자동.

```bash
curl -fsSL https://raw.githubusercontent.com/slo-oww/claude-code-statusline/main/install.sh | bash
```

이 인스톨러가 하는 일:

- `~/.claude/statusline.sh` 작성 (실행 권한 포함)
- `~/.claude/settings.json`의 `statusLine` 키 병합 — **다른 키는 보존**
- 기존 `settings.json`은 `settings.json.bak.YYYYMMDDHHMMSS` 형식으로 백업
- 기존 `settings.json`이 유효하지 않은 JSON이면 안전하게 중단
- 새 세션을 열기 전에 동작 확인 출력 표시

환경 변수로 설치 위치 커스터마이징:

```bash
CLAUDE_DIR=$HOME/my-claude curl -fsSL https://raw.githubusercontent.com/slo-oww/claude-code-statusline/main/install.sh | bash
```

### 방식 C-2 — 마켓플레이스 경유 플러그인

스크립트 업데이트를 `/plugin update`로 자동 추종하고 싶을 때 사용. **단, `settings.json`은 수동 편집이 필요**합니다 — Claude Code의 플러그인 사양상 메인 `statusLine`은 선언할 수 없고, `subagentStatusLine`만 플러그인 작성자에게 노출되기 때문입니다.

1. Claude Code 세션 내에서 마켓플레이스 추가:

   ```text
   /plugin marketplace add slo-oww/claude-code-statusline
   ```

2. 플러그인 설치:

   ```text
   /plugin install statusline@slo-oww-claude-code-statusline
   ```

3. Claude Code가 플러그인을 배치한 경로 확인:

   ```bash
   find ~/.claude/plugins -name 'statusline.sh' 2>/dev/null
   ```

4. `~/.claude/settings.json`에 절대 경로 추가:

   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "bash /3단계에서 확인한 절대경로"
     }
   }
   ```

5. Claude Code 재시작.

이후 업데이트: `/plugin update`로 스크립트가 자동 갱신되며, `settings.json` 재편집은 불필요합니다.

---

## 색상 코딩

컨텍스트 사용률에 따라 색상이 바뀝니다:

| 범위   | 색상    | 의미                                |
|--------|---------|------------------------------------|
| ≤ 60%  | 🟢 녹색 | 여유 있음                          |
| 61–80% | 🟡 노랑 | 주의, `/compact` 고려              |
| > 80%  | 🔴 빨강 | 높음, compact 또는 세션 종료 권장  |

임계값은 `statusline.sh` 내 (`awk -v p="$context_pct"` 블록)에 있으며 취향에 맞게 조정 가능합니다.

## 사용하는 JSON 필드

스크립트는 Claude Code가 stdin에 전달하는 JSON에서 다음 필드를 읽습니다 (v2.1.132+ 스키마):

- `.cwd`
- `.model.display_name`
- `.version`
- `.context_window.used_percentage`
- `.context_window.current_usage.input_tokens`
- `.context_window.current_usage.output_tokens`
- `.cost.total_lines_added`
- `.cost.total_lines_removed`

모든 필드는 jq의 `// 0` 또는 `// "default"`로 기본값이 설정되어 있어, Claude Code의 스키마가 변경되어도 안전하게 동작합니다.

## 제거 방법

```bash
# 스크립트 제거
rm ~/.claude/statusline.sh

# settings.json에서 statusLine 키만 제거 (다른 설정 보존)
tmp=$(mktemp) && jq 'del(.statusLine)' ~/.claude/settings.json > "$tmp" && mv "$tmp" ~/.claude/settings.json

# 플러그인 마켓플레이스로 설치한 경우
# /plugin uninstall statusline@slo-oww-claude-code-statusline
# /plugin marketplace remove slo-oww/claude-code-statusline
```

## 트러블슈팅

| 증상 | 원인 / 해결 |
|------|------------|
| Statusline이 비어 있음 | `jq` 미설치 → `apt install jq` 또는 `brew install jq` |
| 컨텍스트 %가 `0%` 표시 | 세션에서 아직 API 호출이 없음 (`current_usage`는 첫 응답까지 null) |
| 색상이 표시되지 않음 | 터미널이 ANSI 이스케이프 미지원 — `TERM` 환경 변수 확인 |
| settings.json에서 `~`가 확장되지 않음 | `~` 대신 `$HOME` 사용 — 둘 다 셸에서 동작하지만 `$HOME`이 더 확실 |
| `is not valid JSON` (인스톨러) | `~/.claude/settings.json`에 구문 오류 — 수동 수정 후 재실행 |

## 기여하기

Statusline 스크립트는 3가지 설치 방식을 지원하기 위해 3곳에 복제되어 있습니다. **스크립트 동작을 변경할 때는 3곳 모두 갱신**하여 함께 커밋해 주세요:

- `statusline.sh` (리포지토리 루트, 방식 A 직접 다운로드용)
- `install.sh` (heredoc 본문, 방식 B curl 원라이너용)
- `plugins/statusline/bin/statusline.sh` (방식 C-2 플러그인용)

간단한 동기화 확인:

```bash
diff statusline.sh plugins/statusline/bin/statusline.sh && echo "✅ in sync"
```

PR 환영합니다.

## 라이선스

MIT — [LICENSE](LICENSE) 참조.
