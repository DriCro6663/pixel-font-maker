@echo off

echo Set proxy setting for npm

set SERVER=proxy.nagaokaut.ac.jp
set PORT=8080

echo npm -g config set proxy http://%SERVER%:%PORT%/
call npm -g config set proxy http://%SERVER%:%PORT%/

echo npm -g config set https-proxy http://%SERVER%:%PORT%/
call npm -g config set https-proxy http://%SERVER%:%PORT%/

echo npm -g config set registry http://registry.npmjs.org/
call npm -g config set registry http://registry.npmjs.org/

echo Completed...