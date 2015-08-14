module Main where

import Server
import Web.Spock.Safe

main :: IO ()
main = runSpock 8080 $ spockT id server
