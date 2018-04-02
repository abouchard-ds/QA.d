![Logo](media/qa-d_logo.png)

<p align="center">
 *audaces fortuna juvat*
  <br>
</p>

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
- [Dataset](#dataset)
- [Examples](#examples)
- [Pseudocode](#pseudocode)
- [Acknowledgments](#acknowledgments)

## Introduction
<p align="center">

  <img src="https://img.shields.io/badge/bash-4.4.12-blue.svg">
  <img src="https://img.shields.io/badge/zenity-3.24.0-green.svg">
  <img src="https://img.shields.io/badge/powered%20by-jekyll-red.svg">

</p>

QA.d (QuantitativeAnalysis.downloader) is a bash script to automatically download historical stock data from [Yahoo! Finance](https://login.yahoo.com/config/login?.intl=ca&.lang=en-CA&.src=finance&.done=https%3A%2F%2Fca.finance.yahoo.com%2F) (as data source) and format it as CSV file. It uses zenity to create a simple GUI. You can download historical data from anytime until yesterday at midnight (in the extent it is available on Y!Finance).

This program was made as *a learning instrument* for bash scripting, creating simple dialogs with zenity and learning Github w/ Jekyll.

The datasets you can create with this program can become of a sizable amount. If you take all Canadian and American stocks without excluding debentures, warrants, etc. **you could get approximately 2Gb to 5Gb of data**.

## Features

* Easily create datasets **for free**
* Personalize your historical stock datasets
* Almost no dependencies, packages are default
* The GUI follows your personnal Linux theme
* A '*non graphical*' version is also available

## Installation
The program has been developed and tested on [Ubuntu 17.10 Desktop](https://www.ubuntu.com/download/desktop). The following packages are used by the script. Nothing fancy, it was all default install on Ubuntu 17.10.

You'll need to have an account on Y! Finance to be able to download the data.
* [Yahoo! Finance Account](https://login.yahoo.com/config/login?.intl=ca&.lang=en-CA&.src=finance&.done=https%3A%2F%2Fca.finance.yahoo.com%2F)

| packages | description | explanation |
|--|--|--|
| bash 4.4.12 | GNU Bourne Again SHell | you need a new version because of the use of ```readarray``` |
| zenity 3.24.0 | Display graphical dialog boxes from shell scripts | only tested on this version |
| bc 1.06.95 | GNU bc arbitrary precision calculator language | only tested on this version |
| awk 4.1.4 | GNU awk, a pattern scanning and processing language | only tested on this version |
| wget 1.19.1 | retrieves files from the web | note that wget handles stuff with the cookies |

To validate if you have the prerequisites:
```bash
dpkg -l bash zenity bc gawk date wget
```

You should get a somewhat similar return:
```bash
$ dpkg -l bash zenity bc gawk date wget
||/ Name        Version          Architecture     Description
+++-===========-================-================-===================================================
ii  bash        4.4-5ubuntu1     amd64            GNU Bourne Again SHell
ii  bc          1.06.95-9build2  amd64            GNU bc arbitrary precision calculator language
ii  gawk        1:4.1.4+dfsg-1   amd64            GNU awk, a pattern scanning and processing language
ii  wget        1.19.1-3ubuntu1. amd64            retrieves files from the web
ii  zenity      3.24.0-1         amd64            Display graphical dialog boxes from shell scripts
```

## Dataset
As a data scientist or enthusiast having full knowledge of your dataset is important.

Data source : Yahoo! Finance Canada. Currency is CAD$

Row example :
```
NTS.V,2018-01-09,1.390000,1.450000,1.350000,1.390000,1.390000,105100
```
Where the columns are:
TICKER, DATE, OPEN, HIGH, LOW,  CLOSE<sup>1</sup>,  ADJ CLOSE<sup>2</sup>,  VOLUME

<sup>1</sup>Close price adjusted for splits.

<sup>2</sup>Adjusted close price adjusted for both dividends and splits.


## Examples
If you use the provided *tsx_tsxv.ini* and uses a Start Date of 1970, you'll get a file of 285M containing 3,339,114 records on ~1150 stocks.

File provided in the examples folder was generated on April 2 2018 using *"tsx_tsxv.ini"* with a *"Start Date"* of March 1 2018.

Stocks ini files provided for testing are:
- tsx_minimal.ini
- tsxv_minimal.ini
- tsx_tsxv.ini

They exclude most exotic stock ticker like ".PR." ".F." ".WT." ".DB.".

## Pseudocode
Since this was created for learning/academic purpose I will add the pseudocode for a beginner who would like to understand the script and learn from it.

1. Ask user for username, password and start date
    * Validate input password since user can't see in field
    * Validate input that start date is less than yesterday.
2. Ask user where she wants to save the Dataset.CSV
3. Process variables from validated input to forge the URL and the Dataset.CSV
4. Create a ./tmp directory to put our temporary stock files during download
5. Validate that no Dataset file exists for today and create one
6. Read the stock parameter file (*tsx_minimal.ini*) into an array
7. Enter a loop for each stocks :
    * Gives the percentage of progress ```((index/arraySize)*100)``` this controls the zenity progress bar
    * Gives the current stock being downloaded ("# abc" insure zenity uses this echo in it's progress window)
    * Create a temporary stock file
    * Download data into the temporary stock file (wget)
    * Add the stock ticker at the beginning of each lines
    * Remove header and null from temporary stock file
    * Append the temporary file into the final Dataset.CSV
8. Delete all temporary stock file
9. Move the Dataset.CSV to the user specified location.
10. Display a dialog summarizing the job and confirming it has been completed.

## Acknowledgments
This program was created as a simple exercise to practice bash with zenity.
Most zenity features are tested in this script.
This was created from scratch without researching other programs would could do the same (if my code looks like yours - that's a random occurence).
The dataset generated is still of good use since Yahoo blocked their Finance API.
