
# Analyzing RFM95 LoRa module

## First approach
In the first attempt we try to use [this library](https://github.com/sandeepmistry/arduino-LoRa), which is an Arduino library. Actually we were able to send data. But it was very simple and we do not have so much control of the LoRa module. 


## Let's start from scratch
We prefer to build our library using SPI protocol to set the module properly.

Our main reference is located in ```docs/RFM95_96_97_98W.pdf```. That pdf provide a full detailed description of the module: register addresses, signal modulation, tuning parameters and so on.

Since the goal is transmitting data over radio frequency, the most important thing to understand is how the signal is build and how to fine tune it.

### Signal Parameters

#### Bandwidth
