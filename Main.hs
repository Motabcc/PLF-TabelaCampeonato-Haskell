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


-- Camada 3, Leitura 


-- cada erro leva o número da linha (ou a rodada)
data Erro
  = CamposInvalidos Int String
  | NumeroInvalido Int String
  | PlacarNegativo Int
  | MesmoTime Int Time
  | TimeRepetidoNaRodada Int Time
  deriving (Show, Eq)

-- separar ';' "1;A;2" == ["1","A","2"]
separar :: Char -> String -> [String]
separar sep = foldr passo [""]
  where
    passo c (atual : resto)
      | c == sep  = "" : atual : resto
      | otherwise = (c : atual) : resto
    passo _ []    = []            -- nunca acontece, começa com [""]

aparar :: String -> String
aparar = dropWhileEnd isSpace . dropWhile isSpace

paraEither :: e -> Maybe a -> Either e a
paraEither e Nothing  = Left e
paraEither _ (Just x) = Right x

lerNumero :: Int -> String -> Either Erro Int
lerNumero n s = paraEither (NumeroInvalido n s) (readMaybe s >>= cabeEmInt)

cabeEmInt :: Integer -> Maybe Int
cabeEmInt x
  | x < toInteger (minBound :: Int) || x > toInteger (maxBound :: Int) = Nothing
  | otherwise = Just (fromInteger x)

validarPartida :: Int -> String -> Partida -> Either Erro Partida
validarPartida n linha p
  | null (mandante p) || null (visitante p)   = Left (CamposInvalidos n linha)
  | rodada p < 1                              = Left (NumeroInvalido n (show (rodada p)))
  | golsMandante p < 0 || golsVisitante p < 0 = Left (PlacarNegativo n)
  | mandante p == visitante p                 = Left (MesmoTime n (mandante p))
  | otherwise                                 = Right p

lerPartida :: Int -> String -> Either Erro Partida
lerPartida n linha = case map aparar (separar ';' linha) of
  [r, m, gm, gv, v] -> do
    rod <- lerNumero n r
    gM  <- lerNumero n gm
    gV  <- lerNumero n gv
    validarPartida n linha (Partida rod m gM gV v)
  _ -> Left (CamposInvalidos n linha)

-- numera antes de filtrar para o número bater com o texto original
linhasNumeradas :: String -> [(Int, String)]
linhasNumeradas texto = filter (ehDado . snd) (zip [1 ..] (lines texto))
  where
    ehDado l = not (all isSpace l) && take 1 (aparar l) /= "#"

aparicoes :: [Partida] -> [(Int, Time)]
aparicoes ps = [ (rodada p, t) | p <- ps, t <- [mandante p, visitante p] ]

repetidosNaRodada :: [Partida] -> [(Int, Time)]
repetidosNaRodada ps = nub [ x | x <- todas, length (filter (== x) todas) > 1 ]
  where
    todas = aparicoes ps

verificarRodadas :: [Partida] -> Either Erro [Partida]
verificarRodadas ps = case repetidosNaRodada ps of
  []           -> Right ps
  ((r, t) : _) -> Left (TimeRepetidoNaRodada r t)

-- para no primeiro erro
lerCampeonato :: String -> Either Erro [Partida]
lerCampeonato texto = do
  ps <- traverse (uncurry lerPartida) (linhasNumeradas texto)
  verificarRodadas ps

-- junta os erros de todas as linhas
todosOsErros :: String -> [Erro]
todosOsErros texto =
  lefts lidas ++ map (uncurry TimeRepetidoNaRodada) (repetidosNaRodada (rights lidas))
  where
    lidas = map (uncurry lerPartida) (linhasNumeradas texto)

descreverErro :: Erro -> String
descreverErro (CamposInvalidos n l) =
  "linha " ++ show n ++ ": esperado rodada;mandante;gols;gols;visitante, veio " ++ entreAspas l
descreverErro (NumeroInvalido n s) =
  "linha " ++ show n ++ ": " ++ entreAspas s ++ " não é um número válido"
descreverErro (PlacarNegativo n) =
  "linha " ++ show n ++ ": placar negativo"
descreverErro (MesmoTime n t) =
  "linha " ++ show n ++ ": " ++ t ++ " não pode jogar contra ele mesmo"
descreverErro (TimeRepetidoNaRodada r t) =
  "rodada " ++ show r ++ ": " ++ t ++ " joga mais de uma vez"

-- show "Paraná" sairia "Paran\225"
entreAspas :: String -> String
entreAspas s = "\"" ++ s ++ "\""

mostrarPartida :: Partida -> String
mostrarPartida p =
  "rodada " ++ show (rodada p) ++ ", " ++ mandante p ++ " "
  ++ show (golsMandante p) ++ " x " ++ show (golsVisitante p) ++ " " ++ visitante p

alinharEsq :: Int -> String -> String
alinharEsq n s = s ++ replicate (n - length s) ' '

alinharDir :: Int -> String -> String
alinharDir n s = replicate (n - length s) ' ' ++ s

-- 66.666 vira "66,7"
umaCasa :: Double -> String
umaCasa x = show (d `div` 10) ++ "," ++ show (d `mod` 10)
  where
    d = round (x * 10) :: Int

comSinal :: Int -> String
comSinal n
  | n > 0     = '+' : show n
  | otherwise = show n

tabelaFormatada :: [Linha] -> String
tabelaFormatada ls =
  unlines (cabecalho : [ formatarLinha i l | (i, l) <- zip [1 :: Int ..] ls ])
  where
    largura   = maximum (length "Time" : map (length . time) ls)
    colunas   = concatMap (alinharDir 4)
    cabecalho = alinharDir 2 "#" ++ "  " ++ alinharEsq largura "Time"
                ++ colunas ["P", "J", "V", "E", "D", "GP", "GC", "SG"]
                ++ alinharDir 8 "Aprov"
    formatarLinha i l =
      alinharDir 2 (show i) ++ "  " ++ alinharEsq largura (time l)
      ++ colunas (map show [ pontosLinha l, jogos l, vitorias l, empates l
                           , derrotas l, golsPro l, golsContra l ]
                  ++ [comSinal (saldo l)])
      ++ alinharDir 8 (umaCasa (aproveitamento l) ++ "%")

relatorio :: [Partida] -> String
relatorio ps = unlines
  [ "=== Classificação final ==="
  , tabelaFormatada (classificacao ps)
  , "=== Classificação até a rodada 3 ==="
  , tabelaFormatada (classificacao (ateRodada 3 ps))
  , "=== Estatísticas ==="
  , "Maior goleada: " ++ maybe "nenhuma partida" mostrarPartida (maiorGoleada ps)
  , "Média de gols por partida: " ++ maybe "nenhuma partida" umaCasa (mediaGols ps)
  ]

relatorioDeErros :: String -> String
relatorioDeErros texto = unlines
  ( [ ""
    , "=== Entrada com erros ==="
    , "lerCampeonato (para no primeiro erro):"
    , "  " ++ either descreverErro (const "nenhum erro") (lerCampeonato texto)
    , "todosOsErros (todos os erros):"
    ]
    ++ map (("  - " ++) . descreverErro) (todosOsErros texto) )


--  campeonato de teste, Dados 

-- 6 times, 5 rodadas
-- 0 x 0: Paraná x Operário | goleada: Coritiba 3 x 0 Athletico
-- empate em pontos: Coritiba e Operário (10), desempata no saldo

dadosCampeonato :: String
dadosCampeonato = unlines
  [ "# rodada;mandante;gols mandante;gols visitante;visitante"
  , "1;Coritiba;3;0;Athletico"
  , "1;Paraná;0;0;Operário"
  , "1;Londrina;1;2;Cascavel"
  , ""
  , "2;Coritiba;1;0;Paraná"
  , "2;Athletico;3;3;Londrina"
  , "2;Operário;2;0;Cascavel"
  , ""
  , "3;Coritiba;2;1;Operário"
  , "3;Athletico;3;1;Cascavel"
  , "3;Paraná;1;1;Londrina"
  , ""
  , "4;Coritiba;2;2;Londrina"
  , "4;Athletico;2;3;Operário"
  , "4;Paraná;0;0;Cascavel"
  , ""
  , "5;Coritiba;0;1;Cascavel"
  , "5;Athletico;0;2;Paraná"
  , "5;Operário;2;1;Londrina"
  ]

-- o mesmo campeonato em lista, para os testes
campeonato :: [Partida]
campeonato =
  -- Rodada 1
  [ Partida 1 "Coritiba"  3 0 "Athletico"
  , Partida 1 "Paraná"    0 0 "Operário"
  , Partida 1 "Londrina"  1 2 "Cascavel"
  -- Rodada 2
  , Partida 2 "Coritiba"  1 0 "Paraná"
  , Partida 2 "Athletico" 3 3 "Londrina"
  , Partida 2 "Operário"  2 0 "Cascavel"
  -- Rodada 3
  , Partida 3 "Coritiba"  2 1 "Operário"
  , Partida 3 "Athletico" 3 1 "Cascavel"
  , Partida 3 "Paraná"    1 1 "Londrina"
  -- Rodada 4
  , Partida 4 "Coritiba"  2 2 "Londrina"
  , Partida 4 "Athletico" 2 3 "Operário"
  , Partida 4 "Paraná"    0 0 "Cascavel"
  -- Rodada 5
  , Partida 5 "Coritiba"  0 1 "Cascavel"
  , Partida 5 "Athletico" 0 2 "Paraná"
  , Partida 5 "Operário"  2 1 "Londrina"
  ]

dadosComErros :: String
dadosComErros = unlines
  [ "# texto com erros"
  , "1;Coritiba;2;1;Athletico"
  , "1;Paraná;0;0"                -- CamposInvalidos
  , "2;Operário;dois;0;Londrina"  -- NumeroInvalido
  , "2;Cascavel;-1;2;Paraná"      -- PlacarNegativo
  , "2;Londrina;1;1;Londrina"     -- MesmoTime
  , "1;Coritiba;0;0;Operário"     -- TimeRepetidoNaRodada
  ]


--  Main 
main :: IO ()
main = do
  hSetEncoding stdout utf8    
  putStr (either (\e -> "Erro nos dados: " ++ descreverErro e ++ "\n")
                 relatorio
                 (lerCampeonato dadosCampeonato))
  putStr (relatorioDeErros dadosComErros)
