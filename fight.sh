#!/bin/bash

export GOPATH="$(pwd)"

rm -f *.log
rm -f *.hlt

if [[ $# -lt "2" ]]; then
	echo "usage: ./fight.sh <bot1> <bot2> [<bot3>...]"
	exit 1
fi
export BOTS=$@

#./halite -d "30 30" "go run jc02/main.go" "go run jc03/main.go" "go run jc04/main.go"
export CMD='./halite -q -d "30 30"'
for BOT in ${BOTS}; do
	CMD="${CMD} 'go run ${BOT}/main.go'"
done
echo $CMD
eval $CMD
