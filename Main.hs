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

