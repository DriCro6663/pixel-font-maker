@rem 文字コード Shift-JIS -> UTF-8 変更
chcp 65001

@rem Commit all the files you have changed.
echo git add .
git add .
echo git commit -m "new commit"
git commit -m "new commit"

@rem Push remote repository.
echo git push -u origin main
git push -u origin main

echo Press the key to exit ...
pause > NUL

echo 終了します
exit