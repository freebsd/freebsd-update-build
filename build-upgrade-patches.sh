#!/bin/sh

if [ $# -lt 3 ]; then
	echo "usage: $0 ARCH TARGETREL OLDRELS"
	exit 1
fi

while [ $(ls -d ${TMPDIR:-/tmp}/genpatch* 2>/dev/null | wc -l) -gt 0 ]; do
	echo "There appears to be evidence from previous runs in ${TMPDIR:-/tmp}/genpatch*...bailing"
	exit 1
done

BASEDIR=/usr/freebsd-update-server
ARCH=$1
TARGETREL=$2
OLDRELS=$3

WWWDIR=${BASEDIR}/pub

MAXJOBS=$(( $(sysctl -n hw.ncpu) - 2 ))
if [ $MAXJOBS -lt 1 ]; then
	MAXJOBS=1
fi

genpatch() {
	tempdir=$(mktemp -d -t genpatch)

	gunzip < ${WWWDIR}/${OR}/${ARCH}/f/${OH}.gz > ${tempdir}/${OH}
	gunzip < ${WWWDIR}/${NR}/${ARCH}/f/${NH}.gz > ${tempdir}/${NH}
	bsdiff ${tempdir}/${OH} ${tempdir}/${NH} ${tempdir}/${OH}-${NH}
	if [ $? -eq 0 ]; then
		mv ${tempdir}/${OH}-${NH} ${WWWDIR}/to-${TARGETREL}/${ARCH}/bp/${OH}-${NH}
	else
		echo "Error generating patch ${OH}-${NH}, removing"
		rm ${tempdir}/${OH}-${NH}
	fi

	rm ${tempdir}/${OH} ${tempdir}/${NH}
	rmdir ${tempdir}
}

echo -n "Building hash table..."
mkdir -p ${WWWDIR}/to-${TARGETREL}/${ARCH}/bp/
for V in ${OLDRELS}; do
	zcat ${WWWDIR}/${V}/${ARCH}/m/* |
	    cut -f 3,4,9 -d '|' |
	    fgrep '|f|' |
	    cut -f 1,3 -d '|' |
	    sort -u |
	    grep -E '\|[0-9a-f]{64}' |
	    lam -s "${V}|" -
done |
    sort -k 2,2 -t '|' > hashtab
echo "done"

echo "Starting patch generation"
marker=
zcat ${WWWDIR}/${TARGETREL}/${ARCH}/m/* |
    cut -f 3,4,9 -d '|' |
    fgrep '|f|' |
    cut -f 1,3 -d '|' |
    sort -u |
    grep -E '\|[0-9a-f]{64}' |
    lam -s "${TARGETREL}|" - |
    sort -k 2,2 -t '|' |
    join -1 2 -2 2 -t '|' hashtab - |
    cut -f 2- -d '|' |
    sort -k 2,2 -t '|' |
    tr '|' ' ' |
    while read OR OH NR NH; do
	if [ "$(echo ${OH} | cut -c1)" != "$marker" ]; then
		echo "  working on $(echo ${OH} | cut -c1-4)...."
		marker="$(echo ${OH} | cut -c1)"
	fi

	if [ -f ${WWWDIR}/to-${TARGETREL}/${ARCH}/bp/${OH}-${NH} ]; then
		continue
	fi
	if [ ${OH} = ${NH} ]; then
		continue
	fi

	genpatch &

	jobs="$(jobs)"
	numjobs=$(echo "$jobs" | wc -l)
	while [ $numjobs -ge $MAXJOBS ]; do
		sleep 2

		jobs="$(jobs)"
		numjobs=$(echo "$jobs" | wc -l)
	done
    done

echo -n "Finished spawning children, waiting for them to finish..."
while [ $(ls -d ${TMPDIR:-/tmp}/genpatch* 2>/dev/null | wc -l) -gt 0 ]; do
	sleep 2
done
echo "done"
rm hashtab
