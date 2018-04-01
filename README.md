# QASMS Downloader v1.0

Historical Stock Market Data Downloader for Quantitative Analysis or general dataset creation.

## Summary
QASMS_downloader (quantitative analysis stock market software) is a small bash script to automatically download historical data for stocks from Yahoo Finance (as data source). It has a small GUI made with zenity. You can download historical data from the ~1970 until yesterday at midnight. It downloads the data per stock so I will add a stock picker window in the future. For the moment you will need to edit the array "arr" in the script to select your own stocks. 

![Main configuration dialog](qasms_1.0_config.png?raw=true "Main configuration dialog")

## Pre-requisites
The program has been developed and tested on Ubuntu 17.10. The following are used by the script. Nothing fancy, was default install on Ubuntu 17.10.

* [Yahoo! Finance Account](https://login.yahoo.com/config/login?.intl=ca&.lang=en-CA&.src=finance&.done=https%3A%2F%2Fca.finance.yahoo.com%2F)

* bash 4.4.12
* zenity 3.24.0
* bc 1.06.95
* awk 4.1.4
* date 8.26
* wget 1.19.1

Developed with geany 1.31.
