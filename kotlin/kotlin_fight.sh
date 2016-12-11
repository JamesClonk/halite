#!/bin/bash

rm -f *.log
rm -f *.hlt
rm -f *.jar
javac *.java
export CLASSPATH=$CLASSPATH:"."

if [[ $# -lt "2" ]]; then
	echo "usage: ./fight.sh <bot1> <bot2> [<bot3>...]"
	exit 1
fi
export BOTS=$@

#../halite -d "30 30" "java -jar MyBot.jar" "java -jar RandomBot.jar"
export CMD='../halite -q -d "30 30"'
for BOT in ${BOTS}; do
	kotlinc ${BOT}.kt -include-runtime -d ${BOT}.jar
	CMD="${CMD} 'java -jar ${BOT}.jar'"
done
echo $CMD
eval $CMD
