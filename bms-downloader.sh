#!/bin/bash

work_folder="$HOME/tmp/bms-downloader/work"
out_folder="$HOME/Games/BMS/Songs/downloaded"

cookies_path="$work_folder/cookies.txt"

######

cmd_exists() {
	return command -v "$1" 2>&1 >/dev/null
}

# from https://gist.github.com/iamtekeste/3cdfd0366ebfd2c0d805#gistcomment-2359248
function gdrive_prepare () {
	if ! echo "$1" | grep 'drive.google.com/file/d/'; then
		echo Unsupported Google link
		exit 1
	fi
	id="$(echo "$1" | cut -d'/' -f6)"
	confirm=$(wget --quiet --save-cookies "$cookies_path" --keep-session-cookies --no-check-certificate "https://docs.google.com/uc?export=download&id=$id" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')

	link="https://docs.google.com/uc?export=download&confirm=$confirm&id=$id"
	out=gdrive.zip
}

link="$1"

if [ "$link" = '' ]; then
	echo No link given, trying to fetch from clipboard
	if cmd_exists xclip; then
		link="$(xclip -o)"
	elif cmd_exists wl-paste; then
		link="$(wl-paste)"
	else
		echo Could not fetch clipboard
		exit 1
	fi
fi

link="$(echo "$link" | sed 's/dl=0/dl=1/')"

out="$(basename "$link")"
out="$(echo "$out" | cut -d'?' -f1)"

mkdir -p "$work_folder"
mkdir -p "$out_folder"

cd "$work_folder"

if echo "$link" | grep '1drv.ms'; then
	echo 'BMS Downloader does not work with OneDrive (yet? submit a PR if you want to do it)'
	exit 1
fi

if echo "$link" | grep google; then
	gdrive_prepare "$1"
fi

echo Downloading from: $link
wget --load-cookies "$cookies_path" "$link" -O "$out"

echo Output: $out

unzip -O shift-jis "$out" -d zip
rm "$out"

guessed_file="$(find zip | grep -E -- '\.(bms|bme|bml|bmson|ogg|mpg|wav)$' | head -n 1)"

if [ "$guessed_file" = '' ]; then
	echo Could not find any BMS related file in archive
	exit 1
fi

guessed_dir="$(dirname "$guessed_file")"

echo Guessed BMS file: $guessed_file
echo Guessed BMS dir: $guessed_dir

mv -nu "$guessed_dir" "$out_folder"

rm -rf zip

echo Done
