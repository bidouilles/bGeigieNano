# Welcome to xGeigie Nano project

This is a lighter version of the bGeigie Mini using a LND 712 geiger tube.

# Requirements
* [Arduino Fio][3]
* [OpenLog][1]
* Adafruit [Ultimate GPS][7]
* [LND712][4] geiger tube with Medcom iRover HV board
* [Nokia 5110][2] LCD screen
* 3.7V 1000mAh Lithium battery

# Assembly

![xGeigieNano](https://github.com/bidouilles/bGeigieNano/raw/xGeigieNano/assembly/xGeigieNano_kit_600.jpg)

## Pins assignment

| Arduino pin | Attached to |
| :-----------: | :-----------: |
| VCC | VCC pin of the GPS and OpenLog |
| GND | GND pin of the GPS and OpenLog |
| D2 | pulse pin from the Inspector audio jack |
| D3 | Nokia 5110 RST pin |
| D4 | Nokia 5110 CS pin |
| D5 | Nokia 5110 DC pin |
| D6 | Nokia 5110 DIN pin |
| D7 | Nokia 5110 CLK pin |
| D8 | TX pin of the GPS |
| D9 | RX pin of the GPS |
| D10 | TX pin of the OpenLog |
| D11 | RX pin of the OpenLog |
| D12 | GRN pin of the OpenLog |

# Build process
## Using the Makefile
    export ARDUINODIR=/home/geigie/arduino-1.0.1/
    export SERIALDEV=/dev/ttyUSB0
    export BOARD=fio
    make
    make upload

## Using the prebuilt image
You can use directly the prebuilt image to flash the Arduino Fio. Here is an example with Arduino Fio connected to ttyUSB0:

    /usr/bin/avrdude -DV -p atmega328p -P /dev/ttyUSB0 -c arduino -b 57600 -U flash:w:bGeigieNano.hex:i

# Usage
Once powered on the bGeigieNano will initiliaze a new log file on the SD card, setup the GPS and start counting the CPM.

# Sample log

    # NEW LOG
    # format=1.0.0nano
    $BNRDD,1,2012-07-05T12:02:36Z,4,3,4,V,3543.1917,N,13942.0190,E,25.30,A,9999,0*69
    $BNRDD,1,2012-07-05T12:02:41Z,5,1,5,V,3543.1909,N,13942.0200,E,25.30,A,9999,0*6E
    $BNRDD,1,2012-07-05T12:02:41Z,7,2,7,V,3543.1909,N,13942.0200,E,25.30,A,9999,0*6D
    $BNRDD,1,2012-07-05T12:02:41Z,11,4,11,V,3543.1909,N,13942.0200,E,25.30,A,9999,0*6B
    $BNRDD,1,2012-07-05T12:02:41Z,13,2,13,V,3543.1909,N,13942.0200,E,25.30,A,9999,0*6D
    $BNRDD,1,2012-07-05T12:03:02Z,14,1,14,V,3543.1687,N,13942.0260,E,25.30,A,367,4*51
    $BNRDD,1,2012-07-05T12:03:07Z,18,4,18,V,3543.1636,N,13942.0280,E,25.30,A,367,4*55
    $BNRDD,1,2012-07-05T12:03:12Z,19,1,19,V,3543.1624,N,13942.0290,E,25.40,A,368,4*5E
    $BNRDD,1,2012-07-05T12:03:18Z,23,4,23,V,3543.1609,N,13942.0290,E,25.40,A,369,4*5F
    $BNRDD,1,2012-07-05T12:03:23Z,28,5,28,V,3543.1616,N,13942.0290,E,25.40,A,369,4*58
    $BNRDD,1,2012-07-05T12:03:28Z,30,2,30,V,3543.1628,N,13942.0280,E,25.40,A,370,4*50
    $BNRDD,1,2012-07-05T12:03:33Z,32,3,33,A,3543.1628,N,13942.0280,E,25.40,A,370,4*4D
    $BNRDD,1,2012-07-05T12:03:38Z,31,2,35,A,3543.1616,N,13942.0290,E,25.40,A,371,4*4F
    $BNRDD,1,2012-07-05T12:03:43Z,33,3,38,A,3543.1604,N,13942.0290,E,25.40,A,372,4*4D
    $BNRDD,1,2012-07-05T12:03:48Z,32,1,39,A,3543.1604,N,13942.0290,E,25.40,A,372,4*44
    $BNRDD,1,2012-07-05T12:03:53Z,31,3,42,A,3543.1653,N,13942.0260,E,25.40,A,353,5*4C
    $BNRDD,1,2012-07-05T12:03:58Z,32,3,45,A,3543.1653,N,13942.0270,E,25.40,A,353,5*42
    $BNRDD,1,2012-07-05T12:04:03Z,34,3,48,A,3543.1638,N,13942.0270,E,25.40,A,151,6*4E
    $BNRDD,1,2012-07-05T12:04:09Z,32,2,50,A,3543.1682,N,13942.0250,E,28.50,A,140,7*44
    $BNRDD,1,2012-07-05T12:04:14Z,33,2,52,A,3543.1682,N,13942.0240,E,26.80,A,140,7*49
    $BNRDD,1,2012-07-05T12:04:19Z,34,5,57,A,3543.1670,N,13942.0240,E,26.30,A,140,7*47
    $BNRDD,1,2012-07-05T12:04:25Z,31,2,59,A,3543.1658,N,13942.0240,E,26.00,A,140,7*4D

# Notes
## OpenLog config

The OpenLog should start listening at 9600bps and in Command mode. Here is the content of the CONFIG.TXT file you have to create on the microSD card:

    9600,26,3,2

## SoftwareSerial update

To make sure all of the NMEA sentences can be received correctly, we will need to update the _SS_MAX_RX_BUFF definition from arduino-1.0.1/libraries/SoftwareSerial/SoftwareSerial.h header file. Here is the modification:

    //#define _SS_MAX_RX_BUFF 64 // RX buffer size -- Old Value is 64
    #define _SS_MAX_RX_BUFF 128 // RX buffer size for TinyGPS

# Licenses
 * [InterruptHandler and bGeigieMini code][5] - Copyright (c) 2011, Robin Scheibler aka FakuFaku
 * [TinyGPS][6] - Copyright (C) 2008-2012 Mikal Hart
 * bGeigieNano - Copyright (c) 2012, Lionel Bergeret
 * [Makefile][8] - Copyright (c) 2012, Tim Marston


  [1]: https://github.com/sparkfun/OpenLog "OpenLog"
  [2]: https://www.adafruit.com/products/338 "Nokia 5110"
  [3]: https://www.sparkfun.com/products/10116 "Arduino Fio"
  [4]: http://www.lndinc.com/products/711/ "LND712"
  [5]: https://github.com/fakufaku/SafecastBGeigie-firmware "SafecastBGeigie-firmware"
  [6]: http://arduiniana.org/libraries/tinygps/ "TinyGPS"
  [7]: https://www.adafruit.com/products/746 "Ultimate GPS"
  [8]: http://ed.am/dev/make/arduino-mk "Arduino Makefile"
