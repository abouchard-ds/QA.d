#!/usr/bin/env bash
#

# bash best practices
	# exit script on fail command (|| true   when you allow to fail)
	set -o errexit
	# force variable declaration
	set -o nounset
	# debugging
	# set -o xtrace
	# catch errors in pipes
	set -o pipefail

# global variable declaration
soft_version="QASMS Downloader 1.0"

# function must be declared before a call - unlike Python
function zen_directory(){
	zenity --file-selection \
	--title="${soft_version}" \
	--directory 2>/dev/null
	
	return $?
}

function zen_configuration(){
	
	local check=0
	until [ $check -eq 2 ]
	do
	
		output=$(zenity --forms --title="${soft_version}" \
		--text="Configure downloader: " \
		--add-entry="Y! username :" \
		--add-password="Y! password :" \
		--add-password="Confirm pass:" \
		--add-calendar="Start date :" \
		--separator="," \
		--forms-date-format=%s 2>/dev/null)

		
		user1=$(awk -F, '{print $1}' <<<$output)
		pass1=$(awk -F, '{print $2}' <<<$output)
		pass2=$(awk -F, '{print $3}' <<<$output)
		date1=$(awk -F, '{print $4}' <<<$output)
		
		check=0
		if [ "$pass1" == "$pass2" ] 
		then 
			check=$((check + 1))
		else
			$(zenity --error --title="${soft_version}" --text="Passwords does not match." 2>/dev/null)
		fi
		
		if [[ $date1 -lt $(date +%s) ]] 
		then 
			check=$((check + 1))
		else
			$(zenity --error --title="${soft_version}" --text="Start date must be smaller than today." 2>/dev/null)
		fi
		
	done
	
	echo "${output}"
	
	return $?
}

# main script
config=$(zen_configuration)

aggregator=STOCK_DATA-"$(date +%Y%m%d)".csv
yuser=$(awk -F, '{print $1}' <<<$config)
ypass=$(awk -F, '{print $2}' <<<$config)
postdata="user=${yuser}&password=${ypass}"
period1=$(awk -F, '{print $4}' <<<$config)
period2=$(date -d 'today 00:00:00' +%s)

# Regarde s'il y a deja un fichier pour aujourd'hui et le supprime 
if [ -f $aggregator ] ; then
    rm $aggregator
fi

# Creer le fichier pour aujourd'hui
touch $aggregator

# Valide s'il peut ecrire dans le fichier que nous veons de creer. S'il ne peut pas exit avec code 1
if [[ ! -w $aggregator ]]; then exit 1; fi

# Load le fichier stock_config.ini dans un array 
# Contient une liste de stocks 'non-exotique' du TSX.
declare -a arr
readarray -t arr < stock_config.ini
arrayLen=${#arr[@]}

# Fonction pour le download
function download() {
	
	# la variable index ne sert qu'a l'affichage du progress dialog de zenity
	# sert au calcul du pourcentage.
	index=1
	for STOCKS in "${arr[@]}"
	do
		# echo pour la fenetre Zenity (gere le progress bar)
		percentage=$(bc <<< "scale=2; ($index/$arrayLen)*100")
		echo $percentage
		# echo pour la fenetre Zenity (gere le texte affiche)
		echo "# Downloading data for:" $STOCKS
		
		filename=$STOCKS".dat"
		# doit ajoute un error handling pour passer au suivant en cas d'erreur.
		url="https://query1.finance.yahoo.com/v7/finance/download/"$STOCKS"?period1="$period1"&period2="$period2"&interval=1d&events=history"
		wget -q -O $filename --post-data $postdata $url
		# ajoute une premiere colonne avec le nom de l'action - le langage HTML a fait deformer les noms des index car ils commence par ^
		# --> a modifier car je ne download plus ces index avec le stock_config.ini
		case $STOCKS in
		 %5EVIX)      
			  sed -i -r "s/^/VIX,/g" $filename
			  ;;
		 %5EGSPC)      
			  sed -i -r "s/^/SP500,/g" $filename
			  ;;
		 %5EDJI)
			  sed -i -r "s/^/DJIA,/g" $filename
			  ;; 
		 %5EGSPTSE)
			  sed -i -r "s/^/SPTSE,/g" $filename
			  ;;
		 *)
			  sed -i -r "s/^/$STOCKS,/g" $filename
			  ;;
		esac
		# enleve la ligne de header
		sed -i '1d' $filename
		sed -i "s/null//g" $filename
		cat $filename >> $aggregator
		index=$((index + 1))
	done

}

# call function and pipe into progress dialog
download | zenity --progress --title="${soft_version}" --text="" --percentage=0 2>/dev/null

# supprime les fichiers temporaires individuels
rm -f *.dat

# preparations pour la fenetre de Summary
filesize=$(du -sh $aggregator | awk '{print $1}')
countline=$(cat $aggregator | wc -l)
newline=$'\n'
start=period1=$(awk -F, '{print $4}' <<<$config)
end=period2=$(date -d 'today 00:00:00' +%s)
summary="Download completed. $newline Historical financial information for $arrayLen stocks.$newline File name is : $aggregator $newline File has $countline lines for a size of $filesize"


# Wipe le STOCK_DATA_permanent.tbl et
# Copie le nouveau temporaire vers le permanent
######### Ceci etait utilise quand je loadait les donner dans une external table Oracle Database
######### Je vais le retravailler plus tard lorsque j'aurai ajouter une option de l'active ou non. 
#cat $aggregator > STOCK_DATA_permanent.tbl
zenity --info --title="${soft_version}" --text="${summary}"  2>/dev/null
