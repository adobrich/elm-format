module ElmFormat.FileWriter (FileWriter, FileWriterF(..), writeFile, overwriteFile, execute) where

import qualified System.Directory as Dir

import Prelude hiding (writeFile)
import Control.Monad.Free
import Data.Text (Text)
import qualified Data.ByteString as ByteString
import qualified Data.Text.Encoding as Text


class Functor f => FileWriter f where
    writeFile :: FilePath -> Text -> f ()
    overwriteFile :: FilePath -> Text -> f ()


data FileWriterF a
    = WriteFile FilePath Text a
    | OverwriteFile FilePath Text a


instance Functor FileWriterF where
    fmap f (WriteFile path content a) = WriteFile path content (f a)
    fmap f (OverwriteFile path content a) = OverwriteFile path content (f a)


instance FileWriter FileWriterF where
    writeFile path content = WriteFile path content ()
    overwriteFile path content = OverwriteFile path content ()


instance FileWriter f => FileWriter (Free f) where
    writeFile path content = liftF (writeFile path content)
    overwriteFile path content = liftF (overwriteFile path content)


execute :: FileWriterF a -> IO a
execute operation =
    case operation of
        WriteFile path content next ->
            do
                exists <- Dir.doesFileExist path
                case exists of
                    True ->
                        error "file exists and was not marked to be overwritten"
                    False ->
                        (ByteString.writeFile path $ Text.encodeUtf8 content) *> return next

        OverwriteFile path content next ->
            (ByteString.writeFile path $ Text.encodeUtf8 content) *> return next
