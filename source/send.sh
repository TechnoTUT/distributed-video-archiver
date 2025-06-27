#!/bin/bash

SOURCE_DIR="~/Videos"
DEST_DIR="/path/to/archive"

# 現在時刻の取得
now_epoch=$(date +%s)
start_epoch=$((now_epoch - 3600))      # 1時間前
end_epoch=$((now_epoch - 1800))        # 30分前

start_time=$(date -d "@$start_epoch" '+%Y-%m-%d %H:%M:00')
end_time=$(date -d "@$end_epoch" '+%Y-%m-%d %H:%M:59')

echo "Now: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Copy: $start_time ～ $end_time"

# 検索・処理
find "$SOURCE_DIR" -maxdepth 1 -type f -name "*.ts" | while read -r file; do
    filename=$(basename "$file")                  # 2025-06-28-12-30-00.ts
    file_time=${filename%.ts}                     # 2025-06-28-12-30-00

    # ハイフン区切り → date形式に変換
    file_time_parsed=$(echo "$file_time" | sed -E 's/^([0-9]{4}-[0-9]{2}-[0-9]{2})-([0-9]{2})-([0-9]{2})-([0-9]{2})$/\1 \2:\3:\4/')
    # 2025-06-28 12:30:00

    file_epoch=$(date -d "$file_time_parsed" '+%s' 2>/dev/null) || continue

    # 対象範囲に入っていればコピー
    if [[ $file_epoch -ge $start_epoch && $file_epoch -le $end_epoch ]]; then
        echo "Copy: $filename"
        rsync -a "$file" "$DEST_DIR/"
    fi
done
