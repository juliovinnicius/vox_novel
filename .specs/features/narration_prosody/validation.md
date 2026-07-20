# Prosódia da narração — Validação

**Data**: 2026-07-20  
**Spec**: `.specs/features/narration_prosody/spec.md`  
**Diff range**: `5b5abf3^..5b5abf3`  
**Verifier**: subagente independente (autor ≠ verificador)

---

## Conclusão das tarefas

Não existe `tasks.md` específico para esta alteração pequena. O diff solicitado
contém a especificação, a implementação no adaptador TTS e os testes focados.
Todos os critérios definidos na especificação estão implementados e
verificados.

## Critérios de aceitação ancorados na especificação

| Critério | Resultado definido pela spec | Evidência `arquivo:linha` + asserção | Resultado |
| --- | --- | --- | --- |
| NP-01 — quebra simples não pausa | A quebra é substituída por um espaço e o texto forma um único envio, sem delay | `test/features/narration/data/services/flutter_tts_narration_engine_test.dart:120` — `expect(facade.spokenValues, ['Ele caminhou até a porta, olhou para trás.'])`; `:123` — `expect(delays, isEmpty)` | ✅ PASS |
| NP-02 — vírgula permanece no trecho | A vírgula permanece no mesmo e único envio, sem pausa artificial | `test/features/narration/data/services/flutter_tts_narration_engine_test.dart:120` — a igualdade exata contém `porta, olhou`; `:123` — `expect(delays, isEmpty)` | ✅ PASS |
| NP-03 — frases e pausa curta | Ponto, interrogação e exclamação produzem quatro envios exatos e três pausas de 220 ms | `test/features/narration/data/services/flutter_tts_narration_engine_test.dart:137` — igualdade da lista `['Primeira.', 'Segunda?', 'Terceira!', 'Última.']`; `:143` — igualdade com três `Duration(milliseconds: 220)` | ✅ PASS |
| NP-04 — parágrafos e pausa longa | Dois parágrafos produzem dois envios exatos e uma pausa de 420 ms | `test/features/narration/data/services/flutter_tts_narration_engine_test.dart:162` — igualdade dos dois parágrafos; `:166` — `expect(delays, [const Duration(milliseconds: 420)])` | ✅ PASS |
| NP-05 — cancelamento durante pausa | Após `stop`, somente a primeira frase é enviada e não há trecho restante | `test/features/narration/data/services/flutter_tts_narration_engine_test.dart:184` — `expect(facade.spokenValues, ['Primeira.'])`; `:185` — `expect(facade.stopCalls, 1)` | ✅ PASS |

**Status**: ✅ 5/5 critérios cobertos com resultados exatos; nenhuma lacuna de
precisão da especificação.

## Sensor de discriminação

As mutações foram feitas apenas em
`/tmp/vox-narration-verify.NQ29gV`, uma cópia descartável. A árvore real não foi
mutada.

| Mutação | Local | Falha injetada | Resultado |
| --- | --- | --- | --- |
| M1 | `lib/features/narration/data/services/flutter_tts_narration_engine.dart:180` | Pausa de frase `220` → `221` ms | ✅ Morta pelo teste em `:143` |
| M2 | `lib/features/narration/data/services/flutter_tts_narration_engine.dart:179` | Pausa de parágrafo `420` → `220` ms | ✅ Morta pelo teste em `:166` |
| M3 | `lib/features/narration/data/services/flutter_tts_narration_engine.dart:126` | Remoção do guard de cancelamento antes do próximo envio | ✅ Morta pelo teste em `:184` |

Uma sondagem preliminar removeu o guard de geração em `:128` e sobreviveu
porque o guard em `:126`, executado logo após o delay, preserva exatamente o
mesmo comportamento. Por ser uma mutação equivalente, ela não é contabilizada
como falha comportamental nem como lacuna.

**Profundidade**: leve, três mutações comportamentais direcionadas  
**Resultado**: 3/3 mortas — PASS ✅

## Casos de borda

- [x] CRLF: entrada em `test/.../flutter_tts_narration_engine_test.dart:118`
  resulta no texto normalizado exato em `:120`.
- [x] CR: entrada em `:160` resulta em dois parágrafos exatos em `:162`.
- [x] Pontuação e Unicode: pontuação final é preservada exatamente em
  `:137-142`; emoji é preservado em `:162-165`; o teste preexistente em `:52`
  também preserva emoji e caracteres CJK.
- [x] Sem pausa após o último trecho: um envio tem zero delays em `:123`; quatro
  frases têm somente três delays em `:143-147`; dois parágrafos têm somente um
  delay em `:166`.

## Gate

- **Comandos**: `flutter analyze`; `flutter test`;
  `flutter test test/features/narration/data/services/flutter_tts_narration_engine_test.dart`
- **Análise**: PASS, nenhum problema.
- **Suíte completa**: 377 passaram, 0 falharam, 0 ignorados.
- **Teste focado**: 9 passaram, 0 falharam, 0 ignorados.
- **Contagem focada antes da feature**: 5 testes no commit pai.
- **Contagem focada depois da feature**: 9 testes.
- **Delta focado**: +4 testes; nenhuma exclusão ou enfraquecimento detectado.
- **Observação não bloqueante**: Flutter avisa que `flutter_tts` ainda não
  oferece suporte a Swift Package Manager em iOS/macOS.

## Qualidade de código

| Princípio | Status |
| --- | --- |
| Código mínimo e sem funcionalidade além da spec | ✅ |
| Alterações cirúrgicas dentro do diff solicitado | ✅ |
| Sem abstrações ou flexibilidade desnecessárias | ✅ |
| Compatível com o estilo e o contrato existentes | ✅ |
| Testes não rasos e ancorados nos resultados da spec | ✅ |
| Cobertura 1:1 dos critérios aplicáveis ao adaptador | ✅ |
| Todos os quatro testes novos são reivindicados por AC ou caso de borda | ✅ |
| Diretrizes documentadas | ✅ `.specs/STATE.md` (gate Flutter) e `coding-principles.md` |

O estado de trabalho possui alterações não relacionadas fora do diff; elas
foram preservadas e não influenciaram a avaliação de escopo.

## Rastreabilidade

| Requisito | Estado verificado |
| --- | --- |
| NP-01 | ✅ Verificado |
| NP-02 | ✅ Verificado |
| NP-03 | ✅ Verificado |
| NP-04 | ✅ Verificado |
| NP-05 | ✅ Verificado |

## Resumo

**Overall**: ✅ Ready  
**Spec-anchored check**: 5/5 ACs correspondem ao resultado definido  
**Sensor**: 3/3 mutações comportamentais mortas  
**Gate**: análise limpa; 377/377 testes da suíte e 9/9 testes focados passaram  
**Lacunas**: nenhuma
