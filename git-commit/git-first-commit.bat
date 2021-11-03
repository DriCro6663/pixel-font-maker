@rem 文字コード Shift-JIS -> UTF-8 変更
chcp 65001

@rem Move to the base directory.
cd ..

@rem Git initialization
echo git init
git init

@rem Commit all the files you have changed.
echo git add .
git add .
echo git commit -m "first commit"
git commit -m "first commit"

@rem Set remote repository settings.
echo git branch -M main
git branch -M main
echo git remote add origin https://DriCro6663@github.com/DriCro6663/pixel-font-maker.git
git remote add origin https://DriCro6663@github.com/DriCro6663/pixel-font-maker.git

@rem Check remote repository settings.
echo git remote -v
git remote -v

@rem Push remote repository.
echo git push -u origin main
git push -u origin main

echo Press the key to exit ...
pause > NUL

echo 終了します
exit