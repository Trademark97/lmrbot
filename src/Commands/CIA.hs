{-# LANGUAGE OverloadedStrings #-}
module Commands.CIA
(
    cia
)
where

import Control.Applicative
import Control.Monad.Random.Class
import Data.Response
import Data.Maybe
import Data.Monoid
import Network.IRC
import Data.Attoparsec.ByteString.Char8 (Parser, string)
import qualified Data.ByteString.Char8 as B

parser :: Parser B.ByteString
parser = string ":cia" <|> string ":CIA"

cia :: MonadRandom m => Response m
cia = fromMsgParser parser $ \_ chan _ -> do
    c <- getRandomR (1337 :: Int, 99999 :: Int)
    let ret = "This incident has been reported. Case #" <> B.pack (show c)
    return $ privmsg (fromMaybe "" chan) ret
