# distributed-video-archiver
## 録画拠点側
OBS Studioの録画設定で、録画ファイルの保存名を `{year}-{month}-{day}-{hour}-{min}-{sec}.ts` の形式に設定する。
[source/send.sh](/source/send.sh) を任意のディレクトリに配置し、実行権限を付与する。
```bash
git clone https://github.com/TechnoTUT/distributed-video-archiver.git
cd distributed-video-archiver/source
vim send.sh
# 必要に応じて SOURCE_DIR と DEST_DIR を変更
chmod +x send.sh
```
cronなどで30分ごとに実行する。
```bash
15,45 * * * * /path/to/send.sh
```
## 動画処理拠点側
### utone_transfer.bat
録画拠点から転送された.tsファイルを圧縮して共有ストレージにパスするスクリプト。処理開始から30分ごとに、一時受け入れフォルダ内のtsファイルを探索しNVEncを用いてMP4形式に変換する。
処理端末側の一時受け入れフォルダに [ytone_transfer.bat](/source/utone_transfer.bat)を配置し、実行する。

FFmpegと、NVEncに対応したGPUが必要です。
