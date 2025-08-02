#!/bin/bash
# Parameters
lockfile=/var/tmp/piprintmail.lock

if ( set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null; then
	# we got the lockfile, so we can continue
	trap 'rm -f "$lockfile"; exit $?' INT TERM EXIT

	BASEDIR=$(dirname $0)
	CURDIR=$(pwd)
	MAILDIR=./maildata
	LOGFILE=/var/log/printmail.log
	ATTACH_DIR=./attachments
	# change directory
	if [ -t 0 ]; then
		echo "Switching directory to: $BASEDIR"
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
		# patch to remove spaces in filenames
		for e in ./*; do
			if [ "$e" != "${e// /_}" ]; then
				echo "Renaming '$e' to '${e// /_}'" | tee -a $LOGFILE
				mv "$e" "${e// /_}";
			fi
		done

		# delete mail
		if [ -t 0 ]; then
			echo "Skip deleting mail: $i"
		else
			# remove the mail from the folder
			echo "Deleting mail: $i" | tee -a $LOGFILE
			rm $i | tee -a $LOGFILE
		fi
	done

	# patch to convert PDF files to lowercase
	for f in $ATTACH_DIR/*.PDF; do mv $f ${f%.*}.pdf; done

	# patch to convert DOCX files to lowercase
	for f in $ATTACH_DIR/*.DOCX; do mv $f ${f%.*}.docx; done

	# patch to convert DOC files to lowercase
	for f in $ATTACH_DIR/*.DOC; do mv $f ${f%.*}.doc; done

	cd $BASEDIR
	# end of patch
	echo "Printing PDFs" | tee -a $LOGFILE

	# convert DOC and DOCX files to PDF and print them
	for f in $ATTACH_DIR/*.{doc,docx}; do
		# check if file exists
		if [ ! -f "$f" ]; then
			continue
		fi
		echo "Converting and printing : $f" | tee -a $LOGFILE
		# convert DOC and DOCX files to PDF
		libreoffice --headless --convert-to pdf $f --outdir $ATTACH_DIR
		# check if conversion was successful
		x=${f%.*}.pdf
		# if the converted file exists, print it and delete the original
		if [ -f "$x" ]; then
			echo "Deleting original file : $f" | tee -a $LOGFILE
			rm $f | tee -a $LOGFILE
		fi
	done

	# print all PDF files
	for x in $ATTACH_DIR/*.pdf; do
		echo "Printing : $x" | tee -a $LOGFILE
		# Check if the command lpr is successful and remove the file if it is
		if { lpr $x; } then
			echo "Printed successfully : $x" | tee -a $LOGFILE
			rm $x | tee -a $LOGFILE
		else
			echo "Failed to print : $x" | tee -a $LOGFILE
		fi
	done

	shopt -u nullglob
	echo "Job finished." | tee -a $LOGFILE

	# clean up after yourself, and release your trap
	rm -f "$lockfile"
    trap - INT TERM EXIT
fi