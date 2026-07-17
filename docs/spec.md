# Especificação do Projeto — Novel Voice Reader

## 1. Visão Geral

O **Novel Voice Reader** é um aplicativo mobile para leitura e narração de novels em formato PDF.

O objetivo principal é permitir que o usuário importe seus próprios arquivos PDF, extraia o conteúdo textual e utilize um sintetizador de voz para ouvir a obra enquanto realiza outras atividades.

O aplicativo deve funcionar como uma combinação de:

- leitor de PDF;
- leitor de texto reformatado;
- sintetizador de voz;
- player de audiobook;
- biblioteca pessoal de novels.

A primeira versão será focada em **Android**, com arquitetura preparada para futura expansão para iOS, macOS, Windows e Web.

---

## 2. Problema

Leitores tradicionais de PDF apresentam limitações para consumo de novels:

- exigem atenção constante à tela;
- não oferecem narração contínua confiável;
- perdem o progresso exato da leitura em voz;
- não tratam corretamente capítulos e parágrafos;
- não funcionam adequadamente em segundo plano;
- narram cabeçalhos, rodapés e números de página;
- não lidam bem com nomes e termos chineses;
- não oferecem uma experiência semelhante a um audiobook.

O Novel Voice Reader deverá transformar um PDF em uma experiência de leitura e escuta contínua.

---

## 3. Objetivos

### 3.1 Objetivo principal

Permitir que o usuário importe uma novel em PDF e ouça seu conteúdo por meio de síntese de voz, com reprodução em segundo plano e salvamento automático de progresso.

### 3.2 Objetivos secundários

- Organizar novels e volumes em uma biblioteca local.
- Detectar capítulos automaticamente.
- Limpar elementos indesejados do PDF.
- Permitir leitura visual e por voz.
- Retomar a leitura no mesmo capítulo e parágrafo.
- Oferecer controles de reprodução semelhantes aos de um audiobook.
- Permitir ajuste de voz, velocidade, tom e pausas.
- Funcionar offline sempre que possível.
- Melhorar a pronúncia de nomes e termos chineses.
- Manter os arquivos do usuário armazenados localmente.

---

## 4. Público-Alvo

- Leitores de novels chinesas.
- Usuários que consomem webnovels, light novels e traduções em PDF.
- Pessoas que desejam ouvir histórias enquanto trabalham, dirigem, caminham ou realizam tarefas domésticas.
- Usuários que possuem grandes bibliotecas locais de PDFs.
- Pessoas que preferem sintetizador de voz em vez da leitura tradicional.

---

## 5. Escopo do Produto

## 5.1 Escopo do MVP

O MVP deverá incluir:

- importação de PDF;
- armazenamento local do arquivo;
- extração de texto de PDFs com texto selecionável;
- limpeza básica do conteúdo;
- detecção inicial de capítulos;
- divisão do texto em parágrafos;
- narração por sintetizador de voz local;
- reprodução contínua;
- execução em segundo plano;
- controles pela notificação e tela bloqueada;
- salvar capítulo, parágrafo e posição atual;
- retomar a leitura;
- controle de velocidade;
- seleção de voz;
- temporizador para dormir;
- biblioteca local;
- leitura visual do texto extraído;
- tema claro, escuro e sépia;
- exclusão de livros;
- atualização manual de título, autor e capa.

## 5.2 Fora do escopo do MVP

Não fazem parte da primeira versão:

- catálogo público de novels;
- distribuição de conteúdo protegido;
- download de novels;
- compartilhamento de PDFs;
- marketplace;
- rede social;
- tradução automática completa;
- OCR para PDFs escaneados;
- vozes neurais pagas;
- sincronização entre dispositivos;
- backup em nuvem;
- geração permanente de audiobooks;
- identificação avançada de personagens;
- resumos com inteligência artificial;
- publicação do conteúdo importado.

---

## 6. Premissas

- O usuário possui legalmente os arquivos importados.
- Os PDFs do MVP possuem texto selecionável.
- O aplicativo não será responsável pela distribuição do conteúdo.
- A narração inicial será feita com o mecanismo TTS instalado no dispositivo.
- O aplicativo deverá funcionar sem backend no MVP.
- Os dados da biblioteca serão armazenados localmente.
- O progresso deverá ser salvo após cada bloco narrado.
- O processamento de PDFs grandes deverá ocorrer de forma assíncrona.

---

## 7. Plataformas

### 7.1 Plataforma inicial

- Android.

### 7.2 Plataformas futuras

- iOS.
- macOS.
- Windows.
- Linux.
- Web.

### 7.3 Tecnologia principal

- Flutter.
- Dart.
- BLoC ou Cubit para gerenciamento de estado.
- Drift para persistência local.
- Armazenamento interno do dispositivo para PDFs e capas.

---

## 8. Experiência Principal

O fluxo principal deverá ser:

```text
Importar PDF
    ↓
Copiar arquivo para o armazenamento interno
    ↓
Extrair texto
    ↓
Limpar conteúdo
    ↓
Detectar capítulos
    ↓
Dividir capítulos em parágrafos
    ↓
Adicionar à biblioteca
    ↓
Abrir leitor
    ↓
Iniciar narração
    ↓
Salvar progresso continuamente
```

---

## 9. Personas

### 9.1 Leitor casual

Deseja ouvir uma novel durante tarefas domésticas sem precisar olhar para a tela.

### 9.2 Leitor frequente

Possui dezenas de novels e volumes em PDF e precisa organizar sua biblioteca.

### 9.3 Usuário avançado

Deseja controlar voz, velocidade, pronúncia, pausas e regras de limpeza.

---

## 10. Requisitos Funcionais

## RF-001 — Importar PDF

O usuário deverá conseguir selecionar um arquivo PDF no dispositivo.

### Critérios de aceite

- Aceitar apenas arquivos PDF.
- Validar se o arquivo existe e pode ser lido.
- Exibir mensagem de erro para arquivos inválidos.
- Copiar o arquivo para o diretório interno do aplicativo.
- Gerar um identificador único para o livro.

---

## RF-002 — Processar PDF

O sistema deverá extrair o texto do PDF importado.

### Critérios de aceite

- Processar PDFs com texto selecionável.
- Exibir progresso do processamento.
- Permitir cancelar o processamento.
- Detectar quando o PDF não possui texto extraível.
- Não bloquear a interface durante o processamento.
- Registrar erros de extração.

---

## RF-003 — Limpar texto extraído

O sistema deverá remover elementos indesejados do texto.

### Exemplos

- números de página;
- cabeçalhos repetidos;
- rodapés;
- URLs;
- espaços excessivos;
- quebras de linha incorretas;
- caracteres de controle;
- anúncios repetidos;
- marcas do grupo tradutor, quando configurado.

### Critérios de aceite

- Preservar parágrafos sempre que possível.
- Não remover conteúdo narrativo.
- Permitir reprocessamento futuro.
- Manter uma cópia do texto bruto.

---

## RF-004 — Detectar capítulos

O sistema deverá tentar identificar capítulos automaticamente.

### Padrões iniciais

```text
Capítulo 1
Capitulo 1
Chapter 1
CAPÍTULO 1
第1章
Volume 1
Prólogo
Epílogo
Extra
```

### Critérios de aceite

- Criar ao menos um capítulo quando nenhuma divisão for encontrada.
- Preservar a ordem do texto.
- Permitir renomear capítulos.
- Permitir unir ou dividir capítulos futuramente.

---

## RF-005 — Dividir conteúdo em blocos narráveis

Cada capítulo deverá ser dividido em unidades menores.

### Unidade recomendada

- parágrafo;
- ou bloco com limite máximo de caracteres.

### Critérios de aceite

- Nenhum bloco deverá ultrapassar o limite suportado pelo mecanismo TTS.
- Cada bloco deverá possuir ordem e identificador próprios.
- O sistema deverá conseguir avançar e voltar um bloco.
- O progresso deverá ser salvo por bloco.

---

## RF-006 — Adicionar livro à biblioteca

Após o processamento, o livro deverá aparecer na biblioteca.

### Informações mínimas

- título;
- nome do arquivo;
- capa;
- autor opcional;
- total de páginas;
- total de capítulos;
- data de importação;
- último acesso;
- progresso;
- status de processamento.

---

## RF-007 — Reproduzir narração

O usuário deverá conseguir iniciar a leitura em voz alta.

### Critérios de aceite

- Narrar o bloco atual.
- Avançar automaticamente ao próximo bloco.
- Avançar automaticamente ao próximo capítulo.
- Salvar progresso ao terminar cada bloco.
- Interromper ao chegar ao fim do livro.
- Permitir pausar e retomar.

---

## RF-008 — Executar em segundo plano

A narração deverá continuar com o aplicativo minimizado ou com a tela bloqueada.

### Critérios de aceite

- Manter reprodução em segundo plano.
- Exibir notificação de mídia.
- Exibir título do livro e capítulo atual.
- Permitir play, pause, anterior e próximo.
- Responder corretamente ao foco de áudio.
- Pausar durante ligações ou reprodução prioritária.
- Não perder progresso ao encerrar o aplicativo.

---

## RF-009 — Controlar reprodução

O player deverá oferecer:

- reproduzir;
- pausar;
- parar;
- bloco anterior;
- próximo bloco;
- capítulo anterior;
- próximo capítulo;
- voltar 15 segundos;
- avançar 30 segundos;
- alterar velocidade;
- selecionar voz;
- ativar temporizador.

---

## RF-010 — Salvar progresso

O sistema deverá salvar a posição exata da leitura.

### Dados mínimos

- livro;
- capítulo;
- bloco;
- índice de caractere opcional;
- data e hora;
- velocidade;
- voz selecionada.

### Critérios de aceite

- Salvar após cada bloco.
- Salvar ao pausar.
- Salvar ao fechar o aplicativo.
- Retomar no último bloco válido.
- Não retroceder o progresso por erro de sincronização local.

---

## RF-011 — Exibir texto narrado

O leitor em modo texto deverá destacar o bloco atual.

### Critérios de aceite

- Rolagem automática opcional.
- Destaque visual do parágrafo narrado.
- Toque em um parágrafo para iniciar daquele ponto.
- Ajuste de tamanho de fonte.
- Ajuste de espaçamento.
- Alteração de tema.
- Bloqueio opcional de tela ativa.

---

## RF-012 — Exibir PDF original

O usuário deverá conseguir visualizar o PDF original.

### Critérios de aceite

- Abrir página específica.
- Navegar pelas páginas.
- Exibir o progresso da página.
- Permitir alternar entre PDF e modo texto.
- Relacionar capítulo com página quando possível.

---

## RF-013 — Selecionar voz

O usuário deverá conseguir selecionar uma voz disponível no dispositivo.

### Configurações

- idioma;
- voz;
- velocidade;
- tom;
- volume;
- pausa entre parágrafos;
- pausa entre capítulos.

### Critérios de aceite

- Listar vozes disponíveis.
- Permitir testar uma voz.
- Salvar preferência global.
- Permitir configuração específica por livro.

---

## RF-014 — Temporizador para dormir

O usuário poderá programar a interrupção da reprodução.

### Opções iniciais

- 10 minutos;
- 20 minutos;
- 30 minutos;
- 45 minutos;
- 60 minutos;
- final do capítulo.

### Critérios de aceite

- Exibir tempo restante.
- Permitir cancelar.
- Salvar progresso antes de interromper.
- Aplicar redução gradual de volume opcional futuramente.

---

## RF-015 — Gerenciar pronúncias

O usuário poderá configurar substituições para melhorar a fala.

### Exemplo

```text
Texto original: Nie Li
Texto enviado ao TTS: Niê Li
```

### Critérios de aceite

- Criar substituição.
- Editar substituição.
- Excluir substituição.
- Aplicar substituição antes da narração.
- Permitir regras globais ou específicas por livro.
- Preservar o texto original na tela.

---

## RF-016 — Gerenciar biblioteca

O usuário deverá conseguir:

- pesquisar livros;
- ordenar livros;
- editar metadados;
- remover livros;
- reprocessar PDFs;
- marcar como concluído;
- reiniciar progresso;
- adicionar capa;
- agrupar volumes.

---

## RF-017 — Tratar erros de processamento

O sistema deverá informar quando:

- o PDF estiver protegido;
- o arquivo estiver corrompido;
- não houver texto selecionável;
- a extração falhar;
- não houver mecanismo TTS;
- a voz selecionada não estiver instalada;
- o armazenamento estiver cheio;
- o arquivo original tiver sido removido antes da cópia.

---

## 11. Requisitos Não Funcionais

## RNF-001 — Offline

As principais funções deverão funcionar sem internet:

- biblioteca;
- leitura;
- síntese local;
- progresso;
- configurações;
- gerenciamento de arquivos.

---

## RNF-002 — Desempenho

- A interface não poderá bloquear durante processamento.
- A abertura da biblioteca deverá ocorrer em até dois segundos em condições normais.
- A troca de bloco deverá ser imperceptível ou inferior a 500 ms.
- PDFs grandes deverão ser processados incrementalmente.
- O aplicativo deverá suportar livros com milhares de páginas.

---

## RNF-003 — Confiabilidade

- O progresso não poderá ser perdido em encerramentos inesperados.
- Operações de banco deverão ser transacionais quando necessário.
- O livro não deverá ser marcado como processado antes da conclusão.
- Processamentos interrompidos deverão ser retomáveis ou reiniciáveis.

---

## RNF-004 — Privacidade

- Os PDFs deverão permanecer no dispositivo.
- Nenhum texto deverá ser enviado para serviços externos no MVP.
- O usuário deverá ser informado antes de qualquer futura integração em nuvem.
- Logs não deverão conter o conteúdo completo da novel.

---

## RNF-005 — Acessibilidade

- Botões deverão possuir rótulos acessíveis.
- Controles deverão ter tamanho adequado para toque.
- O aplicativo deverá suportar leitores de tela.
- O contraste deverá atender padrões mínimos.
- O player deverá ser operável sem navegar por múltiplas telas.

---

## RNF-006 — Compatibilidade

- Android 9 ou superior no MVP.
- Suporte a diferentes mecanismos TTS instalados.
- Suporte a PDFs em português, inglês e chinês simplificado.
- Layout responsivo para celular e tablet.

---

## RNF-007 — Manutenibilidade

- Arquitetura por features.
- Separação entre domínio, dados e apresentação.
- Cobertura de testes para regras críticas.
- Interfaces para serviços externos.
- Dependências isoladas por adapters.

---

## 12. Arquitetura

## 12.1 Estilo arquitetural

Arquitetura baseada em features com separação inspirada em Clean Architecture.

```text
lib/
├── app/
│   ├── app.dart
│   ├── router/
│   ├── theme/
│   └── dependency_injection/
│
├── core/
│   ├── errors/
│   ├── result/
│   ├── database/
│   ├── file_system/
│   ├── logging/
│   └── utils/
│
├── features/
│   ├── library/
│   ├── import_book/
│   ├── pdf_processing/
│   ├── reader/
│   ├── narration/
│   ├── playback/
│   ├── pronunciation/
│   └── settings/
│
└── shared/
    ├── widgets/
    ├── extensions/
    └── models/
```

---

## 12.2 Camadas por feature

```text
feature/
├── data/
│   ├── datasources/
│   ├── repositories/
│   ├── models/
│   └── mappers/
│
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
│
└── presentation/
    ├── bloc/
    ├── pages/
    └── widgets/
```

---

## 12.3 Componentes principais

### Library Service

Responsável por:

- cadastrar livros;
- consultar livros;
- editar metadados;
- remover livros;
- agrupar volumes.

### File Storage Service

Responsável por:

- copiar PDFs;
- armazenar capas;
- calcular hash;
- controlar diretórios;
- remover arquivos.

### PDF Extraction Service

Responsável por:

- extrair texto;
- extrair metadados;
- obter total de páginas;
- detectar PDF sem texto.

### Text Cleaning Pipeline

Responsável por:

- normalização;
- remoção de cabeçalhos;
- remoção de rodapés;
- correção de quebras;
- aplicação de regras customizadas.

### Chapter Detection Service

Responsável por:

- identificar títulos;
- criar capítulos;
- preservar posição no texto;
- relacionar capítulos com páginas.

### Narration Queue

Responsável por:

- manter bloco atual;
- preparar próximos blocos;
- aplicar regras de pronúncia;
- enviar texto ao TTS;
- receber eventos de conclusão.

### Playback Service

Responsável por:

- reprodução em segundo plano;
- controles de mídia;
- foco de áudio;
- estado do player;
- integração com notificação.

### Progress Service

Responsável por:

- salvar progresso;
- restaurar progresso;
- registrar sessões;
- calcular porcentagem concluída.

---

## 13. Modelo de Dados

## 13.1 Book

```text
id
title
author
description
coverPath
originalFileName
storedFilePath
fileHash
pageCount
chapterCount
language
status
processingProgress
createdAt
updatedAt
lastReadAt
completedAt
```

### Status possíveis

```text
importing
processing
ready
failed
unsupported
```

---

## 13.2 Chapter

```text
id
bookId
title
chapterNumber
sortOrder
startPage
endPage
rawText
cleanText
createdAt
updatedAt
```

---

## 13.3 NarrationBlock

```text
id
chapterId
sortOrder
originalText
normalizedText
characterCount
estimatedDuration
startPage
endPage
```

---

## 13.4 ReadingProgress

```text
id
bookId
chapterId
blockId
blockIndex
characterOffset
pageNumber
progressPercentage
voiceId
speechRate
updatedAt
```

---

## 13.5 Bookmark

```text
id
bookId
chapterId
blockId
pageNumber
title
note
createdAt
```

---

## 13.6 PronunciationRule

```text
id
bookId
sourceText
replacementText
isGlobal
isCaseSensitive
isEnabled
createdAt
updatedAt
```

---

## 13.7 ReaderSettings

```text
id
theme
fontFamily
fontSize
lineHeight
paragraphSpacing
textAlignment
autoScroll
keepScreenOn
```

---

## 13.8 NarrationSettings

```text
id
voiceId
language
speechRate
pitch
volume
paragraphPauseMs
chapterPauseMs
skipUrls
skipPageNumbers
```

---

## 13.9 ReadingSession

```text
id
bookId
startedAt
endedAt
startBlockId
endBlockId
listenedSeconds
blocksCompleted
```

---

## 14. Máquina de Estados do Player

```text
idle
loading
ready
playing
paused
stopping
completed
error
```

### Transições

```text
idle -> loading
loading -> ready
loading -> error
ready -> playing
playing -> paused
paused -> playing
playing -> stopping
stopping -> ready
playing -> completed
completed -> ready
qualquer estado -> error
```

### Regras

- Apenas um livro poderá ser narrado por vez.
- O bloco atual deverá ser persistido antes de trocar de livro.
- Uma troca de voz deverá reiniciar somente o bloco atual.
- Uma troca de velocidade não deverá alterar o progresso.
- Eventos duplicados de conclusão deverão ser ignorados.

---

## 15. Pipeline de Processamento

## 15.1 Etapas

```text
1. Validar arquivo
2. Calcular hash
3. Verificar duplicidade
4. Copiar arquivo
5. Ler metadados
6. Extrair texto por página
7. Salvar texto bruto
8. Normalizar caracteres
9. Remover elementos repetidos
10. Detectar capítulos
11. Criar blocos de narração
12. Calcular estatísticas
13. Gerar capa
14. Marcar livro como pronto
```

## 15.2 Idempotência

O processamento deverá ser idempotente.

Executar novamente o processamento do mesmo livro não deverá:

- duplicar capítulos;
- duplicar blocos;
- perder progresso sem autorização;
- criar múltiplas cópias do PDF;
- alterar regras personalizadas.

---

## 16. Limpeza de Texto

## 16.1 Regras básicas

- converter múltiplos espaços em um;
- remover linhas vazias repetidas;
- unir palavras quebradas por mudança de página;
- remover caracteres invisíveis;
- normalizar aspas;
- normalizar travessões;
- remover números isolados identificados como página;
- remover cabeçalhos repetidos;
- remover rodapés repetidos;
- preservar títulos.

## 16.2 Estratégia para cabeçalhos e rodapés

O sistema poderá identificar linhas que:

- aparecem em grande porcentagem das páginas;
- ocupam a primeira ou última linha;
- possuem pequenas variações numéricas;
- repetem o título do livro ou site.

## 16.3 Configurações futuras

O usuário poderá definir:

- ignorar linhas contendo determinado texto;
- substituir expressão;
- remover conteúdo entre padrões;
- manter conteúdo original;
- reprocessar apenas a limpeza.

---

## 17. Síntese de Voz

## 17.1 Estratégia do MVP

Utilizar o mecanismo TTS local do dispositivo.

## 17.2 Entrada do TTS

Antes de enviar o texto:

```text
Texto original
    ↓
Normalização
    ↓
Regras de pronúncia
    ↓
Remoção de elementos ignorados
    ↓
Inserção de pausas
    ↓
Texto enviado ao TTS
```

## 17.3 Fila de narração

A fila deverá manter:

- bloco atual;
- próximo bloco;
- bloco posterior;
- capítulo seguinte;
- configuração atual.

## 17.4 Recuperação de falhas

Se o TTS falhar:

- tentar novamente uma vez;
- reinicializar o engine;
- manter o mesmo bloco;
- registrar o erro;
- informar o usuário;
- permitir trocar a voz.

---

## 18. Reprodução em Segundo Plano

## 18.1 Requisitos

- serviço de reprodução persistente;
- notificação de mídia;
- integração com tela bloqueada;
- headset e Bluetooth;
- foco de áudio;
- interrupções por chamada;
- controles externos;
- restauração após o sistema encerrar o app.

## 18.2 Ações da notificação

- anterior;
- voltar;
- play ou pause;
- avançar;
- próximo;
- parar.

## 18.3 Metadados exibidos

- título da novel;
- capítulo;
- progresso;
- capa;
- velocidade.

---

## 19. Telas

## 19.1 Splash

Responsável por:

- inicializar banco;
- verificar processamento pendente;
- restaurar player;
- validar TTS.

---

## 19.2 Biblioteca

Elementos:

- lista ou grade;
- campo de busca;
- filtro;
- ordenação;
- botão importar;
- progresso por livro;
- botão continuar ouvindo;
- mini player.

---

## 19.3 Importação

Etapas visuais:

```text
Selecionando arquivo
Copiando
Extraindo texto
Limpando
Detectando capítulos
Preparando narração
Concluído
```

---

## 19.4 Detalhes do livro

Elementos:

- capa;
- título;
- autor;
- progresso;
- continuar;
- iniciar do começo;
- lista de capítulos;
- editar;
- reprocessar;
- excluir.

---

## 19.5 Leitor em modo texto

Elementos:

- título do capítulo;
- conteúdo;
- destaque do parágrafo;
- controles;
- configuração de fonte;
- seleção de voz;
- velocidade;
- temporizador.

---

## 19.6 Leitor em modo PDF

Elementos:

- página atual;
- zoom;
- navegação;
- marcador;
- iniciar narração;
- alternar para modo texto.

---

## 19.7 Player expandido

Elementos:

- capa;
- título;
- capítulo;
- bloco atual;
- progresso;
- controles;
- velocidade;
- voz;
- temporizador;
- lista de capítulos.

---

## 19.8 Pronúncias

Elementos:

- busca;
- regras globais;
- regras do livro;
- adicionar;
- editar;
- testar pronúncia.

---

## 19.9 Configurações

Seções:

- aparência;
- leitor;
- narração;
- armazenamento;
- processamento;
- privacidade;
- diagnóstico.

---

## 20. Casos de Uso

## UC-001 — Importar uma novel

### Ator

Usuário.

### Fluxo principal

1. O usuário toca em importar.
2. Seleciona um PDF.
3. O sistema valida o arquivo.
4. O sistema copia o PDF.
5. O sistema processa o conteúdo.
6. O sistema detecta capítulos.
7. O livro é adicionado à biblioteca.
8. O usuário abre o livro.

### Exceções

- arquivo inválido;
- arquivo duplicado;
- PDF protegido;
- PDF sem texto;
- armazenamento insuficiente.

---

## UC-002 — Ouvir uma novel

1. O usuário abre um livro.
2. Seleciona um capítulo.
3. Toca em reproduzir.
4. O sistema carrega o bloco.
5. O TTS inicia a narração.
6. O sistema avança pelos blocos.
7. O progresso é salvo.
8. A reprodução continua em segundo plano.

---

## UC-003 — Retomar leitura

1. O usuário abre o aplicativo.
2. O sistema localiza o último livro.
3. Exibe continuar ouvindo.
4. O usuário toca no botão.
5. A narração retoma no último bloco salvo.

---

## UC-004 — Corrigir pronúncia

1. O usuário identifica um nome pronunciado incorretamente.
2. Abre as opções do trecho.
3. Seleciona corrigir pronúncia.
4. Informa a substituição fonética.
5. Testa a voz.
6. Salva a regra.
7. O sistema reaplica a regra nas próximas leituras.

---

## 21. Regras de Negócio

## RN-001

Um arquivo com o mesmo hash não deverá ser importado novamente sem confirmação.

## RN-002

O progresso deverá ser salvo antes de:

- trocar de livro;
- trocar de capítulo;
- encerrar o player;
- interromper pelo temporizador;
- fechar o aplicativo.

## RN-003

O texto original nunca deverá ser alterado pelas regras de pronúncia.

## RN-004

O livro somente poderá receber status `ready` após a criação dos capítulos e blocos.

## RN-005

Se nenhum capítulo for detectado, o sistema deverá criar um capítulo único.

## RN-006

Se uma voz deixar de existir, o sistema deverá selecionar uma voz compatível.

## RN-007

A exclusão de um livro deverá remover:

- PDF;
- capa;
- texto bruto;
- capítulos;
- blocos;
- progresso;
- bookmarks;
- configurações específicas.

## RN-008

Configurações globais poderão ser sobrescritas por configurações específicas do livro.

## RN-009

O player deverá impedir duas narrações simultâneas.

## RN-010

O aplicativo deverá avisar o usuário antes de reprocessar um livro caso existam edições manuais.

---

## 22. Segurança e Direitos Autorais

O aplicativo será um leitor de arquivos pessoais.

O produto não deverá:

- distribuir novels;
- hospedar catálogo pirata;
- oferecer links não autorizados;
- compartilhar PDFs importados;
- remover mecanismos de proteção;
- quebrar criptografia de arquivos.

O usuário será responsável pelos arquivos importados.

Uma mensagem deverá informar que o aplicativo é destinado à leitura de conteúdo adquirido legalmente, autorizado ou em domínio público.

---

## 23. Logs e Diagnóstico

Os logs poderão conter:

- etapa de processamento;
- duração;
- quantidade de páginas;
- quantidade de capítulos;
- quantidade de blocos;
- identificador interno;
- código de erro;
- modelo do dispositivo;
- versão do sistema.

Os logs não deverão conter:

- texto completo da novel;
- capítulos completos;
- dados pessoais desnecessários;
- conteúdo do PDF.

---

## 24. Testes

## 24.1 Testes unitários

Cobrir:

- limpeza de texto;
- detecção de capítulos;
- divisão em blocos;
- regras de pronúncia;
- cálculo de progresso;
- transições do player;
- validações de arquivos.

## 24.2 Testes de integração

Cobrir:

- importação completa;
- persistência;
- restauração de progresso;
- fila TTS;
- reprocessamento;
- exclusão.

## 24.3 Testes de widget

Cobrir:

- biblioteca;
- player;
- leitor;
- tela de processamento;
- configurações.

## 24.4 Testes end-to-end

Cenários:

- importar e ouvir;
- pausar e retomar;
- bloquear a tela;
- usar controle da notificação;
- encerrar e abrir novamente;
- trocar de voz;
- finalizar capítulo;
- temporizador.

---

## 25. Métricas Locais

O MVP poderá registrar localmente:

- tempo total ouvido;
- livros concluídos;
- capítulos concluídos;
- velocidade média;
- sessões por livro;
- sequência de dias;
- tempo restante estimado.

Nenhuma telemetria externa será obrigatória no MVP.

---

## 26. Roadmap

## Milestone 0 — Fundação

- criar projeto Flutter;
- configurar arquitetura;
- configurar BLoC;
- configurar Drift;
- configurar injeção de dependências;
- configurar testes;
- configurar lint;
- configurar pipeline de CI.

## Milestone 1 — Biblioteca e importação

- selecionar PDF;
- copiar arquivo;
- cadastrar livro;
- listar biblioteca;
- editar metadados;
- excluir livro;
- detectar duplicidade.

## Milestone 2 — Processamento de texto

- extrair texto;
- salvar texto bruto;
- limpar conteúdo;
- detectar capítulos;
- gerar blocos;
- exibir progresso.

## Milestone 3 — Leitor visual

- modo texto;
- modo PDF;
- capítulos;
- navegação;
- temas;
- configurações de fonte;
- destaque de parágrafo.

## Milestone 4 — Narração

- inicializar TTS;
- selecionar voz;
- narrar blocos;
- fila de narração;
- play e pause;
- avanço automático;
- velocidade;
- persistência de progresso.

## Milestone 5 — Segundo plano

- serviço de mídia;
- notificação;
- tela bloqueada;
- foco de áudio;
- Bluetooth;
- restauração do player.

## Milestone 6 — Experiência avançada

- temporizador;
- regras de pronúncia;
- bookmarks;
- estatísticas;
- agrupamento por volumes;
- reprocessamento configurável.

## Milestone 7 — Pós-MVP

- OCR;
- sincronização;
- backup;
- iOS;
- vozes neurais;
- geração de áudio;
- tradução;
- glossário;
- resumos;
- recursos com IA.

---

## 27. Backlog Futuro

- importar EPUB;
- importar TXT;
- importar HTML;
- importar DOCX;
- OCR offline;
- tradução por trecho;
- detecção de personagens;
- glossário sem spoilers;
- resumo do capítulo;
- diferentes vozes para diálogos;
- compartilhamento de configurações de pronúncia;
- exportação de audiobook;
- sincronização entre dispositivos;
- Android Auto;
- CarPlay;
- widget de reprodução;
- comandos por voz;
- integração com smartwatch.

---

## 28. Riscos

## Risco 1 — Extração inconsistente

PDFs podem armazenar texto de maneira desordenada.

### Mitigação

- pipeline modular;
- texto bruto preservado;
- regras configuráveis;
- suporte futuro a OCR.

## Risco 2 — Variação entre mecanismos TTS

A qualidade e os eventos podem variar por fabricante.

### Mitigação

- adapter de TTS;
- testes em diferentes dispositivos;
- fila independente do engine;
- recuperação de falhas.

## Risco 3 — Restrições de segundo plano

O sistema operacional pode encerrar processos.

### Mitigação

- serviço de mídia apropriado;
- persistência frequente;
- restauração de estado;
- instruções de otimização de bateria.

## Risco 4 — PDFs muito grandes

Arquivos extensos podem consumir muita memória.

### Mitigação

- processamento por páginas;
- operações em isolate;
- escrita incremental;
- paginação no banco;
- carregamento sob demanda.

## Risco 5 — Pronúncia de nomes chineses

Vozes portuguesas podem pronunciar nomes incorretamente.

### Mitigação

- dicionário de pronúncia;
- substituições fonéticas;
- teste de voz;
- regras compartilháveis futuramente.

---

## 29. Critérios de Sucesso do MVP

O MVP será considerado funcional quando o usuário conseguir:

1. importar um PDF com texto selecionável;
2. visualizar o livro na biblioteca;
3. abrir o texto extraído;
4. iniciar a narração;
5. bloquear a tela e continuar ouvindo;
6. controlar a reprodução pela notificação;
7. alterar velocidade e voz;
8. fechar o aplicativo;
9. abrir novamente;
10. continuar exatamente do último bloco salvo.

---

## 30. Definição de Pronto

Uma funcionalidade será considerada pronta quando:

- os critérios de aceite forem atendidos;
- houver tratamento de erro;
- houver testes aplicáveis;
- não houver bloqueio da interface;
- os dados forem persistidos corretamente;
- a funcionalidade respeitar acessibilidade;
- o código estiver revisado;
- a documentação estiver atualizada;
- não houver regressões conhecidas.

---

## 31. Decisões Iniciais Recomendadas

- Começar pelo Android.
- Utilizar Flutter.
- Utilizar BLoC/Cubit.
- Utilizar Drift.
- Utilizar TTS local.
- Não criar backend no MVP.
- Processar somente PDFs com texto selecionável.
- Preservar o texto bruto.
- Narrar por blocos curtos.
- Salvar progresso após cada bloco.
- Implementar segundo plano como serviço de mídia.
- Deixar OCR e vozes de IA para uma segunda fase.

---

## 32. Nome Provisório

Sugestões:

- Novel Voice Reader;
- NovelFlow;
- NovelSpeak;
- VoiceNovel;
- NovelCast;
- ReadFlow;
- StoryVoice;
- Xianxia Reader;
- Dao Reader;
- Novel Echo.

O nome definitivo deverá ser validado posteriormente quanto à disponibilidade de domínio, loja e marca.