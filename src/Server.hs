{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}
module Server
where

import Data.Aeson (ToJSON, FromJSON)
--import qualified Data.Time.Clock as C
import qualified Data.Vector as V

import Network.Wai.Middleware.Static (staticPolicy, hasPrefix)
import Network.Wai.Middleware.RequestLogger (logStdoutDev)
import Web.Spock.Safe
import GHC.Generics
import Control.Concurrent.STM
import Control.Monad.Trans (liftIO)

data Message = Message { name :: String
                       , msg :: String
                       }
                       deriving (Generic)

instance ToJSON Message
instance FromJSON Message

type Chat = TVar (V.Vector Message)

server :: SpockT IO ()
server = do
    chat <- liftIO $ newTVarIO V.empty
    appMiddleware
    getWebchat
    getMessages chat
    postMessage chat

appMiddleware :: SpockT IO ()
appMiddleware = do
    middleware . staticPolicy $ hasPrefix "web/"
    middleware logStdoutDev

getWebchat :: SpockT IO ()
getWebchat = get "/chat.html" $ file "html" "web/chat.html"

getMessages :: Chat -> SpockT IO ()
getMessages chat = get "/chat" $ json =<< liftIO (readTVarIO chat)

postMessage :: Chat -> SpockT IO ()
postMessage chat = do
        post ("/write") $ do
            m <- jsonBody'
            --time <- liftIO $ C.getCurrentTime
            liftIO $ atomically (appendMessage chat m)
            json =<< liftIO (readTVarIO chat)

appendMessage :: Chat -> Message -> STM ()
appendMessage chat m = modifyTVar chat append
    where append messages = V.take 10 .  V.cons m $  messages
