#!/bin/bash

rm -f *.log
rm -f *.hlt

if [[ $# -lt "2" ]]; then
	echo "usage: ./fight.sh <bot1> <bot2> [<bot3>...]"
	exit 1
fi
export BOTS=$@

cargo build
#../halite -d "30 30" "target/debug/MyBot" "target/debug/RandomBot"
export CMD='../halite -q -d "30 30"'
for BOT in ${BOTS}; do
	CMD="${CMD} 'target/debug/${BOT}'"
done
echo $CMD
eval $CMD
