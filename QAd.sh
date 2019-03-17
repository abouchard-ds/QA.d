#!/usr/bin/env bash
#

set -o errexit
set -o nounset
set -o pipefail

declare -r SCRIPT_VER=2.0
declare -r AUTHOR="Alexandre Bouchard"
declare -r GITHUB="https://github.com/abouchard-ds/QA.d/"

# declare and initialize variables with deafult values
# "" evaluate to FALSE in a -> if "$verbose"; scenario
username=""
password=""
stockfile=""
configuredClient=""
verbose=""
colnames=""
keep_all=""
cleanup_missing=""
starttime=$(date +%s)

# GMT: Friday, January 1, 1971 12:00:00 AM
period1="31536000"
period2=$(date -d 'today 00:00:00' +%s)
aggregator=QAd_dataset-"$(date +%Y%m%d)".csv
newline=$'\n'
sleeptime=0.1
unsafe=""
tmpdir="./.downloads/"

# TODO: Trap signals(interrupts): http://man7.org/linux/man-pages/man7/signal.7.html
#   EXIT        EXIT      0         termine correctement
#   SIGHUP      HUP       1         termine avec erreur
#   SIGINT      INT       2         control+C
#   SIGQUIT     QUIT      3
#   SIGKILL     KILL      9
#   SIGTERM     TERM      15
# trap trap_int INT               # ex.: run fonction trap_int s'il trap un CTRL+C

# don't think like it's 1985, try to make it object-oriented. It simplifies
# reading the script execution (kind of __init__ main) and code reuse.
function usage() {
  cat <<EOF
  Quantitative Analysis Dataset Creator ${SCRIPT_VER}
  Object: Create a stock price dataset from a list of tickers.

  Usage: qad.sh -u "user@yahoo.com" -p "p4ssw0rd" -l "/home/user/stocks.ini" [options]

    Required :
      -u  yahoo finance username
      -p  yahoo finance password
      -l  stocklist file

    Optional :
      -k  keep individual .dat files
      -s  bypass sleep timer on downloads
      -m  cleanup missing symbols from stocklist file
      -n  do not resume, start new
      -c  keep column names in individual CSV
      -h  help
      -V  verbose/debug
    
  info: ${GITHUB}
EOF
}

# function available() {
#  # bc was not installed on ubuntu 18.04
# }

function getConfiguredClient() {
  if command -v wget &>/dev/null; then
    configuredClient="wget"
    if [ $verbose ]; then echo "configuredClient is ${configuredClient}"; fi
  elif command -v curl &>/dev/null; then
    configuredClient="curl"
    if [ $verbose ]; then echo "configuredClient is ${configuredClient}"; fi
  else
    echo "Error: This tool requires either wget or curl to be installed." >&2
    return 1
  fi
}

function httpGet() {
  case "$configuredClient" in
    wget)  wget -qO- "$@" ;;
    curl)  curl -A curl -s "$@" ;;
  esac
}

function checkConnectivity() {
  httpGet github.com > /dev/null 2>&1 || { echo "Error: no active internet connection" >&2; return 1; }
}

function isEmailaddress() {
  if [[ "$1" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$ ]]; then
      return 0
  else
      return 1
  fi
}

# work in progress
function generateList() {
    i=0
    declare -a URL_LIST
    for STOCKS in "${STOCK_LIST[@]}"
    do
        url="https://query1.finance.yahoo.com/v7/finance/download/${STOCKS}?period1=${period1}&period2=${period2}&interval=1d&events=history"
        URL_LIST[$i]=${url}
        i=$(($i+1))
    done
}

# work in progress - it seems like it misses some. file is half the expected size
# wget -q -O - --post-data ${postdata} '{}' >> ./${aggregator}
# may be too fast for yahoo
#function downloadParrallel() {
#    echo ${url}_LIST | xargs -I '{}' -n 1 -P 8 { sleep 0.5; wget -q -O - --post-data ${postdata} '{}' >> ./${aggregator}; }
#}

function download() {

	index=1

	for STOCKS in "${STOCK_LIST[@]}"
	do
		percentage=$(bc <<< "scale=4; ($index/$arrayLen)*100")
    clear >$(tty)
    echo ""
		echo -ne "Downloading ${STOCKS} data: (${percentage}%) of total completed.\r"
		declare -l filename=${STOCKS}".dat"

		url="https://query1.finance.yahoo.com/v7/finance/download/${STOCKS}?period1=${period1}&period2=${period2}&interval=1d&events=history"
    wget -q -O ${tmpdir}${filename} --post-data ${postdata} ${url}

    if [ $? -eq 0 ]; then
      case "$STOCKS" in
        %5EVIX)
          sed -i -r "s/^/VIX,/g" ${tmpdir}${filename} 
          ;;
        %5EGSPC)
          sed -i -r "s/^/SP500,/g" ${tmpdir}${filename} 
          ;;
        %5EDJI)
          sed -i -r "s/^/DJIA,/g" ${tmpdir}${filename} 
          ;;
        %5EGSPTSE)
          sed -i -r "s/^/SPTSE,/g" ${tmpdir}${filename} 
          ;;
        *)
          sed -i -r "s/^/${STOCKS},/g" ${tmpdir}${filename} 
          ;;
      esac

      sed -i '1d' ${tmpdir}${filename}
      sed -i "s/null//g" ${tmpdir}${filename}
      if [ $colnames ]; then sed -i '1s/^/SYMBOL,DATE,OPEN,HIGH,LOW,CLOSE,ADJ_CLOSE,VOLUME\n/' ${tmpdir}${filename}; fi

      if [ ! $keep_all ]; then 
          cat ${tmpdir}${filename} >> ./${aggregator}
          rm -f ${tmpdir}${filename}
      fi

      printf "${STOCKS}${newline}" >> ${logResume}
      if [ ! "$unsafe" ]; then sleep ${sleeptime}; fi
      index=$((index + 1))

    else
      printf "${STOCKS}${newline}" >> ${logError}
      rm ${tmpdir}${filename}
      index=$((index + 1))
    fi
	done
}

# __init__ main script
# ###########################################################################

# number of args before entering getopts parsing
if [ $# -lt 6 ]; then
    echo "Invalid number of arguments. Try qad.sh -h to get help."
    exit 1
fi

# TODO : multiple identical options are possible (-a -a -a)
while getopts ":u:p:l:ckmnsVh" opt; do
  case $opt in
      u)
        if [ $verbose ]; then echo "-u was triggered, Parameter: ${OPTARG}" >&2; fi
        if $(isEmailaddress ${OPTARG}); then
          username=${OPTARG}
        else
          "Option -u requires a valid email address." >&2
          exit 1
        fi ;;
      p)
        if [ $verbose ]; then echo "-p was triggered, Parameter: ${OPTARG}" >&2; fi
        password=${OPTARG} ;;
      l)
        if [ $verbose ]; then echo "-l was triggered, Parameter: ${OPTARG}" >&2; fi
        if [ -s ${OPTARG} ]; then
          stockfile=${OPTARG} 
        else
          "Option -l requires an existing, non-empty file." >&2
          exit 1
        fi ;;
      c)
        if [ $verbose ]; then echo "-c was triggered, Parameter: keep column names" >&2; fi
        colnames=true ;;
      k)
        if [ $verbose ]; then echo "-k was triggered, Parameter: keep individual .dat files" >&2; fi 
        keep_all=true ;;
      m) 
        if [ $verbose ]; then echo "-m was triggered, Parameter: remove missing symbols from config file" >&2; fi 
        cleanup_missing=true ;;
      n)
        if [ $verbose ]; then echo "-n was triggered, Parameter: do not resume, start new" >&2; fi 
        new=true ;;
      s)
        if [ $verbose ]; then echo "-s was triggered, Parameter: bypass sleep timer on downloads" >&2; fi 
        unsafe=true ;;
      V) 
        if [ $verbose ]; then echo "-V was triggered, Parameter: verbose" >&2; fi 
        verbose=true ;;
      h) usage ;;
      \?)
        echo "Invalid option: -${OPTARG}. Try qad.sh -h to get help." >&2
        exit 1 ;;
      :)
        echo "Option -${OPTARG} requires an argument." >&2
        exit 1 ;;
  esac
done

# you need an internet connection
getConfiguredClient
checkConnectivity || exit 1

# OPTION TO RESUME HERE
logResume="./.qad_resume_${stockfile}_$(date +%Y%m%d).log"
logError="./.qad_error.log"

if [ -s ${logResume} ]; then
  resume=$(tail -n 1 ${logResume})
  if [ $verbose ]; then echo "NOTICE: could resume from ${resume} if it was implemented."; fi
else    
  touch ${logResume}
fi

# PREPARE FOLDER AND FILE

# Creer un dossier dans le working directory pour acceuillir les fichiers temporaires s'il n'existe pas
mkdir -p ${tmpdir}

# Regarde s'il y a deja un fichier pour aujourd'hui et le supprime
# ici ca depend du resume feature
if [ -f ./${aggregator} ] ; then
    rm ./${aggregator}
    # if [ ! $resume ]; then rm ./${aggregator}; fi
fi

# Creer le fichier aggregation pour aujourd'hui
touch ./${aggregator}
if [[ ! -w ./${aggregator} ]]; then exit 1; fi

touch ${logError}
touch ./${aggregator}
# if [[ ! -w ./${aggregator} ]]; then exit 1; fi


# PRINT LA CONFIG
if [ $verbose ]; then
    echo ""
    echo "=================================================================================="
    echo "Your dataset file is: ${aggregator}"
    echo "Your stock file is : ${stockfile}"
    echo "Your file contains "$(wc -l ${stockfile})" stocks"
    echo "=================================================================================="
    echo ""
fi

# DOWNLOAD
# Load le fichier stocklist dans un array
declare -a STOCK_LIST
readarray -t STOCK_LIST < ${stockfile}
arrayLen=${#STOCK_LIST[@]}

postdata="user=${username}&password=${password}"
# avoid script exit on download error
set +e
download
set -e


# CLEANUP
if [ ! $keep_all ]; then 
    # remove folder and files if any
    rm -rf ${tmpdir}
else
    # at this point with keep_all option there is no BIGFILE
    cat ${tmpdir}*.dat >> ./${aggregator}
fi

sed -i '1s/^/SYMBOL,DATE,OPEN,HIGH,LOW,CLOSE,ADJ_CLOSE,VOLUME\n/' ./${aggregator}

if [ ! -s ${logError} ]; then rm ${logError}; fi

if [ $cleanup_missing ]; then
    mv ${stockfile} ${stockfile}.bak
    grep -Fvxf ${logError} ${stockfile}.bak > ${stockfile}
fi

# can remove since it was successfully completed
rm ${logResume}

# SUMMARY STATISTICS
# benchmarking and optimization 
if [ $verbose ]; then
    filesize=$(du -sh ./${aggregator} | awk '{print $1}')
    countline=$(cat ./${aggregator} | wc -l)
    endtime=$(date +%s)
    runtime=$((endtime-starttime))
    summary1="Download completed. $newline Historical financial information for $arrayLen stocks."
    summary2="File name is : ${aggregator} $newline File has $countline lines for a size of $filesize"
    avgfilesize=$(ls -l ${tmpdir} | gawk '{sum += $5; n++;} END {print sum/n;}')
    badstocks=$(wc -l ${logError})

    function printsummary() {
        echo ""
        echo "=================================================================================="
        echo $summary1
        echo $summary2
        echo "Average individual file size is : ${avgfilesize}"
        echo "The was ${badstocks} Symbols not found on Yahoo."
        echo "Runtime was ${runtime} seconds."
        echo "=================================================================================="
    }

    printsummary
fi
