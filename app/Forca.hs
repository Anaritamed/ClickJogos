module Forca where

import Data.Map (Map)
import Data.Text (Text)
import Data.Char (toLower, toUpper, isSpace, isDigit)
import qualified Data.Map as Map
import System.Exit (exitSuccess)
import Control.Concurrent (threadDelay)
import Utils (limpaTerminal, coloreAmarelo, coloreVerde, bold)


forca :: IO()
forca = do
    limpaTerminal
    putStrLn "                                               "
    putStrLn "   ███████╗ ██████╗ ██████╗  ██████╗ █████╗    "
    putStrLn "   ██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔══██╗   "
    putStrLn "   █████╗  ██║   ██║██████╔╝██║     ███████║   "
    putStrLn "   ██╔══╝  ██║   ██║██╔══██╗██║     ██╔══██║   "
    putStrLn "   ██║     ╚██████╔╝██║  ██║╚██████╗██║  ██║   "
    putStrLn "   ╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   "
    putStrLn "               SEJA BEM VINDO!                 "
    putStrLn "                                               "
    putStrLn "                 (1) JOGAR                     "
    putStrLn "              (2) SAIR DO JOGO                 "
    putStrLn "                                               "
    opcao <- getLine
    handleInteracaoInicial opcao

handleInteracaoInicial :: String -> IO()
handleInteracaoInicial opcao
    | opcao == "1" = handleInteracaoInicialForca
    | opcao == "2" = do
        putStrLn "Saindo..."
        exitSuccess
    | otherwise = do
        putStrLn $ bold (coloreAmarelo "Opção inválida!")
        forca

palavraValida :: String -> Bool
palavraValida palavra = not (null palavra) && not (all isSpace palavra) && not (any isDigit palavra)


loopGetLine :: String -> IO String
loopGetLine jogador1 = do
    putStrLn ("\nCerto " ++ bold jogador1 ++ ", qual a palavra da rodada? ")
    palavra <- getLine
    if palavraValida palavra
        then return palavra
        else do
            putStrLn $ bold (coloreAmarelo "Palavra inválida!")
            threadDelay (900 * 1000) -- 0.9 segundos de delay
            limpaTerminal
            loopGetLine jogador1
            
handleInteracaoInicialForca :: IO()
handleInteracaoInicialForca = do
    let regras ="\n📜 Regras do jogo: \n" ++
                "\n- O jogador 1 será o jogador que dirá a palavra para ser adivinhada, assim como qual tema ela se relaciona.\n" ++
                "- O jogador 2 será o jogador que tentará adivinhar a palavra dada pelo jogador 1.\n" ++
                "\n- Caso a palavra contenha uma letra acentuada ou ç, digite exatamente a letra com sua acentuação ou o ç.\n" ++
                "- Por exemplo, caso a palavra fosse 'Maçã' a ≠ ã, assim como c ≠ ç\n"
    putStrLn $ bold (coloreAmarelo regras)
    putStrLn "Digite o seu nome Jogador 1: "
    jogador1 <- getLine
    putStrLn "Digite o seu nome Jogador 2: "
    jogador2 <- getLine
    palavra <- loopGetLine jogador1
    putStrLn "Qual o tema que está relacionado à palavra a ser adivinhada? "
    tema <- getLine
    jogo palavra tema

jogo :: String -> String -> IO ()
jogo palavra tema = do
    let mapaLetras = criaMapaLetras (map toLower palavra) -- Mapa de letras em minúsculas
    let estadoAtual = criaStringSublinhados palavra -- cria string sublinhada com o tamanho da palavra. Ex: maçã ele criaria : _ _ _ _

    let loop stringSublinhada erros letrasDigitadas = do
            limpaTerminal
            atualizaForca erros -- printa forca vazia já que erros inicia em zero

            putStrLn $ bold (coloreAmarelo "\nTEMA: " ++ tema)
            putStrLn stringSublinhada
            putStrLn $ "\nLetras digitadas: " ++ letrasDigitadas
            putStrLn "\nDigite uma letra:"
            letraDigitada <- getLine
            
            if length letraDigitada > 1
                then do
                    putStrLn $ coloreAmarelo "\nAdivinhe com letra e não palavras!"
                    loop stringSublinhada erros letrasDigitadas
                else do
                    let letra = toLower (head letraDigitada) -- Converte a letra digitada para minúscula
                    if letra `elem` letrasDigitadas
                        then do
                            putStrLn $ coloreAmarelo "\nEssa letra já foi digitada!\n"
                            threadDelay (900 * 1000) -- 0.9 segundos de delay
                            limpaTerminal
                            loop stringSublinhada erros letrasDigitadas
                        else do
                            let letrasDigitadasAtualizadas = letra : (" " ++ letrasDigitadas)
                            case Map.lookup letra mapaLetras of
                                Nothing -> do
                                    if (erros + 1) >= 6
                                        then do
                                            handleCenarioPerda palavra
                                            threadDelay (3 * 1000000) -- 2 segundos de delay
                                            forca
                                        else
                                            loop stringSublinhada (erros + 1) letrasDigitadasAtualizadas
                                Just indices -> do
                                    let novoEstadoStringSublinhados = atualizaStringSublinhados letra stringSublinhada indices
                                    if map toLower novoEstadoStringSublinhados == map toLower palavra
                                        then do
                                            handleCenarioVitoria palavra
                                            threadDelay (3 * 1000000) -- 2 segundos de delay
                                            forca
                                        else do
                                            loop novoEstadoStringSublinhados erros letrasDigitadasAtualizadas -- se ainda não completou a palavra e não errou o limite.
    loop estadoAtual 0 []

-- Função que cria a string com sublinhados
criaStringSublinhados :: String -> String
criaStringSublinhados palavra = replicate (length palavra) '_'

-- Função que cria um mapa de letra -> posições
criaMapaLetras :: String -> Map.Map Char [Int]
criaMapaLetras palavra =
    Map.fromListWith (++) [(letra, [i]) | (i, letra) <- zip [0..] palavra]

-- Função para atualizar a string de sublinhados com a letra correta
atualizaStringSublinhados :: Char -> String -> [Int] -> String
atualizaStringSublinhados letra sublinhados indices =
    [if i `elem` indices then letra else sublinhados !! i | i <- [0..length sublinhados - 1]]

-- desenha a forca atualizada a cada erro (contado) passado
atualizaForca :: Int -> IO()
atualizaForca 0 = do
    putStrLn "      ________    \n"
    putStrLn "     |/       |   \n"
    putStrLn "     |        §   \n"
    putStrLn "     |            \n"
    putStrLn "     |            \n"
    putStrLn "     |            \n"
    putStrLn "   __|            \n"
    putStrLn "  |  |            \n"
    putStrLn "  ====             \n"
atualizaForca 1 = do
    putStrLn "      ________     \n"
    putStrLn "     |/       |    \n"
    putStrLn "     |        §    \n"
    putStrLn "     |      (*.*)  \n"
    putStrLn "     |             \n"
    putStrLn "     |             \n"
    putStrLn "   __|             \n"
    putStrLn "  |  |             \n"
    putStrLn "  ====             \n"
atualizaForca 2 = do
    putStrLn "      ________     \n"
    putStrLn "     |/       |    \n"
    putStrLn "     |        §    \n"
    putStrLn "     |      (*.*)  \n"
    putStrLn "     |        |    \n"
    putStrLn "     |       [ ]   \n"
    putStrLn "   __|        |    \n"
    putStrLn "  |  |             \n"
    putStrLn "  ====             \n"
atualizaForca 3 = do
    putStrLn "      ________     \n"
    putStrLn "     |/       |    \n"
    putStrLn "     |        §    \n"
    putStrLn "     |      (*.*)  \n"
    putStrLn "     |        |    \n"
    putStrLn "     |       [ ]   \n"
    putStrLn "   __|        |    \n"
    putStrLn "  |  |       /     \n"
    putStrLn "  ====             \n"
atualizaForca 4 = do
    putStrLn "      ________     \n"
    putStrLn "     |/       |    \n"
    putStrLn "     |        §    \n"
    putStrLn "     |      (*.*)  \n"
    putStrLn "     |        |    \n"
    putStrLn "     |       [ ]   \n"
    putStrLn "   __|        |    \n"
    putStrLn "  |  |       / \\  \n"
    putStrLn "  ====             \n"
atualizaForca 5 = do
    putStrLn "      ________     \n"
    putStrLn "     |/       |    \n"
    putStrLn "     |        §    \n"
    putStrLn "     |      (*.*)  \n"
    putStrLn "     |        |    \n"
    putStrLn "     |      /[ ]   \n"
    putStrLn "   __|        |    \n"
    putStrLn "  |  |       / \\  \n"
    putStrLn "  ====             \n"
atualizaForca 6 = do
    putStrLn "      ________     \n"
    putStrLn "     |/       |    \n"
    putStrLn "     |        §    \n"
    putStrLn "     |      (*.*)  \n"
    putStrLn "     |        |    \n"
    putStrLn "     |      /[ ]\\ \n"
    putStrLn "   __|        |    \n"
    putStrLn "  |  |       / \\  \n"
    putStrLn "  ====             \n"

handleCenarioPerda :: String -> IO()
handleCenarioPerda palavra = do
    limpaTerminal
    putStrLn " ██████╗  █████╗ ███╗   ███╗███████╗     ██████╗ ██╗   ██╗███████╗██████╗ "
    putStrLn "██╔════╝ ██╔══██╗████╗ ████║██╔════╝    ██╔═══██╗██║   ██║██╔════╝██╔══██╗"
    putStrLn "██║  ███╗███████║██╔████╔██║█████╗      ██║   ██║██║   ██║█████╗  ██████╔╝"
    putStrLn "██║   ██║██╔══██║██║╚██╔╝██║██╔══╝      ██║   ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗"
    putStrLn "╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗    ╚██████╔╝ ╚████╔╝ ███████╗██║  ██║"
    putStrLn " ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝     ╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝"
    putStrLn (coloreAmarelo ("                           A PALAVRA ERA: " ++ map toUpper palavra ++ "!"))

handleCenarioVitoria :: String -> IO()
handleCenarioVitoria palavra = do
    putStrLn"  ██████╗███████╗██████╗ ████████╗ █████╗     ██████╗ ███████╗███████╗██████╗  ██████╗ ███████╗████████╗ █████╗ ██╗"
    putStrLn" ██╔════╝██╔════╝██╔══██╗╚══██╔══╝██╔══██╗    ██╔══██╗██╔════╝██╔════╝██╔══██╗██╔═══██╗██╔════╝╚══██╔══╝██╔══██╗██║"
    putStrLn" ██║     █████╗  ██████╔╝   ██║   ███████║    ██████╔╝█████╗  ███████╗██████╔╝██║   ██║███████╗   ██║   ███████║██║"
    putStrLn" ██║     ██╔══╝  ██╔══██╗   ██║   ██╔══██║    ██╔══██╗██╔══╝  ╚════██║██╔═══╝ ██║   ██║╚════██║   ██║   ██╔══██║╚═╝"
    putStrLn" ╚██████╗███████╗██║  ██║   ██║   ██║  ██║    ██║  ██║███████╗███████║██║     ╚██████╔╝███████║   ██║   ██║  ██║██╗"
    putStrLn " ╚═════╝╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝    ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝      ╚═════╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝"
    putStrLn (coloreVerde("                               PARABÉNS, VOCÊ VENCEU! A PALAVRA ERA: " ++ map toUpper palavra ++ "!"))