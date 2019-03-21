#!/usr/bin/env bash
#

set -o errexit
set -o nounset
set -o pipefail

readonly SCRIPT_VER=2.1
readonly AUTHOR="Alexandre Bouchard"
readonly GITHUB="https://github.com/abouchard-ds/QA.d/"

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
unsafe=""
readonly starttime=$(date +%s)
readonly newline=$'\n'
readonly sleeptime=0.1
readonly tmpdir="./.downloads/"

# GMT: Friday, January 1, 1971 12:00:00 AM
readonly period1="31536000"
readonly period2=$(date -d 'today 00:00:00' +%s)
readonly logError="./.qad_error.log"
readonly aggregator="QAd_dataset-"$(date +%Y%m%d)".csv"

# TODO: Trap signals(interrupts): http://man7.org/linux/man-pages/man7/signal.7.html
#   EXIT        EXIT      0         termine correctement
#   SIGHUP      HUP       1         termine avec erreur
#   SIGINT      INT       2         control+C
#   SIGQUIT     QUIT      3
#   SIGKILL     KILL      9
#   SIGTERM     TERM      15
# trap trap_int INT               # ex.: run fonction trap_int s'il trap un CTRL+C

# TODO: Implement a logging function

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

function err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
}

function getConfiguredClient() {
#: getConfiguredClient()
#: search for and prioritize the tool to use
  if command -v wget &>/dev/null; then
    readonly configuredClient="wget"
  elif command -v curl &>/dev/null; then
    readonly configuredClient="curl"
  else
    err "Error: This tool requires either wget or curl to be installed."
    return 1
  fi
}

function httpGet() {
#: httpGet() 
#: function to download data in function of the configuredClient
  case "${configuredClient}" in
    wget) wget -qO- "$@" ;;
    curl) curl -A curl -s "$@" ;;
  esac
}

function checkConnectivity() {
#: checkConnectivity() 
#: validate for internet connectivity
  httpGet github.com > /dev/null 2>&1 || { err "Error: no active internet connection"; return 1; }
}

function validemail() {
#: validemail() stringToTest
#: validate if a string looks like an email address
  if [[ "$1" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$ ]]; then
      return 0
  else
      err "Error: Your username should be an email."
      return 1
  fi
}

function generateList() {
#: generateList() -t hist -o urlfile.txt
#: generate an associative array of urls and write the urls to a file
#: assume the stocklist have been read to array STOCK_LIST
  if [ $# -ne 4 ]; then
    err "generateList() need an url type -u and an output file -o."
    return 1
  else
    while getopts ":u:o:" opt; do
      case $opt in
        t) local -r urltype=${OPTARG} ;;
        o) local -r outfile=${OPTARG} ;;
      esac
    done

    declare -A URL_LIST
    for STOCKS in "${STOCK_LIST[@]}"
    do
        local URL="https://query1.finance.yahoo.com/v7/finance/download/${STOCKS}?period1=${period1}&period2=${period2}&interval=1d&events=history"
        URL_LIST[$STOCKS]="${URL}"
        echo "${URL}" >> "${outfile}"
    done
  fi
}

# TODO: implement parralelization for download
# may be too fast for yahoo
#function downloadParrallel() {
# wget -q -O - --post-data ${postdata} '{}' >> ./${aggregator}
#    echo $URL_LIST | xargs -I '{}' -n 1 -P 8 { sleep 0.5; wget -q -O - --post-data ${postdata} '{}' >> ./${aggregator}; }
#}

function download() {
#: download()
#: does the main job of this script. assume the stocklist have been read to array STOCK_LIST
	local -i index=1

	for STOCKS in "${STOCK_LIST[@]}"
	do
    local filename="${STOCKS}.dat"
		local percentage=$(bc <<< "scale=4; ($index/$arrayLen)*100")
    echo ""
		echo -ne "Downloading ${STOCKS} data: (${percentage}%) of total completed.\r"
		
		local url="https://query1.finance.yahoo.com/v7/finance/download/${STOCKS}?period1=${period1}&period2=${period2}&interval=1d&events=history"
    wget -q -O "${tmpdir}${filename} --post-data ${postdata} ${url}" || true

    if [ $? -eq 0 ]; then
      case "$STOCKS" in
        %5EVIX) sed -i -r "s/^/VIX,/g" "${tmpdir}${filename}" ;;
        %5EGSPC) sed -i -r "s/^/SP500,/g" "${tmpdir}${filename}" ;;
        %5EDJI) sed -i -r "s/^/DJIA,/g" "${tmpdir}${filename}" ;;
        %5EGSPTSE) sed -i -r "s/^/SPTSE,/g" "${tmpdir}${filename}" ;;
        *) sed -i -r "s/^/${STOCKS},/g" "${tmpdir}${filename}" ;;
      esac

      sed -i '1d' "${tmpdir}${filename}"
      sed -i "s/null//g" "${tmpdir}${filename}"
      if [ "${colnames}" ]; then sed -i '1s/^/SYMBOL,DATE,OPEN,HIGH,LOW,CLOSE,ADJ_CLOSE,VOLUME\n/' "${tmpdir}${filename}"; fi

      if [ ! "${keep_all}" ]; then 
        cat "${tmpdir}${filename}" >> "./${aggregator}"
        rm -f "${tmpdir}${filename}"
      fi

      printf "${STOCKS}${newline}" >> "${logResume}"
      if [ ! "${unsafe}" ]; then sleep "${sleeptime}"; fi
      index=$((index + 1))
    else
      printf "${STOCKS}${newline}" >> "${logError}"
      rm "${tmpdir}${filename}"
      index=$((index + 1))
    fi
	done
}

function printsummary() {

    local -r filesize=$(du -sh "./${aggregator}" | awk '{print $1}')
    local -r countline=$(cat "./${aggregator}" | wc -l)
    local -r endtime=$(date +%s)
    local -r runtime=$((endtime-starttime))
    local -r summary1="Download completed. ${newline} Historical financial information for ${arrayLen} stocks."
    local -r summary2="File name is : ${aggregator} ${newline} File has ${countline} lines for a size of ${filesize}"
    local -r avgfilesize=$(ls -l "${tmpdir}" | gawk '{sum += $5; n++;} END {print sum/n;}')
    local -r badstocks=$(wc -l ${logError})
    
    echo ""
    echo "=================================================================================="
    echo "${summary1}"
    echo "${summary2}"
    echo "Average individual file size is : ${avgfilesize}"
    echo "The was ${badstocks} Symbols not found on Yahoo."
    echo "Runtime was ${runtime} seconds."
    echo "=================================================================================="
}

# __init__ main script

# number of args before entering getopts parsing
if [ $# -lt 6 ]; then
    err "Invalid number of arguments. Try qad.sh -h to get help."
    usage
    exit 1
fi

# bc needed to calculate percent of progress
# ici faire un array des required et passer dans un for
command -v bc > /dev/null 2>&1
if [ $? -eq 1 ]; then
    err "You need to install bc (a calculator)."
    exit 1
fi

# TODO > check for duplicate: multiple identical options are possible (-a -a -a)
# TODO > help -h make no sense. it cannot be triggered. placed 'usage' elsewhere for the moment
while getopts ":u:p:l:ckmrsVh" opt; do
  case "$opt" in
      u)
        if $(validemail ${OPTARG}); then
          readonly username=${OPTARG}
        else
          err "Option -u requires a valid email address."
          exit 1
        fi ;;
      p) readonly password=${OPTARG} ;;
      l)
        if [ -s ${OPTARG} ]; then
          stockfile=${OPTARG}
	  readonly logResume="./.qad_resume_${stockfile}_$(date +%Y%m%d).log"
        else
          err "Option -l requires an existing, non-empty file."
          exit 1
        fi ;;
      c) readonly colnames=true ;;
      k) readonly keep_all=true ;;
      m) readonly cleanup_missing=true ;;
      n) readonly new=true ;;
      r) readonly resumable=true ;;
      s) readonly unsafe=true ;;
      V) readonly verbose=true ;;
      h) usage ;;
      \?)
        err "Invalid option: -${OPTARG}. Try qad.sh -h to get help."
        usage
        exit 1 ;;
      :)
        err "Option -${OPTARG} requires an argument."
        usage
        exit 1 ;;
  esac
done

# you need an internet connection
getConfiguredClient
checkConnectivity || exit 1

# RESUME FEATURE
mkdir -p "${tmpdir}"

if [ -f "${logError}" ]; then 
  rm "${logError}"
else
  touch "${logError}"
fi

if [ -s "${logResume}" ]; then
  if [ "${resumable}" ]; then
    resume=$(tail -n 1 "${logResume}")
    if [ "${verbose}" ]; then 
      echo "RESUMING : ${logResume} was found and last stock was ${resume}." 
    fi
    grep -Fvxf "${logResume}" "${stockfile}" > "${stockfile}.tmp"
    stockfile="${stockfile}.tmp"
  else
    rm "${logResume}"
    if [ -f "./${aggregator}" ]; then 
      rm "./${aggregator}"
    fi
    touch "${logResume}"
    touch "./${aggregator}"
  fi
else
  touch "${logResume}"
  if [ -f "./${aggregator}" ]; then 
    rm "./${aggregator}"
  fi
  touch "./${aggregator}"
fi

# PRINT CONFIGURATION
if [ "${verbose}" ]; then
  echo ""
  echo "=================================================================================="
  echo "Your dataset file is: ${aggregator}"
  echo "Your stock file is : ${stockfile}"
  echo "Your file contains "$(wc -l ${stockfile})" stocks"
  echo "=================================================================================="
  echo ""
fi

# PREPARE FOR DOWNLOAD
declare -a STOCK_LIST
readarray -t STOCK_LIST < "${stockfile}"
readonly STOCK_LIST
arrayLen=${#STOCK_LIST[@]}

readonly postdata="user=${username}&password=${password}"
# clear >$(tty)

# DOWNLOAD
download

# MANAGE AGGREGATOR FILE
if [ ! "${keep_all}" ]; then 
  rm -rf "${tmpdir}"
else
  cat "${tmpdir}*.dat" >> "./${aggregator}"
fi

sed -i '1s/^/SYMBOL,DATE,OPEN,HIGH,LOW,CLOSE,ADJ_CLOSE,VOLUME\n/' "./${aggregator}"

# CLEANUP STOCKFILE
if [ "${cleanup_missing}" ]; then
  mv "${stockfile}" "${stockfile}.bak"
  grep -Fvxf "${logError}" "${stockfile}.bak" > "${stockfile}"
  if [ ! -s "${logError}" ]; then 
    rm "${logError}"
  fi
fi

# CLEANUP LOGS
if [ -s "${logError}" ]; then rm "${logError}"; fi
rm "${logResume}"

# SUMMARY STATISTICS
# benchmarking and optimization 
if [ "${verbose}" ]; then
  printsummary
fi

# should end by a main()
