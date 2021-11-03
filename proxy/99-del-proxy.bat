@echo off

echo Delete proxy, https-proxy and registry setting for npm

call npm -g config delete proxy
call npm -g config delete https-proxy
call npm -g config delete registry

echo Completed...