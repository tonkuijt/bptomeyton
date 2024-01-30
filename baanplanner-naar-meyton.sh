#!/bin/bash

###############################################################################################################
##                                        baanplanner-naar-meyton.sh                                         ##
###############################################################################################################
## Dit script genereert een bestand dat met de wedstrijdsoftware van het Meyton schotregistratiesysteem kan  ##
## worden ingelezen. De input die wordt verwacht is een CSV-export van baanplanner.eu met ; als separator.   ##
## Output wordt in de folder SERIES geplaatst waarna deze in een tarball word gepakt en kan worden geupload  ##
## naar de Meyton wedstrijdcomputer. Op de wedstrijdcomputer kan de tarball dan worden uitgepakt en worden   ##
## ingelezen in het wedstrijdsysteem per serie. Tussentijdse seriewijzigingen vereisen dan ook tussentijds   ##
## draaien van de procedures.                                                                                ##
###############################################################################################################
## Dit script is vrij te gebruiken door anderen die er hun voordeel mee kunnen doen. Bronvermelding vind ik  ##
## fijn, maar niet absoluut noodzakelijk want dat zou beperkend kunnen werken voor verspreiding.             ##
###############################################################################################################

# To handle filenames with spaces in them
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

# Check if there is an input argument given
if [ -z ${1} ]; then
	echo ""
	echo Geen inscrhijflijst meegegeven!
	echo Genereer een inschrijflijst op baanplanner.eu met \; als separator en sla deze op.
	echo Start daarna het script met als argument de inschrijflijst.
	echo Bijvoorbeeld \"${0} inschrijflijst.csv\"
	echo ""
	exit 1;
fi

# Check if the inputfile exists.
if [ -s ${1} ]; then
	INFILE=${1}
else
	echo Het invoerbestand ${1} is niet gevonden. Controleer of de invoer juist is.
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

	# Construeer de filenaam om naar te schrijven
	FILENAME=${JAAR}-${MAAND}-${DAG}_Serie_${SERIE}.csv
	# 
	# Schrijf de regel naar de file EN naar standaard uit
	#echo "\"${STARTNUMMER}\";\"${Achternaam}, ${Voorletters}\";\"${Licentienr}\";\"-\";\"0\";\"${Vernaam}\";\"${Vernr}\";\"${BAAN}\";;;;;;;\"-m\";\"53223030\";\"-t\";\"${DISCIPLINE}\";\"-D\";\"${SERIETIJD}\";"
	echo "\"${STARTNUMMER}\";\"${Achternaam}, ${Voorletters}\";\"${Licentienr}\";\"-\";\"0\";\"${Vernaam}\";\"${Vernr}\";\"${BAAN}\";;;;;;;\"-m\";\"53223030\";\"-t\";\"${DISCIPLINE}\";\"-D\";\"${SERIETIJD}\";" >> SERIES/${FILENAME}

done < <(tail -n +2 ${INFILE} | sed 's/; /;/g')

# All files are generated, let's tarball the result
tar -zcvf series-${SERIETIJD}.tgz SERIES >> /dev/null|| echo "Tarball mislukt!"

# Clean up after ourselves
rm -rf SERIES

# Display the results
echo "Tarball gemaakt met de series er in:"
tar -ztvf series-${SERIETIJD}.tgz

IFS=$SAVEIFS
