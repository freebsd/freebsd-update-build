#!/bin/sh

export TZ=UTC
now=$(date +%s)

cd /usr/freebsd-update-server || exit 1
find scripts -type f -name build.conf | while read conf ; do
	rel=$(expr "$conf" : 'scripts/\([0-9][0-9]*\.[0-9][0-9]*-[A-Z0-9-]*\)/.*')
	eol=$(. $conf ; echo $EOL)
	expr "$eol" : '[0-9][0-9]*' >/dev/null || continue
	[ $eol -gt $now ] || continue
	p=$(find patches/"$rel" -type f | cut -d/ -f3- | cut -d- -f1 | sort -n | tail -1)
	echo $(date -j -r $eol +'%Y-%m-%d %H:%M:%S UTC') "$rel${p:+-p$p}"
done | sort -t" " -k4 -rn
