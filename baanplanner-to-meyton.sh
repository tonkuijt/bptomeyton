#!/bin/bash

###############################################################################################################
##                                        baanplanner-to-meyton.sh                                           ##
###############################################################################################################
## This script generates a series of inputliste format files for use in the Meytom match control software,   ##
## from a baanplanner.eu export file.                                                                        ##
## Output is placed in the SERIES folder and then tarballed for easy copying to the Meyton match system.     ##
## The tarball can then be un-tarred on the Meyton system and the series files used as input for the         ##
###############################################################################################################
## This script can be freely used by anybody benefitting from it.                                            ##
## Source recognition is nice, but it should not interfere with free use of this code.                       ##
###############################################################################################################

# Check if there is an input argument given
if [ -z ${1} ]; then
	echo ""
	echo No input file given!
	echo Generate an input file on baanplanner.eu based on your match, CSV format, ';' separated.
	echo Then start this script with the file as an argument.
	echo For example \"${0} inschrijflijst.csv\"
	echo ""
	exit 1;
fi

# Check if the inputfile exists.
if [ -s ${1} ]; then
	INFILE=${1}
else
	echo Input file ${1} is not found. Check if the filename is given correctly.
	exit 1
fi


# Check if the output folder exists. If yes, remove it because data corruption might occur. If no, create it.
if [ -d "SERIES" ]; then
	# Empty the SERIES folder
	rm -rf SERIES/*
else
	# SERIES does not exist (yet) so let's create it
	mkdir SERIES
fi

# All prerequisites met, let's split the file into variables and construct a startlist
while IFS=";" read -r Dag Datum Baan Serie Voorletters Achternaam Geslacht Geboortedatum Geboorteplaats Adres Postcode Plaats Legitimatie Documentnr Vernr Vernaam Licentienr Korps Korpsnr Klasse Houding Email Telnr Linkshandig Opmerkingen Betaaldvooraf Betaald Betaaldatum Betaalmanier
do
	# Remodelling baanplanner variables to Meyton formats
	DAG=`echo ${Datum}|cut -d'/' -f1`
	MAAND=`echo ${Datum}|cut -d'/' -f2`
	JAAR=`echo ${Datum}|cut -d'/' -f3`
	UUR=`echo ${Serie}|cut -d'.' -f1`
	MINUUT=`echo ${Serie}|cut -d'.' -f2`
	SERIETIJD=${JAAR}${MAAND}${DAG}${UUR}${MINUUT}

	if [ "${Serie}" = "09.00" ]; then SERIE=1; fi
	if [ "${Serie}" = "09.50" ]; then SERIE=2; fi
	if [ "${Serie}" = "10.40" ]; then SERIE=3; fi
	if [ "${Serie}" = "11.30" ]; then SERIE=4; fi
	if [ "${Serie}" = "12.20" ]; then SERIE=5; fi
	if [ "${Serie}" = "13.10" ]; then SERIE=6; fi
	if [ "${Serie}" = "14.00" ]; then SERIE=7; fi
	if [ "${Serie}" = "14.50" ]; then SERIE=8; fi
	if [ "${Serie}" = "15.40" ]; then SERIE=9; fi
	if [ "${Serie}" = "16.30" ]; then SERIE=10; fi

	if [ "${Houding}" = "MILITAIR GEWEER" ]; then DISCIPLINE="GKG Mil Lig St 100M_2022_12"; fi
	if [ "${Houding}" = "MILITAIR GEWEER OPTIEK" ]; then DISCIPLINE="GKG Mil Lg Opt 100m_202"; fi
	if [ "${Houding}" = "VETERANEN GEWEER" ]; then DISCIPLINE="GKG Vet Lig 100M_2022_12"; fi
	if [ "${Houding}" = "STANDAARD GEWEER" ]; then DISCIPLINE="GKG Std. Lig. 100M_2022_12"; fi

	BAAN=`echo ${Baan}+16 | bc -l`
	STARTNUMMER=${SERIE}${BAAN}

	# Construct the filename to write the result to
	FILENAME=${JAAR}-${MAAND}-${DAG}_Serie_${SERIE}.csv
	# 
	# Write the line to the file.
	# Uncomment the line below to get output to standard out for debugging purposes.

	#echo "\"${STARTNUMMER}\";\"${Achternaam}, ${Voorletters}\";\"${Licentienr}\";\"-\";\"0\";\"${Vernaam}\";\"${Vernr}\";\"${BAAN}\";;;;;;;\"-m\";\"53223030\";\"-t\";\"${DISCIPLINE}\";\"-D\";\"${SERIETIJD}\";"
	echo "\"${STARTNUMMER}\";\"${Achternaam}, ${Voorletters}\";\"${Licentienr}\";\"-\";\"0\";\"${Vernaam}\";\"${Vernr}\";\"${BAAN}\";;;;;;;\"-m\";\"53223030\";\"-t\";\"${DISCIPLINE}\";\"-D\";\"${SERIETIJD}\";" >> SERIES/${FILENAME}

done < <(tail -n +2 ${INFILE} | sed 's/; /;/g')

# All files are generated, let's tarball the result
tar -zcvf series-${SERIETIJD}.tgz SERIES >> /dev/null|| echo "Tarball mislukt!"

# Clean up after ourselves
rm -rf SERIES

# Display the results
echo "Tarball created with the following contents:"
tar -ztvf series-${SERIETIJD}.tgz

