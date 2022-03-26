{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE DeriveAnyClass #-}
module Template
  ( main
  )
where

import Control.Monad
import Control.Exception
import Control.Concurrent
import Data.IORef

main :: IO ()
main = do
  emitter <- forkIO $ emitter
  fizzTid <- forkIO $ fizz emitter
  buzzTid <- forkIO $ buzz emitter
  numsTid  <- forkIO $ numSender emitter
  let threads = [fizzTid, buzzTid, numsTid, emitter]
  forever $ do
    void $ traverse (flip throwTo Flush) threads
    threadDelay 0_0001_000 -- is this neccisary?

emitter :: IO ()
emitter = do
  ref <- newIORef []
  forever $
      handle (\case
                   Flush -> do
                     res <- readIORef ref
                     writeIORef ref []
                     if (hasn't (traversed . failing _Fizz _Buzz) res) then
                       print $ head $ res ^.. traversed . _Num
                     else do -- has a fizz or buzz (or both
                        traverseOf (traversed . _Fizz) (putStr . show)
                        traverseOf (traversed . _Buzz) (putStr . show)
                        putStr "\n"
            ) $ handle (putItIn ref) $ waitMsg

putItIn :: IORef [FizzBuzzMsg] -> FizzBuzzMsg -> IO ()
putItIn ref msg = modifyIORef ref (msg :)

data FlushMsg = Flush
                deriving (Exception, Show)

data FizzBuzzMsg = Fizz
                 | Buzz
                 | Num Int
                 deriving (Exception, Show)

mainLoop :: Int -> Int -> IO ()
mainLoop untill cur = pure ()

numSender :: ThreadId -> IO ()
numSender tid = do
    ref <- newIORef 0
    forever $
      handle (\case
                   Flush -> do
                     cur <- atomicModifyIORef ref (\num -> (num + 1, num))
                     throwTo tid $ Num cur
                     pure ()
               ) waitMsg

waitMsg :: IO ()
waitMsg = threadDelay 10_000_000

fizz :: ThreadId -> IO ()
fizz tid = forever $
  handle (\case
             Flush -> throwTo tid Fizz) $
    handle (\case
             Flush -> waitMsg) $
      handle (\case
              Flush -> waitMsg) $ waitMsg

buzz :: ThreadId -> IO ()
buzz tid = do
  handle (\case
             Flush -> throwTo tid Buzz) $
    handle (\case
             Flush -> waitMsg) $
    handle (\case
             Flush -> waitMsg) $
    handle (\case
             Flush -> waitMsg) $
      handle (\case
              Flush -> waitMsg) $ waitMsg
