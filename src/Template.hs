{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE TemplateHaskell #-}

module Template
  ( main
  )
where

import Control.Monad
import Control.Exception
import Control.Concurrent
import Data.IORef
import Control.Lens

data FlushMsg = Flush
                deriving (Exception, Show)

data FizzBuzzMsg = Fizz
                 | Buzz
                 | Num Int
                 deriving (Exception, Show)
makePrisms ''FizzBuzzMsg

main :: IO ()
main = do
  putStrLn "startin"
  emitter <- forkIO $ emitter
  putStrLn "emmiter"
  fizzTid <- forkIO $ fizz emitter
  putStrLn "buzz"
  buzzTid <- forkIO $ buzz emitter
  putStrLn "numsender"
  numsTid  <- forkIO $ numSender emitter
  let threads = [fizzTid, buzzTid, numsTid]
  forever $ do
    void $ traverse (flip throwTo Flush) threads
    threadDelay 0_0010_000 -- wait for exceptions to arrive from work threads to emitter
    throwTo emitter Flush
    threadDelay 0_0010_000 -- emitter needs some time to clear before dealing with new exceptions

emitter :: IO ()
emitter = mask $ \unmask -> do -- we use unmask to indicate when we're ready for new messages
  ref <- newIORef []
  forever $
      handle (\case
                   Flush -> do
                     res <- readIORef ref
                     writeIORef ref []
                     if (hasn't (traversed . failing _Fizz _Buzz) res) then do
                         void $ traverse print $ reverse $ res ^.. traversed . _Num
                     else do -- has a fizz or buzz (or both
                        traverseOf (traversed . _Fizz) (const $ putStr "Fizz") res
                        traverseOf (traversed . _Buzz) (const $ putStr "Buzz") res
                        putStr "\n"
            ) $ handle (putItIn ref) $ unmask waitMsg

putItIn :: IORef [FizzBuzzMsg] -> FizzBuzzMsg -> IO ()
putItIn ref msg = modifyIORef ref (msg :)

numSender :: ThreadId -> IO ()
numSender tid = mask $ \unmask -> do
    ref <- newIORef 1
    forever $
      handle (\case
                   Flush -> do
                     cur <- atomicModifyIORef ref (\num -> (num + 1, num))
                     throwTo tid $ Num cur
                     pure ()
               ) $ unmask waitMsg

-- this is a safe point, eg can receive exceptions
waitMsg :: IO ()
waitMsg = threadDelay 10_000_000

fizz :: ThreadId -> IO ()
fizz tid = mask $ \unmask -> do
  forever $ handle (\case
              -- completely declerative I suppose,
              -- we just catch a flush 3 times before sending fizz.
              -- no slow modulo for us!
             Flush -> throwTo tid Fizz) $
    handle (\case
             Flush -> unmask waitMsg) $
      handle (\case
              Flush -> unmask waitMsg) $ unmask waitMsg

buzz :: ThreadId -> IO ()
buzz tid = mask $ \unmask -> do
  forever $ handle (\case
             Flush -> throwTo tid Buzz) $
    handle (\case
             Flush -> unmask waitMsg) $
    handle (\case
             Flush -> unmask waitMsg) $
    handle (\case
             Flush -> unmask waitMsg) $
      handle (\case
              Flush -> unmask waitMsg) $ unmask waitMsg
