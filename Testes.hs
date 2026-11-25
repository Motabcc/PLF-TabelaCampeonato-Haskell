{-# OPTIONS_GHC -main-is Testes #-}
-- Testes do PjBL 2 
-- Rodar da pasta raiz: runghc -i. tests/Testes.hs

module Testes (main) where

import Main hiding (main)
import System.IO (hSetEncoding, stdout, utf8)


-- função para testar enunciado
testar :: (Eq a, Show a) => String -> a -> a -> IO ()
testar nome obtido esperado
  | obtido == esperado = putStrLn ("OK      " ++ nome)
  | otherwise          = putStrLn ("FALHOU " ++ nome ++ ": " ++ show obtido)

coxAth :: Partida
coxAth = Partida 1 "Coritiba" 3 0 "Athletico"

-- Alfa e Bravo empatam em tudo, só o nome decide
empateTotal :: [Partida]
empateTotal =
  [ Partida 1 "Bravo" 1 1 "Alfa"
  , Partida 2 "Alfa"  2 0 "Charlie"
  , Partida 3 "Bravo" 2 0 "Charlie"
  ]

main :: IO ()
main = do
  hSetEncoding stdout utf8

  putStrLn "--- Camada 1 ---"
  testar "resultadoPara: mandante"            (resultadoPara "Coritiba" coxAth)  (Just Vitoria)
  testar "resultadoPara: visitante"           (resultadoPara "Athletico" coxAth) (Just Derrota)
  testar "resultadoPara: empate"              (resultadoPara "Paraná" (Partida 1 "Paraná" 0 0 "Operário")) (Just Empate)
  testar "resultadoPara: time que não jogou"  (resultadoPara "Londrina" coxAth)  Nothing
  testar "participou: mandante e visitante"   (map (`participou` coxAth) ["Coritiba", "Athletico", "Paraná"]) [True, True, False]
  testar "times: sem repetição, em ordem alfabética"
    (times campeonato) ["Athletico", "Cascavel", "Coritiba", "Londrina", "Operário", "Paraná"]
  testar "times: campeonato vazio"            (times []) []

  putStrLn "--- Camada 2 ---"
  testar "pontos: vitória, empate e derrota"  (map pontos [Vitoria, Empate, Derrota]) [3, 1, 0]
  testar "linhaDoTime: Coritiba"              (linhaDoTime campeonato "Coritiba") (Linha "Coritiba" 5 3 1 1 8 4)
  testar "linhaDoTime: time que não jogou"    (linhaDoTime campeonato "Maringá") (linhaVazia "Maringá")
  testar "pontosLinha e saldo: Coritiba"
    (let l = linhaDoTime campeonato "Coritiba" in (pontosLinha l, saldo l)) (10, 4)
  testar "aproveitamento: 10 de 15 pontos"
    (round (aproveitamento (linhaDoTime campeonato "Coritiba") * 100) :: Int) 6667
  testar "aproveitamento: time sem jogos dá 0" (aproveitamento (linhaVazia "Maringá")) 0

  -- conferida à mão: (time, pontos, vitórias, saldo)
  testar "classificacao completa (conferida à mão)"
    (map (\l -> (time l, pontosLinha l, vitorias l, saldo l)) (classificacao campeonato))
    [ ("Coritiba", 10, 3,  4), ("Operário", 10, 3,  3), ("Cascavel", 7, 2, -2)
    , ("Paraná",    6, 1,  1), ("Athletico", 4, 1, -4), ("Londrina", 3, 0, -2) ]
  -- 10 pts e 3 V cada, decide o saldo
  testar "desempate pelo saldo: Coritiba x Operário"
    (map time (take 2 (classificacao campeonato))) ["Coritiba", "Operário"]
  -- 2 pts, 0 V e saldo -1 cada, decide gols pró
  testar "desempate por gols pró: Londrina x Paraná até a rodada 3"
    (map time (drop 4 (classificacao (ateRodada 3 campeonato)))) ["Londrina", "Paraná"]
  testar "desempate pelo nome: empate total"
    (map time (classificacao empateTotal)) ["Alfa", "Bravo", "Charlie"]
  testar "classificacao de ateRodada 3"
    (map time (classificacao (ateRodada 3 campeonato)))
    ["Coritiba", "Operário", "Athletico", "Cascavel", "Londrina", "Paraná"]
  testar "ateRodada 3 é diferente da classificação final"
    (classificacao (ateRodada 3 campeonato) /= classificacao campeonato) True
  testar "ateRodada 0: nenhuma partida"       (ateRodada 0 campeonato) []
  testar "classificacao: campeonato vazio"    (classificacao []) []
  testar "maiorGoleada do campeonato"         (maiorGoleada campeonato) (Just coxAth)
  testar "maiorGoleada []"                    (maiorGoleada []) Nothing
  testar "mediaGols: 39 gols em 15 jogos"     (fmap (round . (* 10)) (mediaGols campeonato) :: Maybe Int) (Just 26)
  testar "mediaGols []"                       (mediaGols []) Nothing

  putStrLn "--- Camada 3 ---"
  testar "separar"                            (separar ';' "1;A;;2") ["1", "A", "", "2"]
  testar "lerPartida: linha válida, com espaços"
    (lerPartida 1 " 1 ; Coritiba ; 3 ; 0 ; Athletico ") (Right coxAth)
  testar "lerCampeonato: entrada válida dá Right"
    (lerCampeonato dadosCampeonato) (Right campeonato)
  testar "lerCampeonato: texto vazio dá Right []" (lerCampeonato "") (Right [])
  -- um teste para cada construtor de Erro
  testar "Erro CamposInvalidos (falta campo)" (lerPartida 7 "1;Paraná;0;0") (Left (CamposInvalidos 7 "1;Paraná;0;0"))
  testar "Erro CamposInvalidos (time vazio)"  (lerPartida 2 "1;;0;0;B") (Left (CamposInvalidos 2 "1;;0;0;B"))
  testar "Erro NumeroInvalido (placar dois)"  (lerPartida 4 "2;Operário;dois;0;Londrina") (Left (NumeroInvalido 4 "dois"))
  testar "Erro PlacarNegativo"                (lerPartida 5 "2;Cascavel;-1;2;Paraná") (Left (PlacarNegativo 5))
  testar "Erro MesmoTime"                     (lerPartida 6 "2;Londrina;1;1;Londrina") (Left (MesmoTime 6 "Londrina"))
  testar "Erro TimeRepetidoNaRodada"
    (lerCampeonato "1;A;1;0;B\n1;A;2;2;C") (Left (TimeRepetidoNaRodada 1 "A"))
  testar "lerCampeonato para no primeiro erro"
    (lerCampeonato dadosComErros) (Left (CamposInvalidos 3 "1;Paraná;0;0"))
  testar "todosOsErros: lista todos os erros"
    (todosOsErros dadosComErros)
    [ CamposInvalidos 3 "1;Paraná;0;0"
    , NumeroInvalido 4 "dois"
    , PlacarNegativo 5
    , MesmoTime 6 "Londrina"
    , TimeRepetidoNaRodada 1 "Coritiba"
    ]
  testar "todosOsErros: entrada válida não tem erros" (todosOsErros dadosCampeonato) []
  testar "tabelaFormatada: linha do líder"
    (take 2 (lines (tabelaFormatada (classificacao campeonato))))
    [ " #  Time        P   J   V   E   D  GP  GC  SG   Aprov"
    , " 1  Coritiba   10   5   3   1   1   8   4  +4   66,7%" ]
