{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}
module Server
    (server)
where

import Data.Aeson (ToJSON, FromJSON, object, toJSON, (.=))
import qualified Data.Time.Clock as C
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
                       deriving (Generic, Show)

instance ToJSON Message
instance FromJSON Message

data TimedMessage = TimedMessage C.UTCTime Message
                       deriving (Show)

instance ToJSON TimedMessage where
    toJSON (TimedMessage t m) = object ["name" .= (name m), "msg" .= (msg m), "time" .= t]

-- This is the "database"
type Chat = TVar (V.Vector TimedMessage)

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
getWebchat = get "/chat.html" $ file "text/html" "web/chat.html"

getMessages :: Chat -> SpockT IO ()
getMessages chat = get "/chat" $ json =<< liftIO (readTVarIO chat)

postMessage :: Chat -> SpockT IO ()
postMessage chat = do
        post ("/write") $ do
            m <- jsonBody'
            time <- liftIO $ C.getCurrentTime
            let tm = TimedMessage time m
            liftIO $ atomically (appendMessage chat tm)
            json =<< liftIO (readTVarIO chat)

appendMessage :: Chat -> TimedMessage -> STM ()
appendMessage chat tm = modifyTVar chat append
    where append messages = V.take 10 .  V.cons tm $ messages
