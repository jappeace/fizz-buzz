{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE DeriveAnyClass #-}
module Template
  ( main
  )
where

import Control.Monad
import Control.Exception
import Control.Concurrent

main :: IO ()
main = do
  this <- myThreadId
  forkIO $ fizz this
  forkIO $ buzz this
  mainLoop 30 1

data FizzBuzzMsg = MkFizz
                 | MkBuzz
                 deriving (Exception, Show)

mainLoop :: Int -> Int -> IO ()
mainLoop untill cur =
    (handle (mask_ . \case
              MkFizz -> putStr "Fizz"
              MkBuzz -> putStr "Buzz"
              -- fizzbuzz??
          ) $ do
      threadDelay 0_001_000
      mask_ $ putStrLn $ "\n" <> show cur) `finally`when (cur < untill) (mainLoop untill (cur + 1))



fizz :: ThreadId -> IO ()
fizz tid = do
  forever $ do
    threadDelay 0_003_000
    throwTo tid MkFizz


buzz :: ThreadId -> IO ()
buzz tid = do
  forever $ do
    threadDelay 0_005_000
    throwTo tid MkBuzz
