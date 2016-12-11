#!/bin/bash

rm -f *.log
rm -f *.hlt
javac *.java
export CLASSPATH=$CLASSPATH:"."

if [[ $# -lt "2" ]]; then
	echo "usage: ./fight.sh <bot1> <bot2> [<bot3>...]"
	exit 1
fi
export BOTS=$@

#../halite -d "30 30" "java MyBot" "java RandomBot"
export CMD='../halite -q -d "30 30"'
for BOT in ${BOTS}; do
	CMD="${CMD} 'java ${BOT}'"
done
echo $CMD
eval $CMD
