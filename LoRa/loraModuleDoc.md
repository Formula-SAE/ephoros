
# Analyzing RFM95 LoRa module

## First approach
In the first attempt we try to use [this library](https://github.com/sandeepmistry/arduino-LoRa), which is an Arduino library. Actually we were able to send data. But it was very simple and we do not have so much control of the LoRa module. 


## Let's start from scratch
We prefer to build our library using SPI protocol to set the module properly.

Our main reference is located in ```docs/RFM95_96_97_98W.pdf```. That pdf provide a full detailed description of the module: register addresses, signal modulation, tuning parameters and so on.

Since the goal is transmitting data over radio frequency, the most important thing to understand is how the signal is build and how to fine tune it.

## Modulation of signal
The Lora module can use two types of modulation so we can use it as a FSK/OOK modem or as LoRa modem.

We will use it as a LoRa modem because the receiver and the transmitter are both LoRa modules.

The LoRa modulation and demodulation process is proprietary and it uses spread spectrum factor combined with cyclic error correction coding. The combined influence of these two factors is an increase in link budget and enhanced immunity to interference.

So the LoRa modulation and demodulation process is more robust and it increases range compared to traditional FSK/OOK modulation and demodulation.

### Optimization of LoRa modulation/demodulation
We can optimize the LoRa modulation used three critical design parameters:

* BandWidth;
* Spreading Factor;
* Error coding rate.

Each one permits trade off between link budget, immunity to interference, spectral occupancy and nominal data rate.

#### Spreading Factor
Spreading Factor is the ratio between the nominal symbol rate and chip rate and represents the number of symbols sent per bit of information.

For example, if we have a Spreading Factor = 6, every 6 bits of message give us a symbol.



The Spreading Factor can be configured using the register RegModulationCfg.





