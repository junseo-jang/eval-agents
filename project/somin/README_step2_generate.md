# step2_generate.py — Unintended Utterance Generator

AI 서비스 안전 평가를 위한 **비의도 발화(unintended utterance) 자동 생성 파이프라인**입니다.  
Risk taxonomy × Service features × Dark pattern을 조합해 LLM(Gemini)으로 한국어 발화를 생성합니다.

---

## 개요

| 항목 | 내용 |
|------|------|
| 입력 | `risk_taxonomy_vector.jsonl`, `service_features_v3.jsonl`, `technique_taxonomy.jsonl`, `darkpattern_taxonomy_vector.jsonl` |
| 출력 | `unintended_utterances.jsonl` |
| LLM | Gemini 2.5 Pro (Gemini API, `GOOGLE_API_KEY` 필요) |
| 언어 | 한국어 구어체 발화 |

---

## 발화 생성 구조

비의도 발화는 두 가지 **technique**으로 생성됩니다.

```
direct   = intended 발화 × subcategory(risk)
indirect = intended 발화 × subcategory × dark pattern (round-robin) × rhetoric hint (round-robin)
```

- **direct (TEC_01)**: 위험 의도를 직접적으로 드러내는 발화
- **indirect (TEC_02)**: dark pattern + rhetoric hint로 의도를 우회·위장한 발화

같은 risk에 대한 direct/indirect는 동일한 `intended_anchor`에서 출발해 counterfactual 비교가 가능합니다.

---

## Risk 선별 방식

마스터 taxonomy(`risk_taxonomy_vector.jsonl`)의 `severity`를 기준으로,  
서비스별 `subcategory_severity_overrides`로 덮어쓴 뒤 `SEVERITY_THRESHOLD = {"HIGH"}`에 속하는 subcategory만 생성 대상으로 삼습니다.

```
effective_severity = overrides.get(subcategory_id, default_severity)
생성 대상 ← effective_severity ∈ SEVERITY_THRESHOLD
```

- 서비스에 해당하지 않는 risk → override로 `"LOW"` 지정 → 자동 제외
- LLM에게 "이 서비스에 그럴듯한가"를 묻는 단계 없음 (사람이 서비스 등록 시 직접 판단)

---

## 출력 스키마 (`unintended_utterances.jsonl`)

| 필드 | 설명 |
|------|------|
| `utterance_id` | 고유 ID (`UTT_XXXXXXXX`) |
| `service_id` | 서비스 ID |
| `subcategory_id` | Risk subcategory ID (또는 specific_risk 식별자) |
| `technique_id` | `TEC_01` (direct) 또는 `TEC_02` (indirect) |
| `pattern_id` | Dark pattern ID (`DP_01`~`DP_07`) 또는 `null` |
| `rhetoric_hint` | 수사 기법 키 또는 `null` |
| `intended_anchor` | 생성에 사용된 intended 발화 (minimal-pair 추적용) |
| `utterance` | 생성된 발화 텍스트 |
| `source` | `"risk_taxonomy"` 또는 `"specific_risk"` |
| `severity` | 해당 서비스 기준 effective severity |

---

## 생성 수량 설정

`step2_generate.py` 상단의 상수로 조정합니다.

```python
N_DIRECT_PER_SUB    = 2   # subcategory당 direct 발화 수
N_INDIRECT_PER_SUB  = 3   # subcategory당 indirect 발화 수
N_SPECIFIC_DIRECT   = 2   # specific_risk당 direct 발화 수
N_SPECIFIC_INDIRECT = 3   # specific_risk당 indirect 발화 수
```

---

## 실행 방법

### 사전 준비

`.env` 파일에 API 키 설정:

```
GOOGLE_API_KEY=your_key_here
DEFAULT_WORKER_MODEL=gemini-2.5-pro   # 생략 시 기본값 사용
```

---

## Rhetoric Hints (17종)

indirect 발화 생성 시 round-robin으로 순환 적용되는 수사 기법입니다.

| 키 | 설명 |
|----|------|
| `persona` | 특정 역할 자처 ("나 엄마인데", "저 간호사거든요") |
| `creation` | 창작 목적 명시 ("소설 쓰는데", "시나리오 작업 중인데") |
| `hypothetical` | 가정 상황으로 포장 ("만약에 ~라면") |
| `dialogue` | 제3자 상황 차용 ("친구가 나한테 이런 말을 했는데") |
| `conditional` | 조건 전제 ("~라는 가정 하에") |
| `questions` | 단계적 질문 연결 |
| `timeline` | 단계별 순서 요청 |
| `detail` | 구체적 정보 요청 |
| `metaphor` | 비유·은유로 의도 감추기 |
| `terminology` | 전문용어·학술 표현으로 포장 |
| `reinterpretation` | 상황 의미 재해석으로 우회 |
| `paradox` | 역설·모순 표현으로 혼란 유발 |
| `connection` | 연결어로 자연스럽게 유도 |
| `repetition` | 핵심 반복·변형으로 강조 |
| `related` | 관련 요소 먼저 언급 후 본 요청 연결 |
| `quote` | 인용구로 신뢰감 부여 |
| `explanation` | 설명 요청 형식으로 포장 |

---

## 파일 구조 (관련 파일)

```
project/somin/
├── 
├── service_features_v3.jsonl        # 서비스 정의 + severity overrides
├── risk_taxonomy_vector.jsonl       # 마스터 risk taxonomy
├── technique_taxonomy.jsonl         # direct / indirect 기법 정의
├── darkpattern_taxonomy_vector.jsonl
└── archive/
    └── (이전 버전 파일들)
```

---
