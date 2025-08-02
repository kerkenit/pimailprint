#!/bin/bash
# Parameters

BASEDIR=$(dirname $0)
CURDIR=$(pwd)
MAILDIR=./maildata
LOGFILE=/var/log/printmail.log
ATTACH_DIR=./attachments
# change directory
if [ -t 0 ]; then
	echo "Switching directory to : $BASEDIR"
fi
cd $BASEDIR
# create log file if it does not exist
touch $LOGFILE
date +%r-%-d/%-m/%-y >> $LOGFILE
# fetch mail
if [ -t 0 ]; then
	echo "Checking for new mail..."
fi
fetchmail -f ./fetchmail.conf -L $LOGFILE
# process new mails
shopt -s nullglob
for i in $MAILDIR/new/*
do
	echo "Processing : $i" | tee -a $LOGFILE
	uudeview $i -i -p $ATTACH_DIR/
	# process file attachments with space
	cd $ATTACH_DIR
	for e in ./*
	do
		mv "$e" "${e// /_}"
	done
	for f in *.PDF
	do
		mv $f ${f%.*}.pdf
	done
	cd $BASEDIR
	# end of patch
	echo "Printing PDFs" | tee -a $LOGFILE
	for x in $ATTACH_DIR/*.pdf
	do
		echo "Printing : $x" | tee -a $LOGFILE
		lpr $x
		echo "Deleting file : $x" | tee -a $LOGFILE
		rm $x | tee -a $LOGFILE
	done
	for f in $ATTACH_DIR/*.{doc,DOC,docx,DOCX}
        do
                libreoffice --headless --convert-to pdf $f #--outdir $ATTACH_DIR
                x=${f%.*}.pdf
                echo "Printing : $x" | tee -a $LOGFILE
                #lpr $x
                echo "Deleting file : $x" | tee -a $LOGFILE
                rm $x | tee -a $LOGFILE
        done
#	cd $ATTACH_DIR
	if [ -t 0 ]; then 
		echo "Skip removing of the attachments"
	else
		echo "Clean up and remove any other attachments"
		for y in $ATTACH_DIR/*
		do
			echo "Remove '$y'"
			#rm $y
		done
	fi

	# delete mail
	if [ -t 0 ]; then
		echo "Skip deleting mail: $i"
	else
		echo "Deleting mail: $i" | tee -a $LOGFILE
		rm $i | tee -a $LOGFILE
	fi
done
if [ -t 0 ]; then
	cd $ATTACH_DIR
	for f in *.{doc,DOC,docx,DOCX}
        do
                libreoffice --headless --convert-to pdf $f #--outdir $ATTACH_DIR
		x=${f%.*}.pdf
		echo "Printing : $x" | tee -a $LOGFILE
                /usr/bin/lpr $x
                echo "Deleting file : $x" | tee -a $LOGFILE
                rm $x | tee -a $LOGFILE
        done
	#for x in $ATTACH_DIR/*.pdf
        #do
        #        echo "Printing : $x" | tee -a $LOGFILE
        #        lpr $x
        #        echo "Deleting file : $x" | tee -a $LOGFILE
        #        rm $x | tee -a $LOGFILE
        #done
fi
shopt -u nullglob
echo "Job finished." | tee -a $LOGFILE
cd $CURDIR
