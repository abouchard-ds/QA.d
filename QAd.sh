#!/usr/bin/env bash
#

#:  <- this indicates docstring in this script.
set -o errexit
set -o nounset
set -o pipefail

declare -r SCRIPT_VER=2.1
declare -r AUTHOR="Alexandre Bouchard"
declare -r GITHUB="https://github.com/abouchard-ds/QA.d/"

# declare and initialize variables with deafult values
# "" evaluate to FALSE in a -> if [ "$verbose" ]; scenario
username=""
password=""
stockfile=""
configuredClient=""
verbose=""
colnames=""
keep_all=""
resumable=""
cleanup_missing=""
starttime=$(date +%s)
newline=$'\n'
sleeptime=0.1
unsafe=""
tmpdir="./.downloads/"

# GMT: Friday, January 1, 1971 12:00:00 AM
period1="31536000"
period2=$(date -d 'today 00:00:00' +%s)
aggregator=QAd_dataset-"$(date +%Y%m%d)".csv

# TODO: Trap signals(interrupts): http://man7.org/linux/man-pages/man7/signal.7.html
#   EXIT        EXIT      0         termine correctement
#   SIGHUP      HUP       1         termine avec erreur
#   SIGINT      INT       2         control+C
#   SIGQUIT     QUIT      3
#   SIGKILL     KILL      9
#   SIGTERM     TERM      15
# trap trap_int INT               # ex.: run fonction trap_int s'il trap un CTRL+C

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
      -r  resume if available
      -c  keep column names in individual CSV
      -h  help
      -V  verbose/debug
    
  info: ${GITHUB}
EOF
}


function timestamp() {
  date +"%Y-%m-%d %T"
}


function getConfiguredClient() {
#: getConfiguredClient()
#: search for and prioritize the tool to use
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
#: httpGet() 
#: function to download data in function of the configuredClient
  case "$configuredClient" in
    wget)  wget -qO- "$@" ;;
    curl)  curl -A curl -s "$@" ;;
  esac
}

function checkConnectivity() {
#: checkConnectivity() 
#: validate for internet connectivity
  httpGet github.com > /dev/null 2>&1 || { echo "Error: no active internet connection" >&2; return 1; }
}

function validemail() {
#: validemail() stringToTest
#: validate if a string looks like an email address
  if [[ "$1" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$ ]]; then
      return 0
  else
      return 1
  fi
}

function generateList() {
#: generateList() -t hist -o urlfile.txt
#: generate an associative array of urls and write the urls to a file
#: assume the stocklist have been read to array STOCK_LIST
  if [ $# -ne 4 ]; then
    echo "generateList() need an url type -u and an output file -o."
    return 1
  else
    while getopts ":t:o:" opt; do
      case $opt in
        t) local -r urltype=${OPTARG} ;;
        o) local -r outfile=${OPTARG} ;;
      esac
    done

    declare -A URL_LIST
    for STOCKS in "${STOCK_LIST[@]}"
    do
        local URL="https://query1.finance.yahoo.com/v7/finance/download/${STOCKS}?period1=${period1}&period2=${period2}&interval=1d&events=history"
        URL_LIST[$STOCKS]=${URL}
        echo ${URL} >> ${outfile}
    done
  fi
}

# may be too fast for yahoo
#function downloadParrallel() {
# wget -q -O - --post-data ${postdata} '{}' >> ./${aggregator}
#    echo $URL_LIST | xargs -I '{}' -n 1 -P 8 { sleep 0.5; wget -q -O - --post-data ${postdata} '{}' >> ./${aggregator}; }
#}

function download() {
#: download()
#: does the main job of this script. assume the stocklist have been read to array STOCK_LIST
	local index=1

	for STOCKS in "${STOCK_LIST[@]}"
	do
    local filename=${STOCKS}".dat"
		local percentage=$(bc <<< "scale=4; ($index/$arrayLen)*100")
    echo ""
		echo -ne "Downloading ${STOCKS} data: (${percentage}%) of total completed.\r"
		
		local url="https://query1.finance.yahoo.com/v7/finance/download/${STOCKS}?period1=${period1}&period2=${period2}&interval=1d&events=history"
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
    usage
    exit 1
fi

# bc needed to calculate percent of progress
command -v bc > /dev/null 2>&1
if [ $? -eq 1 ]; then
    echo "You need to install bc (a calculator)."
    exit 1
fi

# TODO > check for duplicate: multiple identical options are possible (-a -a -a)
# TODO > help -h make no sense. it cannot be triggered. placed 'usage' elsewhere for the moment
while getopts ":u:p:l:ckmrsVh" opt; do
  case $opt in
      u)
        if $(validemail ${OPTARG}); then
          username=${OPTARG}
        else
          "Option -u requires a valid email address." >&2
          exit 1
        fi ;;
      p) password=${OPTARG} ;;
      l)
        if [ -s ${OPTARG} ]; then
          stockfile=${OPTARG} 
        else
          "Option -l requires an existing, non-empty file." >&2
          exit 1
        fi ;;
      c) colnames=true ;;
      k) keep_all=true ;;
      m) cleanup_missing=true ;;
      n) new=true ;;
      r) resumable=true ;;
      s) unsafe=true ;;
      V) verbose=true ;;
      h) usage ;;
      \?)
        echo "Invalid option: -${OPTARG}. Try qad.sh -h to get help." >&2
        usage
        exit 1 ;;
      :)
        echo "Option -${OPTARG} requires an argument." >&2
        usage
        exit 1 ;;
  esac
done

# you need an internet connection
getConfiguredClient
checkConnectivity || exit 1

# RESUME FEATURE
logError="./.qad_error.log"
logResume="./.qad_resume_${stockfile}_$(date +%Y%m%d).log"

mkdir -p ${tmpdir}

if [ -f ${logError} ]; then 
  rm ${logError} 
else
  touch ${logError}
fi

if [ -s ${logResume} ]; then
  if [ "$resumable" ]; then
    resume=$(tail -n 1 ${logResume})
    if [ $verbose ]; then 
      echo "RESUMING : ${logResume} was found and last stock was ${resume}." 
    fi
    grep -Fvxf ${logResume} ${stockfile} > "${stockfile}.tmp"
    stockfile="${stockfile}.tmp"
  else
    rm ${logResume} 
    if [ -f ./${aggregator} ]; then 
      rm ./${aggregator}
    fi
    touch ${logResume}
    touch ./${aggregator}
  fi
else
  touch ${logResume}
  if [ -f ./${aggregator} ]; then 
    rm ./${aggregator}
  fi
  touch ./${aggregator}
fi

# PRINT CONFIGURATION
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
declare -a STOCK_LIST
readarray -t STOCK_LIST < ${stockfile}
arrayLen=${#STOCK_LIST[@]}

postdata="user=${username}&password=${password}"
# avoid script exit on download error
set +e
# clear >$(tty)
download
set -e

# MANAGE AGGREGATOR FILE
if [ ! $keep_all ]; then 
  rm -rf ${tmpdir}
else
  cat ${tmpdir}*.dat >> ./${aggregator}
fi

sed -i '1s/^/SYMBOL,DATE,OPEN,HIGH,LOW,CLOSE,ADJ_CLOSE,VOLUME\n/' ./${aggregator}

# CLEANUP
if [ $cleanup_missing ]; then
  mv ${stockfile} ${stockfile}.bak
  grep -Fvxf ${logError} ${stockfile}.bak > ${stockfile}
  if [ ! -s ${logError} ]; then 
    rm ${logError}
  fi
fi

if [ ! -s ${logError} ]; then rm ${logError}; fi
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
