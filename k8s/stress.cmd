@echo off
setlocal enabledelayedexpansion

rem Define o intervalo entre as requisições (em segundos)
set "interval=1"

rem Permite definir o intervalo através de um argumento de linha de comando
if not "%~1"=="" set "interval=%~1"

rem Loop para enviar 10000 requisições
for /L %%i in (1,1,10000) do (
    echo Enviando requisição %%i
    curl http://localhost:31300/lanchonete/v1/produtos
    timeout /t %interval% >nul
)

endlocal
