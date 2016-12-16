#!/bin/bash

rm -f *.log
rm -f *.hlt

if [[ $# -lt "2" ]]; then
	echo "usage: ./fight.sh <bot1> <bot2> [<bot3>...]"
	exit 1
fi
export BOTS=$@

#../halite -d "30 30" "ruby jc03.rb" "ruby jc05.rb"
export CMD='../halite -q -d "30 30"'
for BOT in ${BOTS}; do
	CMD="${CMD} 'ruby ${BOT}.rb'"
done
echo $CMD
eval $CMD

if [[ -d ~/00_VM_SHARE/ ]]; then
	rm -f ~/00_VM_SHARE/*.hlt
	cp *.hlt ~/00_VM_SHARE/.
fi
