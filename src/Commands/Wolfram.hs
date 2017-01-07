{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE ScopedTypeVariables #-}
module Commands.Wolfram
(
    wolfram
)
where

import Servant.API
import Servant.Client
import Control.Monad.IO.Class
import Control.Monad.Except
import Network.IRC
import Data.Response
import Data.BotConfig
import Data.Maybe
import Data.Monoid
import Data.Proxy
import Data.Attoparsec.ByteString.Char8
import Data.ByteString.Char8 (unpack, pack)
import Network.HTTP.Client (Manager)

newtype Query = Query String
    deriving (Eq, Show, Ord, ToHttpApiData)

parser :: Parser Query
parser = Query . unpack <$>
    (char ':' *> choice [ string "hal", string "wa" ] 
              *> skipSpace *> takeByteString)

type WolframShort = "v1" 
                 :> "result" 
                 :> QueryParam "appid" WolframAPIKey 
                 :> QueryParam "i" Query 
                 :> Get '[PlainText] String

shortAnswer :: Client WolframShort
shortAnswer = client (Proxy :: Proxy WolframShort)

baseUrl :: BaseUrl
baseUrl = BaseUrl Http "api.wolframalpha.com" 80 ""

wolfram :: MonadIO m => Manager -> Maybe WolframAPIKey -> Response m
wolfram _ Nothing = emptyResponse
wolfram man appid = fromMsgParser parser $ \p chan q -> do
    let u = fromMaybe "Dave" $ msgUser' p
    res <- liftIO $
        runExceptT (shortAnswer appid (Just q) man baseUrl)
    return $ case res of
        Left _ -> privmsg (fromMaybe "" chan) $
                      "I'm sorry " <> u <> ", I'm afraid I can't do that."
        Right r -> privmsg (fromMaybe "" chan) (pack r)
