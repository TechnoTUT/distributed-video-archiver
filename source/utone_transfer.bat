@echo off
setlocal enabledelayedexpansion

:: =================================================================
:: カレントディレクトリ内の .ts ファイルを監視し、見つかった場合に
:: FFmpeg を使って H.265/HEVC (NVEnc) 形式の .mp4 に変換します。
:: 変換成功後、.mp4 を指定のネットワーク共有に移動し、
:: 元の .ts ファイルを削除します。
:: =================================================================

:: --- 設定項目 ---

:: 変換後のMP4ファイルを移動する先のディレクトリ
:: イベントごとにUtone_Rec以下を書き換える必要あり
set "DestinationDir=\\10.1.70.0\share\Utone_Rec\20250705_utone4_x_gilleworkers"

:: ファイル検索の間隔（秒）
set "CheckIntervalSeconds=1800"

:: FFmpegのエンコード設定
set "ffmpegOptions=-c:v hevc_nvenc -preset p7 -cq 20 -c:a aac"

:: --- スクリプト本体 ---

title TS Transcoder (Batch Version)
echo --- TS transcoder is now starting ---
echo Watching: %~dp0
echo Destination directory: %DestinationDir%
echo Press Ctrl + C to stop the script
echo -------------------------------------

:main_loop
:: ループの開始点

:: /bでファイル名のみ、/a-dでフォルダを除外して.tsファイルを検索
:: `dir`コマンドはファイルが見つからない場合に errorlevel を 1 に設定します。
dir /b /a-d "*.ts" >nul 2>&1
if %errorlevel% neq 0 (
    echo .ts file not found. Retry in %CheckIntervalSeconds% sec...
    goto :wait
)

echo Found .ts file(s). Starting processing...

:: 見つかったすべての.tsファイルを順番に処理
for %%F in ("*.ts") do (
    echo.
    echo [!date! !time!] found: "%%~nxF"

    :: 処理中のファイル名と出力ファイル名を変数に設定
    set "processingFile=%%~nF.processing.ts"
    set "outputMp4Path=%%~nF.mp4"

    :: 処理中とわかるようにファイル名を変更
    ren "%%~fF" "!processingFile!"

    :: FFmpegコマンドを実行
    echo Start encoding: ffmpeg -i "!processingFile!" %ffmpegOptions% "!outputMp4Path!"
    ffmpeg -i "!processingFile!" %ffmpegOptions% "!outputMp4Path!"

    :: FFmpegの実行結果を確認 (errorlevelが0なら成功)
    if !errorlevel! equ 0 (
        echo Successfully encoded: "!outputMp4Path!"

        :: MP4ファイルを移動
        echo Moving to: %DestinationDir%
        move "!outputMp4Path!" "%DestinationDir%"

        :: moveコマンドの実行結果を確認
        if !errorlevel! equ 0 (
            echo Successfully moved to %DestinationDir%
            
            :: 元の処理中ファイルを削除
            del "!processingFile!"
            echo Deleted "!processingFile!"
        ) else (
            echo ERROR: Failed to move "!outputMp4Path!". The file will be kept here.
            echo Reset file name: "%%~nxF"
            ren "!processingFile!" "%%~nxF"
        )
    ) else (
        echo ERROR: Encode failed! Code: !errorlevel!
        
        :: エラーが発生した場合、ファイル名を元に戻す
        if exist "!processingFile!" (
            ren "!processingFile!" "%%~nxF"
            echo Reset file name: "%%~nxF"
        )
        :: 不完全に生成されたMP4ファイルがあれば削除
        if exist "!outputMp4Path!" (
            del "!outputMp4Path!"
        )
    )
)

:wait
:: 指定した時間だけ待機
echo.
echo All tasks finished. Waiting for %CheckIntervalSeconds% seconds...
timeout /t %CheckIntervalSeconds% /nobreak > nul
goto main_loop