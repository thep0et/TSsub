#!/bin/bash
#===================================#
#        TSDuck Subscriber          #
#       Author:  Dan Dennis         #
#               V.1.1               #
#===================================#
##script should be executed with the following positional arguments CHE for WA and GIL for EA
##	EXAMPLE
##	/mnt/isilon/INSIGHT/SCRIPTS/bin/TSsub.sh CHE  
##		or
##  /mnt/isilon/INSIGHT/SCRIPTS/bin/TSsub.sh GIL 
  
#log=/mnt/isilon/INSIGHT/SCRIPTS/logs/TSublog.log  ###Logfile###
#channelDetails=/mnt/isilon/INSIGHT/SCRIPTS/bin/ChannelData.txt


##Logic to tell the script which arc to subscribe to based on passed arguments
if [[ $1 == "GIL" ]] ; then 
	channelDetails=/mnt/isilon/INSIGHT/SCRIPTS/bin/ChannelDataGil.txt ###Format <Name> <SSM> <GrouIP> <PID>###
	log=/mnt/isilon/INSIGHT/SCRIPTS/logs/TSublogGIL.log
	ARC="EA"
	elif [[ $1 == "CHE" ]] ; then
	channelDetails=/mnt/isilon/INSIGHT/SCRIPTS/bin/ChannelDataChe.txt ###Format <Name> <SSM> <GrouIP> <PID>###
	log=/mnt/isilon/INSIGHT/SCRIPTS/logs/TSublogCHE.log
	ARC="WA"
fi

datetime=$(date)
printf>&2 '%s\n' "$datetime - Starting Subscriber" > $log

###Create funtion to iterate through subscribtion list.  Takes 4 value Name=$1 SSM=$2 GrouIP:Port=$3 PID=$4###
multicastSub () {
	###Generate string to check for in running processes###
	psName="$2@$3 -P filter -p $4";
	###Check if an active subscribtion to the channel is already running###
	value=$(ps -ef | grep -c  "$psName")
	###If no active subscribtion is found, start a new one
	if [[ $value -lt 2 ]] ; then
		printf>&2 '%s\n' "Subscription for $1 with SSM $2, Group $3 and PID $4 not found, restarting." >> $log
		###watch for new lines and read through them.  Will expire after 86400 seconds (24 hours)
		while IFS= read -r -t 86400 cue; do
			###generate variable(s) to pass as argument to jq (mostly for human readable reasons)###
			NAME="$1";
			SOURCE="$2";
			###Use JQ JSON parser to add variable(s) and ship via UDP data packet###
			jq --arg name "$NAME" --arg arc "$ARC" --arg source "$SOURCE" '. += { 
				"channel_name": $name,
				"arc": $arc,
				"source_ssm": $source }' <<<"$cue" > /dev/udp/172.20.32.233/5100
			done < <(
			tsp -I ip --receive-timeout 86400000 $2@$3 -P filter -p $4 -P continuity -f --no-replicate-duplicated -p $4 -P splicemonitor -a --json-line='ServiceName' -s $4 -O drop 2>&1 | sed 's/^[^{]*{/{/g'
			) &  
			###The preceeding line generates a herefile to be read by line.  
			###SED command removes non-json tag at the beginning for processing.  
			###TSP command will timeout if no data is received for 24hours, at which point the script will restart it, so long as it is in the list of active channels.
			###This is to prevent old channel subscribtions from hanging around too long
			###Care should be taken if cue reciever is repurposed without a 24 window in between, as this script will continue to monitor it as the old channel name
			###TSDuck does not bind ports by default, only the PID needs to be unique.
	else
		printf>&2 '%s\n' "Subscription for $1 with SSM $2, Group $3 and PID $4 found to be running, skipping."  >> $log
	fi
}

### Execute funtion, reading in the channelDetails file, running each subscribtion in a subshell###
while read line; do
    multicastSub $line &
done < $channelDetails
