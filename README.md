# PLF – Tabela de Classificação em Haskell (PjBL 2)

Calcula a tabela de classificação de um campeonato de pontos corridos a partir da lista de
partidas: pontos, jogos, vitórias, empates, derrotas, gols pró e contra, saldo e
aproveitamento, com critérios de desempate. Também lê as partidas a partir de texto,
validando cada linha e informando os erros.

## Como rodar

**Ambiente utilizado: GHC local** (instalado via GHCup; testado nas versões 8.10, 9.6 e
9.14). O `Main.hs` também roda sem alterações no [playground](https://play.haskell.org);
os testes (`Testes.hs`) precisam do GHC local, porque importam o `Main.hs`.

```bash
runghc Main.hs                      # roda o programa
ghc -Wall Main.hs && ./Main         # compila (sem nenhum aviso) e roda (no Windows: Main.exe)
runghc Testes.hs                    # roda os testes (nesta pasta)
```

No playground: cole o conteúdo de `Main.hs` e clique em Run.

## Estrutura

Como o grupo optou por um arquivo único (compatível com o playground), o `Main.hs` tem
as seções na mesma ordem dos módulos da Seção 6 do enunciado: Tipos, Classificacao,
Leitura, Dados e Main.

```
Main.hs            código completo, dividido em seções (Tipos, Classificacao, Leitura, Dados, Main)
Testes.hs          40 testes com resultado esperado (Seção 7 e casos de borda)
docs/decisoes.md   foldl × foldr, modelo da Linha, outras decisões e limitações
README.md          este arquivo
```

| Camada | O que tem |
|---|---|
| 1 | `Time`, `Resultado`, `Partida`, `Linha`; `participou`, `resultadoPara` (Maybe), `times` |
| 2 | `pontos`, `linhaDoTime` (foldl), `pontosLinha`, `saldo`, `aproveitamento`, `classificacao` (sortBy + comparing + Down + `<>`), `ateRodada`, `maiorGoleada` e `mediaGols` (Maybe). Sem recursão explícita |
| 3 | `Erro`, `separar`, `lerPartida` (do em Either), `lerCampeonato` (traverse), `todosOsErros`, `tabelaFormatada` |
| Dados | `dadosCampeonato` (o campeonato de teste como String), `campeonato` (o mesmo, como lista) e `dadosComErros` |
| Main | `main`, a única função com IO |

## Formato dos dados em texto

Uma partida por linha, campos separados por `;`:

```
# rodada;mandante;gols mandante;gols visitante;visitante
1;Coritiba;3;0;Athletico
```

Linhas em branco e linhas que começam com `#` são ignoradas, e os espaços em volta dos
campos são removidos. Cada erro indica a linha (ou a rodada) do problema:

| Erro | Quando |
|---|---|
| `CamposInvalidos linha conteúdo` | a linha não tem 5 campos, ou um nome de time está vazio |
| `NumeroInvalido linha texto` | rodada ou gols não são número inteiro (`dois`, `2.5`, um número grande demais), ou a rodada é menor que 1 |
| `PlacarNegativo linha` | gols negativos |
| `MesmoTime linha time` | mandante igual ao visitante |
| `TimeRepetidoNaRodada rodada time` | um time joga duas vezes na mesma rodada |

O número da linha é o do texto original, contando também as linhas em branco e os
comentários.

## Campeonato de teste

6 times, 5 rodadas, turno único. Tem um 0 x 0 (Paraná x Operário), uma goleada
(Coritiba 3 x 0 Athletico) e um empate em pontos: Coritiba e Operário terminam com 10
pontos e 3 vitórias, e o saldo decide.

## Saída

```
=== Classificação final ===
 #  Time        P   J   V   E   D  GP  GC  SG   Aprov
 1  Coritiba   10   5   3   1   1   8   4  +4   66,7%
 2  Operário   10   5   3   1   1   8   5  +3   66,7%
 3  Cascavel    7   5   2   1   2   4   6  -2   46,7%
 4  Paraná      6   5   1   3   1   3   2  +1   40,0%
 5  Athletico   4   5   1   1   3   8  12  -4   26,7%
 6  Londrina    3   5   0   3   2   8  10  -2   20,0%

=== Classificação até a rodada 3 ===
 #  Time        P   J   V   E   D  GP  GC  SG   Aprov
 1  Coritiba    9   3   3   0   0   6   1  +5  100,0%
 2  Operário    4   3   1   1   1   3   2  +1   44,4%
 3  Athletico   4   3   1   1   1   6   7  -1   44,4%
 4  Cascavel    3   3   1   0   2   3   6  -3   33,3%
 5  Londrina    2   3   0   2   1   5   6  -1   22,2%
 6  Paraná      2   3   0   2   1   1   2  -1   22,2%

=== Estatísticas ===
Maior goleada: rodada 1, Coritiba 3 x 0 Athletico
Média de gols por partida: 2,6

=== Entrada com erros ===
lerCampeonato (para no primeiro erro):
  linha 3: esperado rodada;mandante;gols;gols;visitante, veio "1;Paraná;0;0"
todosOsErros (todos os erros):
  - linha 3: esperado rodada;mandante;gols;gols;visitante, veio "1;Paraná;0;0"
  - linha 4: "dois" não é um número válido
  - linha 5: placar negativo
  - linha 6: Londrina não pode jogar contra ele mesmo
  - rodada 1: Coritiba joga mais de uma vez
```

## Equipe

Gabriel Mota, Clara Miyamoto, Cauã Brylkowski, Vicente Migliorini.
