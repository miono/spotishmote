#!/bin/bash
#
# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <markus.nilsson@gmail.com> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return. Markus Nilsson
# ----------------------------------------------------------------------------
# spotishmote.sh written by Markus Nilsson, miono@IRCnet
# Bugs, Requests etc: markus.nilsson [AltGr+2] gmail.com
# Version 0.2

# Change these variables if it's not working for you. (Use mdbus2 to find out your values)
DEST='org.mpris.MediaPlayer2.spotify'
OBJECT_PATH='/'
NAME_PART_1='org.freedesktop.MediaPlayer2.'

# Check if Spotify is running
SPOTIFYPID=$(pidof spotify)
if [[ $SPOTIFYPID == ''  ]]; then
	echo "Spotify isn't running"
	exit 1
fi

SPOTIFYUID=$(grep Uid /proc/$SPOTIFYPID/status | awk '{print $2}')
SCRIPTUID=$(id -u)

if [[ $SPOTIFYUID != $SCRIPTUID ]]; then
	echo "You must execute spotishmote.sh as the same user as Spotify"
	exit 1
fi

uri_open () {
		NAME_PART_2='OpenUri'
		URI=$1
		dbus-send --print-reply --dest=$DEST $OBJECT_PATH ${NAME_PART_1}${NAME_PART_2} string:$URI &> /dev/null
		exit 0
	
}

song_info () {
	NAME_PART_2='GetMetadata'
	INFO=$(dbus-send --print-reply --dest=$DEST $OBJECT_PATH ${NAME_PART_1}${NAME_PART_2})
	ARTIST=$(echo "$INFO" | grep -A2 xesam:artist | tail -n1 | sed -e 's/[^"]*"//' -e 's/"$//')
	TITLE=$(echo "$INFO" | grep -A1 xesam:title | tail -n1 | sed -e 's/[^"]*"//' -e 's/"$//')
	ALBUM=$(echo "$INFO" | grep -A1 xesam:album | tail -n1 | sed -e 's/[^"]*"//' -e 's/"$//')
	YEAR=$(echo "$INFO" | grep -A1 xesam:contentCreated | tail -n1 | sed -e 's/[^"]*"//' -e 's/-.*$//')
	SPOTIFY_ID=$(echo "$INFO" | grep -A1 xesam:url | tail -n1 | sed -e 's/[^"]*"//' -e 's/"$//')
	if [[ $TITLE == '' ]]; then
		echo "No song is playing"
		exit 0
	fi
	echo "$ARTIST - $TITLE"
	echo "($ALBUM, $YEAR)"
	echo $SPOTIFY_ID
}

case $1 in
	toggle|t)
		NAME_PART_2='PlayPause'
		dbus-send --print-reply --dest=$DEST $OBJECT_PATH ${NAME_PART_1}${NAME_PART_2} &> /dev/null
		song_info
		exit 0
	;;
	play)
		NAME_PART_2='Play'
		dbus-send --print-reply --dest=$DEST $OBJECT_PATH ${NAME_PART_1}${NAME_PART_2} &> /dev/null
		song_info
		exit 0
	;;
	pause)
		NAME_PART_2='Pause'
		dbus-send --print-reply --dest=$DEST $OBJECT_PATH ${NAME_PART_1}${NAME_PART_2} &> /dev/null
		song_info
		exit 0
	;;
	next|n)
		NAME_PART_2='Next'
		dbus-send --print-reply --dest=$DEST $OBJECT_PATH ${NAME_PART_1}${NAME_PART_2} &> /dev/null
		song_info
		exit 0
	;;
	prev|p)
		NAME_PART_2='Previous'
		dbus-send --print-reply --dest=$DEST $OBJECT_PATH ${NAME_PART_1}${NAME_PART_2} &> /dev/null
		song_info
		exit 0
	;;
	spotify*)
		uri_open $1
	;;
	info|i)
		song_info
		exit 0
	;;
	x)
		ONE=$(xclip -o | head -n1 | sed -re 's#(http://open\.|\.com)##g;s#/#:#g')
		TWO=$(xclip -o -selection clipboard | head -n1 | sed -re 's#(http://open\.|\.com)##g;s#/#:#g')

		if [[ $ONE == spotify:* ]]; then
			uri_open $ONE	
		elif [[ $TWO == spotify:* ]]; then
			uri_open $TWO	
		fi

		exit 1
	;;
	help|h|*)
		echo 'Usage: spotishmote <command/uri>
  Available commands:
  help/h - Display this help
  play/pause/t - Toggle between play/pause
  next/n - Next song
  prev/p - Previous song
  info/i - Show info about current song
  <uri> - Play the entered URI (must be valid URI)'
  		if [[ "$1" == 'h' || "$1" == 'help' ]]; then
			exit 0
		else	
			exit 1
		fi
	;;
esac
