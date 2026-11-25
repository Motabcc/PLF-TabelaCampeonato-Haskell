-- PjBL 2 - Tabela de Classificação de Campeonato
-- Gabriel Mota, Vicente Migliorini, Clara Miyamoto, Cauã Brylkowski - BCC - Manhã-A -PUCPR 2026/2
--
-- Rodar: runghc Main.hs  (ou colar no play.haskell.org)
-- Seções na ordem da Seção 6: Tipos, Classificacao, Leitura, Dados, Main

module Main where

import Data.Char (isSpace)
import Data.Either (lefts, rights)
import Data.List (dropWhileEnd, maximumBy, nub, sort, sortBy)
import Data.Ord (Down (..), comparing)
import System.IO (hSetEncoding, stdout, utf8)
import Text.Read (readMaybe)

-- Camada 1 , Tipos

type Time = String

data Resultado = Vitoria | Empate | Derrota
  deriving (Show, Eq)

data Partida = Partida
  { rodada        :: Int
  , mandante      :: Time
  , golsMandante  :: Int
  , golsVisitante :: Int
  , visitante     :: Time
  } deriving (Show, Eq)

-- pontos e saldo não ficam aqui: são calculados a partir dos campos
data Linha = Linha
  { time       :: Time
  , jogos      :: Int
  , vitorias   :: Int
  , empates    :: Int
  , derrotas   :: Int
  , golsPro    :: Int
  , golsContra :: Int
  } deriving (Show, Eq)

participou :: Time -> Partida -> Bool
participou t p = t == mandante p || t == visitante p

resultadoDoPlacar :: Int -> Int -> Resultado
resultadoDoPlacar meus deles
  | meus > deles = Vitoria
  | meus < deles = Derrota
  | otherwise    = Empate

-- (gols feitos, gols sofridos) pelo time t
golsDe :: Time -> Partida -> Maybe (Int, Int)
golsDe t p
  | t == mandante p  = Just (golsMandante p, golsVisitante p)
  | t == visitante p = Just (golsVisitante p, golsMandante p)
  | otherwise        = Nothing

resultadoPara :: Time -> Partida -> Maybe Resultado
resultadoPara t p = fmap (uncurry resultadoDoPlacar) (golsDe t p)

times :: [Partida] -> [Time]
times = sort . nub . concatMap (\p -> [mandante p, visitante p])

-- Camada 2, Classificacao

pontos :: Resultado -> Int
pontos Vitoria = 3
pontos Empate  = 1
pontos Derrota = 0

linhaVazia :: Time -> Linha
linhaVazia t = Linha
  { time = t, jogos = 0, vitorias = 0, empates = 0
  , derrotas = 0, golsPro = 0, golsContra = 0 }

-- 1 se o resultado é o esperado, 0 se não
contar :: Resultado -> Resultado -> Int
contar esperado r
  | r == esperado = 1
  | otherwise     = 0

-- acumulado primeiro para encaixar no foldl
somarPartida :: Linha -> Partida -> Linha
somarPartida l p = maybe l somar (golsDe (time l) p)
  where
    somar (feitos, sofridos) =
      let r = resultadoDoPlacar feitos sofridos
      in l { jogos      = jogos l + 1
           , vitorias   = vitorias l + contar Vitoria r
           , empates    = empates l + contar Empate r
           , derrotas   = derrotas l + contar Derrota r
           , golsPro    = golsPro l + feitos
           , golsContra = golsContra l + sofridos
           }

linhaDoTime :: [Partida] -> Time -> Linha
linhaDoTime ps t = foldl somarPartida (linhaVazia t) (filter (participou t) ps)

pontosLinha :: Linha -> Int
pontosLinha l =
  vitorias l * pontos Vitoria + empates l * pontos Empate + derrotas l * pontos Derrota

saldo :: Linha -> Int
saldo l = golsPro l - golsContra l

aproveitamento :: Linha -> Double
aproveitamento l
  | jogos l == 0 = 0
  | otherwise    = 100 * fromIntegral (pontosLinha l)
                       / fromIntegral (jogos l * pontos Vitoria)

-- Brasileirão: pontos, vitórias, saldo, gols pró; nome no lugar do sorteio
criterios :: Linha -> Linha -> Ordering
criterios = comparing (Down . pontosLinha)
         <> comparing (Down . vitorias)
         <> comparing (Down . saldo)
         <> comparing (Down . golsPro)
         <> comparing time

classificacao :: [Partida] -> [Linha]
classificacao ps = sortBy criterios (map (linhaDoTime ps) (times ps))

ateRodada :: Int -> [Partida] -> [Partida]
ateRodada n = filter ((<= n) . rodada)

diferenca :: Partida -> Int
diferenca p = abs (golsMandante p - golsVisitante p)

maiorGoleada :: [Partida] -> Maybe Partida
maiorGoleada [] = Nothing
maiorGoleada ps = Just (maximumBy (comparing diferenca) ps)

mediaGols :: [Partida] -> Maybe Double
mediaGols [] = Nothing
mediaGols ps = Just (fromIntegral (sum (map totalGols ps)) / fromIntegral (length ps))
  where
    totalGols p = golsMandante p + golsVisitante p
