
# Our Case

Our setup is very simple: transmit data between the vehicle and the team at the station. Since it might be no internet connection, we decide to use LoRa protocol.

---

# LoRa Protocol 

LoRa stands for Long Range. It is a minimal yet so powerful protocol used by IoT devices to communicate each others. It is suitable because it covers a very long range using very low power consumptions. [Main docs](https://lora.readthedocs.io/en/latest/)

## Restrictions

LoRa uses unlicensed frequencies that are available worldwide. For Europe is 868 MHz. Because this band is unlicensed, anyone can freely use it without paying or having to get a license. But users must comply to the following rules:

- For uplink, the maximum transmission power is limited to 25mW (14 dBm).
- For downlink (for 869.525MHz), the maximum transmission power is limited to 0.5W (27 dBm)
- There is an 0.1% and 1.0% duty cycle per day depending on the channel.
- Maximum allowed antenna gain +2.15 dBi.

Translating these result in: limit the range and limit the quality of the signal due to less power transmission and Antenna gain. But more important we cannot flood the channel with our packets. So, we need to be very precise to send what really matter and also divide our data in multiple small packets. In this way we can achive responsivness, infact small packets implies less time of air and so a smaller duty cycle.

##### TL;DR
We tell to the car what we want, so the channel is not flooded. To increase responsivness we send small packets.


## Reliable Data Transfer

The LoRa protocol does not provide a service like TCP: there is no transport layer. So we have to make sure our data are correctly delivered. Actually this is under development...

---

# Embedded Devices

We decide to use two ESP32 microcontroller, one as transmitter and one as receiver. ESP32 is such a cheap and a general purpouse component, that it can be fine tuned for our specific case.

Together with it we are using a LoRa Transceiver module: RFM95. This module communicates via SPI with the ESP32. There is a Arduino library [here](https://github.com/sandeepmistry/arduino-LoRa). Actually we are using it but we will move to a C/C++ library, because we want to have more hardware mangement like threads and memmory.

---

# Architecture

Currently under development, but the are some ideas:

- Both transmitter and receiver share a key, so other incoming packets are discarded (But it will be done a safer check)
- Store the whole state of the Car every TAU
- The team at the station tells exactly what it wants to see, then the Car we will accomplish the request. (Responsivness with no flooding)
- The transmitter will send most recently data, according to the request
- Each section of the Car has a priority, so the request is handled to send the most important first
- To accomplish the request as fast as possible, we need some sort of cache in the RAM. Only if the data is not in there, we look for it in the SD storage
- The SD storage is built in a way the most recently data are fastly retrived
- The whole state of the Car can be sent, but then we must cool down to respect the restrictions
- The transmission need to be reliable (checksum and others to ensure the correct transfer)
- The transmission are encrypted with AES-256 following the CRT operative mode


Note:
The whole state of the Car will be about 20KB. TAU is a time interval that may be static or dynamic and we are deciding it together with the Electronic Divison.