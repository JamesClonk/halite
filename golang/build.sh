#!/bin/bash

if [[ -z "$1" ]]; then
	echo "usage: ./build.sh <directory>"
	exit 1
fi

rm -rf output/*
mkdir -p output/src/hlt
cp -R src/hlt/* output/src/hlt/.
cp $1/*.go output/.
cp install.sh output/.
chmod +x output/install.sh

pushd output
mv main.go MyBot.go
./install.sh
if [[ $? -ne "0" ]]; then
	echo 'ERROR!'
	exit 1
fi
rm MyBot
zip MyBot *
zip MyBot */*/*
popd

exit 0
