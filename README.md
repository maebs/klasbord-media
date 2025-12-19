
# klasbord-media
Download the media from Klasbord Ouderapp in semi-automated way

**Background**
I needed to download the photos and videos from the Klasbord Ouderapp that the school of my kid is using. The app does not have the 'Download all' button (or maybe it is disabled), so downloading the images one-by-one is a tedious work. Yes, granted, if I am do it everytime the teacher posted anything, it wouldn't be a hassle, but you know, we are weak to the 'I'll do it later' excuse.


# ADB Media Downloader Script

This script automates downloading (pull) images and videos from an Android device using ADB, then renames and annotates the files locally.

It is designed for manual, supervised use where media is browsed on the device and downloaded one item at a time via UI automation.

## What this script does

-   Connects to an Android device via ADB
    
-   Taps the download button on the device screen
    
-   Swipes through media items in sequence
    
-   Detects newly downloaded files in:
    
    -   /sdcard/Pictures
        
    -   /sdcard/Movies
        
-   Pulls new files to the local machine
    
-   Verifies file integrity before deleting them from the device
    
-   Renames files using a consistent naming scheme
    
-   Adds EXIF metadata to JPEG images
    
-   Handles filenames with spaces and parentheses safely
    
-   Announces completion using text-to-speech on macOS
    

## Naming scheme

Downloaded files are renamed to:

presetString_YYYY-MM-DD_XXX.ext

Where:

-   YYYY-MM-DD is the entry date
    
-   XXX is a zero-padded counter based on the media index
    
-   ext is the original file extension
    

Example:

AB3_Klasbord_2025-08-29_001.jpg  
AB3_Klasbord_2025-08-29_002.mp4

## Metadata added (JPEG only)

For JPEG files, the script writes the following metadata using exiftool:

-   DateTimeOriginal
-   CreateDate
-   ModifyDate
    
-   Description
    
-   UserComment
    
-   ImageDescription
    
-   Keywords: add these to your liking
        

Videos are not modified but are still renamed and tracked.

## Requirements

Local machine:

-   macOS (BSD date is assumed)
    
-   bash
    
-   adb
    
-   exiftool
    

Android device: (phone used is S25Ultra)

-   USB debugging enabled
    
-   Media downloads saved to /sdcard/Pictures or /sdcard/Movies
    

## Usage

1.  Connect your Android device via USB
    
2.  Ensure adb can see the device:
    
    adb devices
    
3.  Start the script:
    
    ./script.sh
    
4.  When prompted:
    
    -   Enter a title for the entry
        
    -   Enter a date in dd-MM-YYYY format
        
5.  The script will:
    
    -   Download each media item
        
    -   Pull it locally
        
    -   Rename and process it
        
    -   Swipe to the next item
        
6.  When finished, the script will say "Download done" and reset for the next entry
    

Press Ctrl+C to exit safely at any time.

## Configuration

Screen interaction coordinates are defined at the top of the script:

    DOWNLOAD_X / DOWNLOAD_Y
    
    SWIPE_START_X / SWIPE_END_X / SWIPE_Y

    

These values are device-specific and must be calibrated using `adb getevent`.

Timing can be adjusted via:

    IMAGE_LOAD_WAIT

    DOWNLOAD_WAIT

    

## Safety features

-   `set -euo pipefail` enabled
    
-   Temporary files cleaned via `trap`
    
-   File size stabilization check for videos
    
-   No deletion without successful pull
    
-   New file detection based on directory diffs
    

## Known limitations

-   Relies on UI text counter being present and accurate
    
-   Assumes ascending media index
    
-   Does not handle HEIC metadata
    
-   Requires manual calibration if the app UI changes
    
## Tip
You might want to clean out your `/sdcard/Pictures` and `/sdcard/Movies` first. Rename these folders it to something else, your device will still recognize them in Albums.

## License

Internal use. No warranty.


