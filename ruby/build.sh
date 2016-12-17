#!/bin/bash

if [[ -z "$1" ]]; then
	echo "usage: ./build.sh <bot>"
	exit 1
fi

rm -rf output/*
mkdir -p output
cp game_map.rb output/.
cp location.rb output/.
cp move.rb output/.
cp networking.rb output/.
cp site.rb output/.
cp $1.rb output/MyBot.rb

pushd output
zip MyBot *
popd

exit 0
