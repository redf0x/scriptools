#!/bin/sh
#ver.1

CPU_ROOT=/sys/devices/system/cpu

freq_max() {
	echo -ne $(cat $CPU_ROOT/cpu$1/cpufreq/cpuinfo_max_freq)
}

freq_min() {
	echo -ne $(cat $CPU_ROOT/cpu$1/cpufreq/cpuinfo_min_freq)
}

freq_curr() {
	echo -ne $(cat $CPU_ROOT/cpu$1/cpufreq/cpuinfo_cur_freq)
}

sfreq_max() {
	echo -ne $(cat $CPU_ROOT/cpu$1/cpufreq/scaling_max_freq)
}

sfreq_min() {
	echo -ne $(cat $CPU_ROOT/cpu$1/cpufreq/scaling_min_freq)
}

pstate_max_pct() {
	echo -ne $(cat $CPU_ROOT/intel_pstate/max_perf_pct)
}

pstate_min_pct() {
	echo -ne $(cat $CPU_ROOT/intel_pstate/min_perf_pct)
}

pstate_turbo() {
	echo -ne $(cat $CPU_ROOT/intel_pstate/no_turbo)
}

scaling_governor() {
	echo -ne $(cat $CPU_ROOT/cpu$1/cpufreq/scaling_governor)
}

dump_freq_curr() {
	echo "current frequency" $(freq_curr $1)
}

dump_freq_max() {
	echo "frequency, max" $(freq_max $1)
}

dump_freq_min() {
	echo "frequency, min" $(freq_min $1)
}

dump_sfreq_max() {
	echo "scaling frequency, max" $(sfreq_max $1)
}

dump_sfreq_min() {
	echo "scaling frequency, min" $(sfreq_min $1)
}

dump_pstate_max_pct() {
	echo "max perf percentage" $(pstate_max_pct)
}

dump_pstate_min_pct() {
	echo "min perf percentage" $(pstate_min_pct)
}

dump_pstate_turbo() {
	echo "turbo boost switch off" $(pstate_turbo)
}

dump_scaling_governor() {
	echo "scaling governor" $(scaling_governor $1)
}

dump_all() {
	echo "cpu $1"
	echo -ne "  "; dump_freq_curr $1
	echo -ne "  "; dump_freq_max $1
	echo -ne "  "; dump_freq_min $1
	echo -ne "  "; dump_sfreq_max $1
	echo -ne "  "; dump_sfreq_min $1
	echo -ne "  "; dump_scaling_governor $1
}

set_governor() {
	echo -ne $1 > $CPU_ROOT/cpu$2/cpufreq/scaling_governor
}

for_each_cpu() {
	i=0

	for x in $CPU_ROOT/cpu? ;
	do
		echo -ne "$i: "; eval $* $i
		i=$((i+1))
	done
}

if [ -z $1 ];	# require at least 1 arg
then
	# teh end
	cat << EOF
usage:
$0 <verb> [object]

or

$0 query [pstate [max_perf | min_perf | turbo]] | [[freq_max | freq_cur | freq_min | sfreq_max | sfreq_min | governor] [cpu#]]
$0 set governor <governor_name> [cpu#] | (max_perf | min_perf) <percentage> | no_turbo <0 | 1>

where:
<exp> mandatory expression/argument
[exp] facultative expression/argument

verbs:
query - query all or any of the values associated with cpu#/cpus
set - set tunable values associated with cpu#/cpus

objects:
self-explanatory
EOF
	exit 0
fi

if [ $1 == "query" ];
then
	if [ -z $2 ];
	then
		for_each_cpu dump_all
		[ ! -d $CPU_ROOT/intel_pstate ] && exit 0
		dump_pstate_max_pct
		dump_pstate_min_pct
		dump_pstate_turbo
	else
		( [ $# -eq 1 -o "$2" -eq "$2" ] 2>/dev/null ) && dump_all $2 && exit 0

		if [ $2 == "pstate" ];
		then
			if [ ! -d $CPU_ROOT/intel_pstate ];
			then
				echo "intel_pstate driver is currently unavailable on this system" && exit 1
			fi

			if [ -z $3 ];
                	then
				dump_pstate_max_pct
				dump_pstate_min_pct
				dump_pstate_turbo
			else
				case $3 in
					max_perf)
						dump_pstate_max_pct
						;;

					min_perf)
						dump_pstate_min_pct
						;;

					turbo)
						dump_pstate_turbo
						;;
					*)
				esac
			fi

			exit 0
		fi

		case $2 in
			freq_max)
				[ -z $3 ] && for_each_cpu dump_freq_max || dump_freq_max $3
				;;

			freq_cur)
				[ -z $3 ] && for_each_cpu dump_freq_curr || dump_freq_curr $3
				;;

			freq_min)
				[ -z $3 ] && for_each_cpu dump_freq_min || dump_freq_min $3
				;;

			sfreq_max)
				[ -z $3 ] && for_each_cpu dump_sfreq_max || dump_sfreq_max $3
				;;

			sfreq_min)
				[ -z $3 ] && for_each_cpu dump_sfreq_min || dump_sfreq_min $3
				;;

			governor)
				[ -z $3 ] && for_each_cpu dump_scaling_governor || dump_scaling_governor $3
				;;
			*)
		esac
	fi
elif [  $1 == "set" ];
then
	if [ -z $2 ];
	then
		echo "missing required arg"
		exit 1
	else
		[ -z $3 ] && echo "missing required arg" && exit 1

		case $2 in
			governor)
				[ -z $4 ] && for_each_cpu set_governor $3 || set_governor $3 $4
				;;

			max_perf|min_perf|no_turbo)
				[ $2 == "no_turbo" ] && out=$2 || out=$2_pct
				echo $3 > $CPU_ROOT/intel_pstate/$out
				;;
		esac
	fi
fi
