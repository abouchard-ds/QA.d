#!/usr/bin/env bash
#

# bash best practices
	set -o errexit
	set -o nounset
	set -o pipefail

# global variable declaration
soft_version="QA.d downloader 1.2"
author="Alexandre Bouchard - https://github.com/data-scientia"

if [[ $# -lt 3 ]] ; then
    echo "Call the script with USERNAME PASSWORD STOCK_FILE as arguments. "
		exit 1
fi

aggregator=QAd_DATA-"$(date +%Y%m%d)".csv
yuser=$1
ypass=$2
sfile=$3
postdata="user=${yuser}&password=${ypass}"
period1="31536000"
period2=$(date -d 'today 00:00:00' +%s)
sleeptime=0.5
starttime=`date +%s`

# Creer un dossier dans le working directory pour acceullir les fichiers temporaires s'il n'existe pas
mkdir -p ./tmp

# Regarde s'il y a deja un fichier pour aujourd'hui et le supprime
if [ -f ./tmp/$aggregator ] ; then
    rm ./tmp/$aggregator
fi

# Creer le fichier pour aujourd'hui
touch ./tmp/$aggregator

# Valide s'il peut ecrire dans le fichier que nous veons de creer. S'il ne peut pas exit avec code 1
if [[ ! -w ./tmp/$aggregator ]]; then exit 1; fi

# Load le fichier stock_config.ini dans un array
# Contient une liste de stocks 'non-exotique' du TSX.
declare -a arr
readarray -t arr < $sfile
arrayLen=${#arr[@]}

# Fonction pour le download
function download() {

	index=1
	for STOCKS in "${arr[@]}"
	do

		percentage=$(bc <<< "scale=2; ($index/$arrayLen)*100")
		echo -ne "Progress percentage : " $percentage " %" '\r'
		echo "Downloading data for: " $STOCKS
		filename=$STOCKS".dat"
		# doit ajoute un error handling pour passer au suivant en cas d'erreur.
		url="https://query1.finance.yahoo.com/v7/finance/download/"$STOCKS"?period1="$period1"&period2="$period2"&interval=1d&events=history"
		wget -q -O ./tmp/$filename --post-data $postdata $url

		case $STOCKS in
		 %5EVIX)
			  sed -i -r "s/^/VIX,/g" ./tmp/$filename
			  ;;
		 %5EGSPC)
			  sed -i -r "s/^/SP500,/g" ./tmp/$filename
			  ;;
		 %5EDJI)
			  sed -i -r "s/^/DJIA,/g" ./tmp/$filename
			  ;;
		 %5EGSPTSE)
			  sed -i -r "s/^/SPTSE,/g" ./tmp/$filename
			  ;;
		 *)
			  sed -i -r "s/^/$STOCKS,/g" ./tmp/$filename
			  ;;
		esac
		# enleve la ligne de header
		sed -i '1d' ./tmp/$filename
		sed -i "s/null//g" ./tmp/$filename
		cat ./tmp/$filename >> ./tmp/$aggregator
		index=$((index + 1))
		sleep $sleeptime
	done

}

# call function
download

# supprime les fichiers temporaires individuels
rm -f ./tmp/*.dat

# preparations pour la fenetre de Summary
filesize=$(du -sh ./tmp/$aggregator | awk '{print $1}')
countline=$(cat ./tmp/$aggregator | wc -l)
newline=$'\n'
endtime=`date +%s`
runtime=$((endtime-starttime))
summary1="Download completed. $newline Historical financial information for $arrayLen stocks."
summary2="File name is : $aggregator $newline File has $countline lines for a size of $filesize"

function printsummary() {
	echo "=================================================================================="
	echo $summary1
	echo $summary2
	echo "Runtime was " $runtime " seconds."
	echo "=================================================================================="
}

printsummary
