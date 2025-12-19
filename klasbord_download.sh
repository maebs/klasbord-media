#!/bin/bash

## if you need to determine the coordinats, use this command. 1 to enable it, 0 to disable.
## adb shell settings put system pointer_location 1  
## adb shell settings put system pointer_location 0   

clear
set -euo pipefail
IFS=$'\n\t'

DOWNLOAD_X=1313
DOWNLOAD_Y=216

SWIPE_START_X=1200
SWIPE_END_X=200
SWIPE_Y=1000

IMAGE_LOAD_WAIT=2
DOWNLOAD_WAIT=1
MAX_ITERATIONS=500

clear
trap 'rm -f before_pictures.txt after_pictures.txt before_movies.txt after_movies.txt' EXIT

systemYear=$(date "+%Y")

while true; do
  read -rp "Enter title for this entry: " currentEntryTitle

  # Prompt for date with default year
  while true; do
    read -rp "Enter day and month (dd-MM) for ${systemYear}: " dm
    currentEntryDate="${dm}-${systemYear}"

    if [[ "$currentEntryDate" =~ ^[0-3][0-9]-[0-1][0-9]-[0-9]{4}$ ]]; then
      break
    else
      echo "Invalid format. Try again."
    fi
  done

  while true; do
  read -rp "Pausing. Now open the post's first image. Press Y to continue: " answer
  case "$answer" in
    [Yy]) break ;;
    *) echo "Invalid input. Please type Y to continue." ;;
  esac
  done

  currentEntryDateExif=$(date -j -f "%d-%m-%Y" "$currentEntryDate" "+%Y:%m:%d")
  currentEntryDateFile=$(date -j -f "%d-%m-%Y" "$currentEntryDate" "+%Y-%m-%d")

  totalDownloaded=0
  iteration=0
  fileList=()

  adb shell ls -t /sdcard/Pictures > before_pictures.txt
  adb shell ls -t /sdcard/Movies   > before_movies.txt
  sort before_pictures.txt -o before_pictures.txt
  sort before_movies.txt -o before_movies.txt

  while true; do
    iteration=$((iteration+1))
    if [ "$iteration" -gt "$MAX_ITERATIONS" ]; then
      echo "Max iterations reached. Aborting loop."
      break
    fi

    adb shell uiautomator dump /sdcard/screen.xml >/dev/null
    adb pull /sdcard/screen.xml >/dev/null

    COUNTER=$(grep -o 'text="[0-9]\+/[0-9]\+"' screen.xml | head -n1 | cut -d'"' -f2 || echo "")
    [ -z "$COUNTER" ] && break

    CURRENT=${COUNTER%/*}
    TOTAL=${COUNTER#*/}

    echo "Image $CURRENT of $TOTAL"

    adb shell input tap $DOWNLOAD_X $DOWNLOAD_Y
    sleep $DOWNLOAD_WAIT

    adb shell ls -t /sdcard/Pictures > after_pictures.txt
    adb shell ls -t /sdcard/Movies   > after_movies.txt
    sort after_pictures.txt -o after_pictures.txt
    sort after_movies.txt   -o after_movies.txt

    newPictures=$(comm -13 before_pictures.txt after_pictures.txt || true)
    newMovies=$(comm -13 before_movies.txt after_movies.txt || true)

    for source in Pictures Movies; do
      eval "newFiles=\$new${source}"

      while IFS= read -r f; do
        if [ "$source" = "Movies" ]; then
          prevSize=0
          for i in {1..10}; do
            size=$(adb shell stat -c %s "/sdcard/${source}/$f" 2>/dev/null || echo 0)
            [ "$size" -gt 0 ] && [ "$size" -eq "$prevSize" ] && break
            prevSize="$size"
            sleep 1
          done
        fi

        adb pull "/sdcard/${source}/$f" . || continue

        if [ -f "$f" ] && [ -s "$f" ]; then
          adb shell rm "/sdcard/${source}/$f"
          counterPadded=$(printf "%03d" "$CURRENT")
          extension="${f##*.}"

          ## Modify this to your liking
          newName="Klasbord_${currentEntryDateFile}_${counterPadded}.${extension}"
          mv "$f" "$newName"

          if [[ "$extension" =~ ^jpe?g$ ]]; then
            exiftool -overwrite_original \
              -DateTimeOriginal="$currentEntryDateExif 12:00:00" \
              -CreateDate="$currentEntryDateExif 12:00:00" \
              -ModifyDate="$currentEntryDateExif 12:00:00" \
              -Description="$currentEntryTitle" \
              -UserComment="$currentEntryTitle" \
              -ImageDescription="$currentEntryTitle" \
              -Keywords="MF3" \
              -Keywords="Montessori Beverwijk" \
              -Keywords="$systemYear" \
              -Keywords="$currentEntryTitle" \
              "$newName" >/dev/null
          fi

          fileList+=("$newName")
          totalDownloaded=$((totalDownloaded+1))
        fi
      done <<< "$newFiles"
    done

    cp after_pictures.txt before_pictures.txt
    cp after_movies.txt   before_movies.txt

    if [ "$CURRENT" -ge "$TOTAL" ]; then
      echo "Entry download complete. $totalDownloaded files processed."
      say "Download done!"
      break
    fi

    ## swipe RTL for the next image.
    adb shell input swipe $SWIPE_START_X $SWIPE_Y $SWIPE_END_X $SWIPE_Y 300
    sleep $IMAGE_LOAD_WAIT
  done

  ## hit the close button
  adb shell input tap 125 290
  clear
done
