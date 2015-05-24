#!/bin/sh
#ver.1

A=$1
GW=$2
CLT=$3

ip_fwd() {
	echo "Turn $1 packet forwarding"

	case $1 in
		on)
			_x=1
			;;
		off)
			_x=0
			;;
	esac

	echo $_x > /proc/sys/net/ipv4/ip_forward
}

if [ "$A" == "start" ] ;
then
	ip_fwd on

	echo "Setting up NAT rules for $GW/$CLT"

	iptables -t nat -A POSTROUTING -o $GW -j MASQUERADE
	iptables -A FORWARD -i $CLT -o $GW -j ACCEPT
	iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
elif [ "$A" == "stop" ] ;
then
	iptables -F nat
	echo "Flushing out NAT rules"
	ip_fwd off
else
	echo -ne "usage: $0 start dev_gateway client_ip\nestablish bridge between remote peer client_ip and Internet\n"
	echo -ne "\twhere dev_gateway is a network device connected to internet\n"
	echo -ne "\tclient_ip IP address of the host which must be connected to the Internet via dev_gateway\n"
	echo -ne "\texample: $0 start wlan0 192.168.1.2\nconnect remote peer 192.168.1.2 to the Internet via local device wlan0\n"
	echo -ne "$0 stop\nshut down previously established bridge between remote peer and Internet\n"
fi
