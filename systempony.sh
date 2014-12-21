#!/bin/bash

PONY=fluttershy
INFO=( User Hostname Distro Kernel Uptime Shell Packages RAM Disk )

function ponyget_Shell()
{
	grep $USER /etc/passwd | cut -f7 -d:
}

function ponyget_User()
{
	whoami
}

function ponyget_Distro()
{
	lsb_release -isr | paste "-d " - -
}


function ponyget_RAM()
{
	local ramtable=$(free -h)
	local used=$(echo "$ramtable" | sed -n 3p | sed -r "s/ +/\t/g"  | cut -f 3)
	local total=$(echo "$ramtable" | sed -n 2p | sed -r "s/ +/\t/g"  | cut -f 2)
	
	local ramtable=$(free -m)
	local used_M=$(echo "$ramtable" | sed -n 3p | sed -r "s/ +/\t/g"  | cut -f 3)
	local total_M=$(echo "$ramtable" | sed -n 2p | sed -r "s/ +/\t/g"  | cut -f 2)
	local percent=$(echo "$used_M * 100 / $total_M " | bc)
	
	local color="32";
	if [ "$percent" -gt 66 ]
	then
		color="31"
	elif [ "$percent" -gt 33 ]
	then
		color="33"
	fi
	
	echo -e "\x1b[$color;1m$used\x1b[0m / $total"
}

function ponyget_Kernel()
{
	uname -r -m
}

function ponyget_Hostname()
{
	hostname
}

function ponyget_CPU()
{
	cat /proc/cpuinfo | grep "model name" | head -n 1 | sed -r "s/model name\s: //"
}

function ponyget_Uptime()
{
	uptime | grep -oE "up\s+[^,]+" | sed -r "s/up\s+//"
}

function ponyget_Packages()
{
	if which dpkg &>/dev/null
	then
		dpkg --get-selections | grep -v deinstall | wc -l
	elif which rpm &>/dev/null
	then
		rpm -qa | wc -l
	elif which pacman &>/dev/null
	then
		pacman -Q | wc -l
	fi 
}

function ponyget_Disk()
{
	local diskusage=$(df -lh --total | tail -n 1 | sed -r "s/ +/\t/g" )
	local used=$(echo "$diskusage" | cut -f 3)
	local total=$(echo "$diskusage" | cut -f 2)
	local percent=$(echo "$diskusage"  | cut -f 5 | sed s/%// )
	
	local color="32";
	if [ "$percent" -gt 66 ]
	then
		color="31"
	elif [ "$percent" -gt 33 ]
	then
		color="33"
	fi
	
	echo -e "\x1b[$color;1m$used\x1b[0m / $total"
}

function bold()
{
	echo -en "\x1b[1m${*}\x1b[22m"
}

function underline()
{
	echo -en "\x1b[4m${*}\x1b[24m"
}

function title()
{
	echo
	bold ${*}
	echo
}

function help()
{
	title NAME
	echo -e "\t$(bold $0) - show a pony and some system information"
	
	title SYNOPSIS
	echo -e "\t$(bold $0) [$(bold --pony) $(underline pony)|$(bold -p=)$(underline pony)] [$(bold --info) $(underline id)|$(bold -i=)$(underline id)...]"
	echo -e "\t$(bold $0) $(bold help)|$(bold --help)|$(bold -h)"
	
	title OPTIONS
	echo -e "\t$(bold --pony) $(underline pony), $(bold -p=)$(underline pony)"
	echo -e "\t\tSelect a pony (default: $PONY)."
	echo
	echo -e "\t$(bold --info) $(underline id), $(bold -i=)$(underline id)"
	echo -e "\t\tShow the given info (default: ${INFO[@]})."
	echo -e "\t\tThis option supports multiples IDs separated by commas, spaces or colons."
	echo -e "\t\tAvailable IDs:"
	declare -F | grep ponyget_ | sed "s/declare -f ponyget_/\t\t * /"	
	echo
	
}

function select_info()
{
	INFO=($(echo "${*}" | column -t -s:,))
}

# TODO read global and user config file
while [ "$1" ]
do
	case "$1" in
		--help|-h|help)
			help
			exit 0
			;;
		--pony)
			shift
			PONY=$1
			;;
		-p=*)
			PONY=$(echo "$1" | sed "s/-p=//")
			;;
		--info)
			infostring=""
			while [ "$2" ] && ! echo "$2" | grep -q -e "-"
			do
				infostring="$infostring $2"
				shift
			done
			select_info $infostring
			;;
		-i=*)
			select_info "$(echo "$1" | sed "s/-i=//")"
			;;
	esac
	shift
done

infoval=()
let maxkeyl=0
let maxvall=0
function addinfo()
{
	infoval+=("${2}")
	local keyl=$(echo "$1" | wc -c)
	local vall=$(echo "${2}" | wc -c)
	[ $keyl -gt $maxkeyl ] && maxkeyl=$keyl;
	[ $vall -gt $maxvall ] && maxvall=$vall;
}
for info in ${INFO[*]}
do
	if [ "$(type -t ponyget_${info})" = "function" ]
	then
		addinfo $info "$(ponyget_${info})"
	else
		addinfo $info "unsupported"
	fi
done

SELFDIR=$(dirname $(readlink -se "${BASH_SOURCE[0]}"))
ponydir="$SELFDIR/rendered/ansi/"
[ ! -d "$ponydir" ] && ponydir="$SELFDIR/../share/systempony/rendered/ansi/"
ponyfile="$ponydir/$PONY.colored.txt"

if [ -f "$ponyfile" ]
then
	lines=$(cat "$ponyfile" | wc -l) # cat to avoid printing file name
	let info_index=0
	let start_line=($lines-${#INFO[@]})/2
	for (( l=1; $l <= $lines; l++ ))
	do
		line=$(sed -n "$l{p;q}" "$ponyfile" )
		echo -n "$line"
		if [ $info_index -lt ${#INFO[@]} -a $l -ge $start_line ]
		then
			# TODO take in consideration $COLUMNS
			printf " \x1b[31;1m%-${maxkeyl}s\x1b[0m: %s" "${INFO[$info_index]}" "${infoval[$info_index]}"
			let info_index++
		else
			echo -ne "\x1b[0m"
		fi
		echo
	done
fi

