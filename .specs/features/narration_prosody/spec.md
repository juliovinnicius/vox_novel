# Prosódia da narração

## Objetivo

Evitar pausas causadas por quebras visuais de linha do PDF e tornar as pausas
entre frases e parágrafos consistentes no TTS local.

## Critérios de aceitação

- **NP-01**: Dado um texto com quebra simples de linha, quando ele for narrado,
  então a quebra será substituída por um espaço e não criará uma pausa.
- **NP-02**: Dado um texto com vírgula, quando ele for narrado, então a vírgula
  permanecerá no mesmo trecho enviado ao TTS, sem pausa artificial.
- **NP-03**: Dado texto com ponto, interrogação ou exclamação seguido por outra
  frase, quando ele for narrado, então cada frase será enviada separadamente ao
  TTS, com pausa de 220 ms entre elas.
- **NP-04**: Dado texto com uma quebra de parágrafo, quando ele for narrado,
  então cada parágrafo será enviado separadamente ao TTS, com pausa de 420 ms
  entre eles.
- **NP-05**: Dada uma narração interrompida durante uma pausa artificial, quando
  `stop` for chamado, então nenhum trecho restante será enviado ao TTS.

## Casos de borda

- Quebras CRLF e CR são tratadas como quebras de linha.
- Pontuação e conteúdo Unicode permanecem no texto enviado ao TTS.
- Não existe pausa artificial depois do último trecho.

