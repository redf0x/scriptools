#!/bin/sh
#ver.1

IFS=$'\n'

K_NUMBERS=()
K_VERSIONS=()
K_RAWINPUT=$(eselect kernel list)

echo "> found kernels: ${K_RAWINPUT[@]}"

for i in ${K_RAWINPUT[@]}; do
	echo $i
	tmp=${i##*[}

	if [ -n "$tmp" ];
	then
		K_NUMBERS=("${K_NUMBERS[@]}" "${tmp%]*}")
		K_VERSIONS=("${K_VERSIONS[@]}" "${i##*linux-}")
	fi
done

i=1

while [ $i -lt ${#K_NUMBERS[@]} ]; do
	echo "> building modules for ${K_NUMBERS[$i]}/${K_VERSIONS[$i]}"
	eselect kernel set ${K_NUMBERS[$i]}
	emerge @module-rebuild

	if [ ! -f "/lib/modules/${K_VERSIONS[$i]}/build/System.map" ];
	then
		echo "> running depmod for ${K_VERSIONS[$i]}"
		depmod -v ${K_VERSIONS[$i]}
	fi

	true $(( i++ ))
done
