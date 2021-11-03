@echo off

@rem 文字コード Shift-JIS -> UTF-8 変更
chcp 65001

echo Converting font-image to font-svg ...

rem Convert font image to font data
cd ./script
call node ./index.js

echo Done.
echo Please chuck [font-svg] folder .

echo Press the key to exit ...
pause > NUL

echo 終了します
exit