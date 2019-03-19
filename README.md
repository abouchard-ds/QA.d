![Logo](media/qa-d_logo.png)

## Table of Contents

- [Introduction](#introduction)
- [Objectives](#objectives)
- [Features](#features)
- [Installation](#installation)
- [Parameters](#parameters)
- [Dataset](#dataset)
- [Examples](#examples)
- [Command_line](#command_line)

## Introduction

<p align="center">

  <img src="https://img.shields.io/badge/bash-4.4.12-blue.svg">
  <img src="https://img.shields.io/badge/zenity-3.24.0-green.svg">
  <img src="https://img.shields.io/badge/powered%20by-jekyll-red.svg">

</p>

## Presentation

QA.d (**Q**uantitative **A**nalysis **d**ataset) is a small project consisting of bash scripts to automatically create a dataset by downloading historical stock data as CSV/JSON files.

A dataset created with this program can be of a sizable amount. If you take all canadian and american securities without exclusion (debentures, warrants, preferred shares, etc.) you could get approximately >4gb of data (**~16,000 individual files and a big file containing ~44,500,000 observations**). 


## Objective
The project is about generating a large amount of data related to each other in multiple files and/or one big file. More specifically:

- this is a bash project; exploring the limitations and benefits of bash;
- nothing is faster than base OS level: if it can be done relatively simply with bash, why do it differently;
- simulating big data stuff: data ingestion, data wrangling/preprocessing, simulating ETLs;
- practice parralel processing (xargs, parralel,...) on multiple files;
- practice with multiples files in Python, R and both;
- load those files into an HDFS (hadoop distributed file system);
- maybe you want to practice with Excel at its maximum capacity;
- importing data in multiple database engine, exploring external tables and so on;
- the pleasure of doing something uncommon (you'll always see this done in python and R, which have overhead and need installation);
- transaction benchmarking, hardware/os testing, statistical analysis, machine learning algorithms;
- the data is real, you could take financial decisions with it.

## Features

* Easily create datasets of variable size;
* Personalize your historical stock datasets;
* The simplest way to do it, no need of Python or R or special libraries, this is the simplest expression made with base OS;
* Almost no dependencies, packages are default;
* The GUI follows your personnal Linux theme;
* A '*non graphical*' version is also available;
* The data is real and can in itself be usefull;
* Usefull if you want to practice statistics, modeling, finance;
* Usefull if you want to practice data wrangling on files;
* Who knows? You could become a millionnaire using your dataset to make financial decisions

### BIG DATA ETL SIMULATION
You can randomly distribute the files between multiple servers and try to recover a full dataset. You can try out an ingestion pipeline for benchmarking or an ETL for correctness. You can stress test some program (*SPSS, SAS, RapidMiner, Enteprise Miner, Python, R, Octave, Matlab, Orange, Tableau, Excel, Access, bash, Spark, anything*).

### FILES VERSUS IN MEMORY
You may want to experiment with big data, distributed file systems or parralelization? Then you need a lot of structured, semi-structured, unstructured files. This is a good project for you. 

### STOCKLIST CURATION
If the data itself if of interest to you, you have the option to configure the stocklist that the program will download with a simple text file. If a stock does not exist anymore (mergers, bankruptcy, you downloaded an old list of symbols, etc.) the program can remove the bad entries from your stocklist automatically or you can consult the .stock.error file.

### The "LIGHT option" - 1 BIGFILE
If getting all the text files is not for you but you only want one massive file (3Gb ++) for your studies/test/project. (Random sampling test avg size per file 220K) min 88b max 512k. Using the full_us_can.txt stockfile I get 4gb of data (~16,000 individual files and a big file of 3-4gb containing 44,500,000 observations/lines/rows).

### RESUMABLE
Downloading all the canadian and american historical stock data since 1996 will take a couple of hours.(random sampling test avg 0.7733 second per stock - approx. 4 hours for 16500 files). So if your program crashes or you issue a CTRL-C, you can resume your download later if you activate this parameter.

### NON-FEATURE
My goal is to increase the types, size and number of files generated. If you want to be very selective on the dates, type, stocks etc. You can do it after the creation of the dataset or use another tool made for this. (thousands of python and R libraries made for this purpose. not this script)

## Installation

The program has been coded and tested on [Ubuntu 17.10 Desktop](https://www.ubuntu.com/download/desktop), Ubuntu 18.04 desktop and Linux on Windows 10 pro (WSL). The following packages are used by the script they should be default install on Ubuntu.

You'll need to have an account on Y! Finance (API Key) to be able to download the data 

* [Yahoo! Finance Account](https://login.yahoo.com/config/login?.intl=ca&.lang=en-CA&.src=finance&.done=https%3A%2F%2Fca.finance.yahoo.com%2F)

| packages | description | explanation |
|--|--|--|
| awk 4.1.4 | GNU awk, a pattern scanning and processing language | only tested on this version |
| bash 4.4.12 | GNU Bourne Again SHell | you need a recent shell because of the use of ```readarray``` |
| bc 1.06.95 | GNU bc arbitrary precision calculator language | only tested on this version |
| wget 1.19.1 | retrieves files from the web | note that wget handles stuff with the cookies |
| whiptail 0.52.18 | Displays user-friendly dialog boxes from sh | only tested on this version |
| zenity 3.24.0 | Display graphical dialog boxes from shell scripts | only tested on this version |

To validate that you have the prerequisites:
```bash
dpkg -l bash bc gawk wget whiptail zenity
```

You'll get a similar return:
```bash
||/ Name        Version          Architecture     Description
+++-===========-================-================-===================================================
ii  bash        4.4-5ubuntu1     amd64            GNU Bourne Again SHell
ii  bc          1.06.95-9build2  amd64            GNU bc arbitrary precision calculator language
ii  gawk        1:4.1.4+dfsg-1   amd64            GNU awk, a pattern scanning and processing language
ii  wget        1.19.1-3ubuntu1. amd64            retrieves files from the web
ii  whiptail    0.52.18-3ubunt   amd64            Displays user-friendly dialog boxes from sh
ii  zenity      3.24.0-1         amd64            Display graphical dialog boxes from shell scripts
```

## Parameters



## Dataset

As a data scientist, data engineer, trader, enthusiast or student having full knowledge of your dataset is important. The dataset created by QA.d is described as:

- Data source : Yahoo! Finance Canada;

- Prices are described at the 6th decimal point;
- Prices currency is CAD$;
- Date field is formated as : ```YYYY-MM-DD```;
- No data available prior to 1996;
- Columns headers are stripped from the dataset;
    - Insert ```SYMBOL,DATE,OPEN,HIGH,LOW,CLOSE,ADJ_CLOSE,VOLUME``` in first row if needed;
- Off-trading days (stock markets closed) don't appear in the file;
- The best data resolution offered by Y!Finance with this method is *Daily Freq*;
- Line feed is Unix '\n';

Raw content example :
```
ZOM.V,2017-12-01,3.000000,3.100000,2.750000,2.750000,2.750000,51200
ZOM.V,2017-12-04,3.000000,3.000000,3.000000,3.000000,3.000000,1000
ZOM.V,2017-12-05,3.000000,3.000000,2.400000,2.450000,2.450000,12800
ZOM.V,2017-12-06,2.940000,2.950000,2.710000,2.750000,2.750000,7100
```

Formated content example:

| TICKER | DATE       | OPEN     | HIGH     | LOW      | CLOSE<sup>1</sup> | ADJ CLOSE<sup>2</sup> | VOLUME |
| -----  | -----      | -----    | -----    | ------   | ------            | ------                | -----  |
| ZOM.V  | 2017-12-01 | 3.000000 | 3.100000 | 2.750000 | 2.750000          | 2.750000              | 51200  |
| ZOM.V  | 2017-12-04 | 3.000000 | 3.000000 | 3.000000 | 3.000000          | 3.000000              | 1000   |
| ZOM.V  | 2017-12-05 | 3.000000 | 3.000000 | 2.400000 | 2.450000          | 2.450000              | 12800  |
| ZOM.V  | 2017-12-06 | 2.940000 | 2.950000 | 2.710000 | 2.750000          | 2.750000              | 7100   |

<sup>1 Close price adjusted for splits. </sup>

<sup>2 Adjusted close price adjusted for both dividends and splits. </sup>


## Examples

I used the *TSX.ini* (provided in /examples) with a ```Start Date``` of 1971 and got a 251M dataset containing 3,744,812 observations on 1489 stocks. My runtime was 24 minutes for which half (~13 minutes) was for ```sleep```. I would not recommend removing the ```sleep 0.5``` in the loop since you could get IP/hostname/username blocked.

The QAd_dataset.csv provided in the /examples shows what the dataset looks like. 

I'm providing some Stocks.ini files for testing:
- Test_mini.ini         (67 random stocks from TSX)
- Test_medium.ini       (314 random stocks from TSX)
- TSX.ini               (1489 stocks from the TSX)
- TSXV.ini              (1522 stocks from the TSX Venture)
- TSX_TSXV_complete.ini (3011 stocks from TSX and TSXV)

**Stock types excluded from the files**

My Stocks.ini files exclude most exotic tickers like ".PR." ".F." ".WT." ".DB." and should include all "common stocks" for their relative stock exchanges. I do not provide support on those files but feel free to add better ones if you have.

I won't explain here what are these types of stocks but you can read [this page on Investopedia](https://www.investopedia.com/university/stocks/stocks2.asp) for more information.

| Ticker code | Describes                    | Status   |
| ----------- | ---------------------------- | -------- |
| .UN.        | Real estate investment trust / Income Fund | Included |
| .PR.,PF,PS  | Preferred shares             | Excluded |
| .WT.        | Warrant                      | Excluded |
| .NT.        | Notes                        | Excluded |
| .A.         | Class                        | Included |
| .B.         | Class                        | Included |
| .C.         | Class                        | Included |
| .D.         | Class                        | Included |
| .F.         | Founders                     | Excluded |
| .L.         | Legended                     | Excluded |
| .N.         | Subscription Receipts 2nd iss| Excluded |
| .R.         | Subscription Receipts        | Excluded |
| .U.         | USD$                         | Excluded |
| .X.         | Class                        | Excluded |
| .Y.         | Redeemable commons           | Excluded |
| .DB.        | Debentures                   | Excluded |


## Command_line

The command line script don't ask for a start date. This is because the ```START DATE``` is always *GMT: Friday, January 1, 1971 12:00:00 AM* and the ```END DATE``` is *Today at midnight* thus downloading a full history for your Stocklist file. There's a sleep timer of 0.5 second between downloads which I find from experience does not lock my IP out of Yahoo.

Usage of the command line script (*qad.sh*) is:
```bash
$ ./qad.sh -u "user@yahoo" -p "password" -l "stocklist.ini"
```

Output looks like the following:
```bash
user@localhost:/github/data-scientia/QA.d $ ./qad.sh -u "user@yahoo" -p "password" -l "stocklist.ini" -V
```

==================================================================================
QA.d downloader 1.3 -- Your dataset file is: QAd_dataset-20180403.csv
QA.d downloader 1.3 -- Your parameter file is : TSX.ini
==================================================================================

Downloading data for:  AAB.TO
Downloading data for:  AAR-UN.TO
            [...]
Downloading data for:  PSA.TO
Downloading data for:  PSB.TO
            [...]
Downloading data for:  ZYME.TO
Downloading data for:  ZZZ.TO

==================================================================================
Download completed. Historical financial information for 1489 stocks.
File name is : QAd_DATA-20180403.csv File has 3744812 lines for a size of 251M
Runtime was  1431  seconds.
==================================================================================
```
