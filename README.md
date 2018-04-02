![Logo](media/qa-d_logo.png)

<p align="center">
  Historical Stock Market Data Downloader for dataset creation.
  <br>
</p>

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
- [Dataset](#dataset)
- [Examples](#examples)
- [Acknowledgments](#acknowledgments)

## Introduction
<p align="center">

  <img src="https://img.shields.io/badge/bash-4.4.12-blue.svg">
  <img src="https://img.shields.io/badge/zenity-3.24.0-green.svg">
  <img src="https://img.shields.io/badge/powered%20by-jekyll-red.svg">

</p>

QA.d (QuantitativeAnalysis.downloader) is a bash script to automatically download historical stocks data from [Yahoo! Finance](https://login.yahoo.com/config/login?.intl=ca&.lang=en-CA&.src=finance&.done=https%3A%2F%2Fca.finance.yahoo.com%2F) (as data source) and format it as CSV file. It uses zenity to create a simple GUI. You can download historical data from anytime until yesterday at midnight (in the extent it is available on Y!Finance).

## Features

## Installation
The program has been developed and tested on [Ubuntu 17.10 Desktop](https://www.ubuntu.com/download/desktop). The following packages are used by the script. Nothing fancy, it was all default install on Ubuntu 17.10.

* [Yahoo! Finance Account](https://login.yahoo.com/config/login?.intl=ca&.lang=en-CA&.src=finance&.done=https%3A%2F%2Fca.finance.yahoo.com%2F)

* bash 4.4.12
* zenity 3.24.0
* bc 1.06.95
* awk 4.1.4
* date 8.26
* wget 1.19.1

To validate if you have the prerequisites:
```bash

dpkg -l bash zenity bc gawk date wget

```

You should a similar return:
```bash
$ dpkg -l bash zenity bc gawk date wget
||/ Name                    Version          Architecture     Description
+++-=======================-================-================-===================================================
ii  bash                    4.4-5ubuntu1     amd64            GNU Bourne Again SHell
ii  bc                      1.06.95-9build2  amd64            GNU bc arbitrary precision calculator language
ii  gawk                    1:4.1.4+dfsg-1   amd64            GNU awk, a pattern scanning and processing language
ii  wget                    1.19.1-3ubuntu1. amd64            retrieves files from the web
ii  zenity                  3.24.0-1         amd64            Display graphical dialog boxes from shell scripts
```

## Dataset

## Examples
File provided in the examples folder was generated on April 2 2018 using *"tsx_tsxv.ini"* with a *"Start Date"* of March 1 2018.

Stocks ini files provided for testing are:
- tsx_minimal.ini
- tsxv_minimal.ini
- tsx_tsxv.ini

Row examples :
Data source : Yahoo! Finance Canada
Currency in CAD$

Where the columns are:
TICKER,DATE,OPEN,HIGH,LOW,CLOSE,ADJ CLOSE,VOLUME

Close price adjusted for splits. Adjusted close price adjusted for both dividends and splits.
```
NTS.V,2018-01-09,1.390000,1.450000,1.350000,1.390000,1.390000,105100
```





## Acknowledgments

This program was created as a simple exercise to practice bash with zenity. Most zenity features are tested in this script.

The dataset generated is still of good use since Yahoo blocked their Finance API.
