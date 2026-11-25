# Decisões de projeto

## 1. foldl ou foldr no `linhaDoTime`

```haskell
linhaDoTime ps t = foldl somarPartida (linhaVazia t) (filter (participou t) ps)
```

Usamos **foldl**, pelos mesmos motivos do extrato bancário da aula 11:

- `foldl f z [p1, p2, p3] = f (f (f z p1) p2) p3`: a linha começa vazia e incorpora as
  partidas **na ordem em que aconteceram** (rodada 1, depois 2, ...). É exatamente o que
  se faz à mão ao montar uma tabela.
- O acumulado vem primeiro em `somarPartida :: Linha -> Partida -> Linha`, o formato que
  o `foldl` espera (igual ao `aplicar saldo t` da aula 11).
- Com `foldr`, a função teria a ordem `Partida -> Linha -> Linha` e as partidas seriam
  incorporadas da última para a primeira. **Para este problema o resultado final seria o
  mesmo**, porque somar jogos, vitórias e gols é comutativo. A escolha pelo `foldl` é de
  clareza: ele lê a lista na ordem do campeonato. Se um dia a tabela guardar algo que
  depende da ordem (por exemplo, a sequência dos últimos 5 resultados), o `foldr` daria
  a ordem invertida.
- Desempenho: com milhares de partidas, o `foldl` preguiçoso acumula cálculos pendentes
  (aula 12). Nesse caso o certo é o `foldl'` de `Data.List`, que força o acumulador a cada
  passo. Com 15 partidas não faz diferença, e o `foldl` do Prelude evita um import.

Já o `separar` usa **foldr**, e de propósito: ele monta uma **lista** (os campos), e o
`foldr` constrói listas na ordem certa com `:`, lendo o texto da direita para a esquerda.
Com `foldl`, cada caractere teria de ir para o fim do campo (`++ [c]`), que é mais lento e
mais difícil de ler. É a regra prática da aula 12: `foldl` para acumular um valor,
`foldr` quando o resultado é uma lista.

## 2. Modelo da `Linha`

```haskell
data Linha = Linha
  { time, jogos, vitorias, empates, derrotas, golsPro, golsContra }
```

- A `Linha` guarda **só os dados contados** a partir das partidas. **Pontos, saldo e
  aproveitamento não são campos**: são funções (`pontosLinha`, `saldo`,
  `aproveitamento`) calculadas a partir dos campos.
- Motivo: se `pontos` fosse um campo, seria possível criar uma `Linha` com
  `vitorias = 3` e `pontos = 2`, um estado ilegal (aula 13: "contar habitantes").
  Calculando, os pontos estão sempre certos por construção.
- Outro ganho: se a regra mudar (vitória valendo 2 pontos, como antigamente), basta mudar
  `pontos Vitoria = 3`. O `pontosLinha` e o `aproveitamento` usam `pontos` e acompanham
  a mudança sozinhos.
- `jogos` é um campo, embora seja `vitorias + empates + derrotas`. Mantivemos porque o
  enunciado pede a coluna J e porque o `aproveitamento` depende dela; os testes conferem
  que os valores batem.
- Records em vez de tuplas: cada campo tem nome e vira uma função de acesso
  (`golsPro l`), e a atualização no fold é `l { jogos = jogos l + 1, ... }`, sem
  depender da posição.
- `Partida` segue a ordem em que se lê um placar (`rodada mandante golsMandante
  golsVisitante visitante` = "Coritiba 3 x 0 Athletico"), e o formato de texto da Camada 3
  usa a mesma ordem.

## 3. Outras decisões

- **Desempate** (`criterios`): segue o Brasileirão, como pede o enunciado ("critérios
  do campeonato escolhido"): pontos, vitórias, saldo e gols pró. Os critérios seguintes do
  regulamento (confronto direto, cartões e sorteio) foram trocados pelo nome do time. Cada
  critério é um `comparing`, combinados com `<>`, que só consulta o próximo critério
  quando o anterior empata. `Down` inverte a ordem (maior primeiro). O nome no fim
  garante que a tabela sai sempre na mesma ordem, mesmo com empate total.
- **Funções parciais evitadas**: `maiorGoleada` e `mediaGols` devolvem `Maybe`, porque
  `maximumBy` e a divisão por `length` quebram com a lista vazia. `aproveitamento` devolve
  0 para quem não jogou, em vez de dividir por zero.
- **`readMaybe`, nunca `read`**: `read "dois" :: Int` derruba o programa; `readMaybe`
  devolve `Nothing`, que vira `NumeroInvalido` com o `paraEither` da aula 14.
- **Número grande demais**: `readMaybe "99999999999999999999" :: Maybe Int` não falha, o
  valor estoura e vira um número qualquer. Por isso `lerNumero` lê como `Integer` e só
  aceita se couber em `Int` (`readMaybe s >>= cabeEmInt`, o `>>=` do Maybe).
- **`lerCampeonato` × `todosOsErros`**: o primeiro usa `traverse` e `do` em `Either` e
  para no primeiro erro (ou tudo é lido, ou nada). O segundo lê cada linha com `map`,
  separa os erros com `lefts` e mostra todos, que é o que um usuário corrigindo o arquivo
  quer ver.
- **Núcleo puro, casca de IO** (aula 14): toda a lógica é pura e testável com `==`; o
  `main` só imprime. Os dados ficam numa `String` no código, sem `getLine`, para rodar
  também no playground.
- **Erros com número da linha**: `lerPartida` recebe o número da linha, e cada `Erro`
  carrega a linha (ou a rodada, no `TimeRepetidoNaRodada`). A numeração é feita antes de
  descartar linhas em branco e comentários (`#`), para o número bater com o texto
  original.
- **Um arquivo só**: o playground não aceita vários módulos, então o código fica em
  `Main.hs`, com as seções na ordem dos módulos da Seção 6 (Tipos, Classificacao,
  Leitura, Dados, Main), como o enunciado permite.
- **`main` é a única função com IO**: tudo o que ele imprime vem de funções puras
  (`relatorio` e `relatorioDeErros` montam as Strings), então a saída também é testável.
- **`System.IO`**: além dos módulos listados no enunciado, usamos `hSetEncoding stdout
  utf8`, também da biblioteca `base`. Sem isso, no terminal do Windows, imprimir
  "Paraná" ou "Classificação" pode encerrar o programa com o erro "invalid argument
  (cannot encode character)".

## 4. Limitações

- Nomes de times são comparados exatamente: `"Coritiba"` e `"coritiba"` viram dois times.
  Os espaços em volta são removidos (`aparar`), mas não há normalização de maiúsculas ou
  acentos.
- O separador `;` não pode aparecer dentro do nome de um time.
- Não há confronto direto como critério de desempate: depois de gols pró, o desempate é
  alfabético.
- `TimeRepetidoNaRodada` só confere se um time joga duas vezes na mesma rodada. Não
  confere se a mesma partida foi digitada em rodadas diferentes, nem se todos jogaram o
  mesmo número de vezes.
- `repetidosNaRodada` compara cada aparição com todas as outras (O(n²)). Para um
  campeonato real (380 jogos) ainda é instantâneo; para muito mais, o certo seria agrupar
  com `Data.Map`.
- `maiorGoleada` com empate na diferença devolve uma só partida (a última com a maior
  diferença, comportamento do `maximumBy`).
