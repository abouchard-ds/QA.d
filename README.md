![Logo](media/qad_logo2.png)
Historical Stock Market Data Downloader for Quantitative Analysis or general dataset creation.

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
- [Examples](#examples)
- [Acknowledgments](#acknowledgments)

## Introduction

[![Bash Status](https://img.shields.io/badge/bash-4.4.12-blue.svg)](https://img.shields.io/badge/bash-4.4.12-blue.svg)
[![zenity Status](https://img.shields.io/badge/zenity-3.24.0-pink.svg)](https://img.shields.io/badge/zenity-3.24.0-pink.svg)

QA.D Downloader is a small bash script to automatically download historical data for stocks from Yahoo Finance (as data source) and format it as CSV file. It has a small GUI made with zenity. You can download historical data from anytime until yesterday at midnight. For the moment you will need to edit the *stock_config.ini* to select your own stocks.

This is the stepping stone to a greater project for a complete Quants solution from scratch.

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

```bash

validate if you have all prerequisites;

```

## Examples
File provided in the examples folder was generated on April 2 2018 using *"tsx_tsxv.ini"* with a *"Start Date"* of January 1 2018.

Stocks ini files provided for testing are:
- tsx_minimal.ini
- tsxv_minimal.ini
- tsx_tsxv.ini

## Acknowledgments
