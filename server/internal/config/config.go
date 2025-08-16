package config

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
)

type SensorConfig struct {
	Name    string `json:"name"`
	ID      uint   `json:"id"`
	Section string `json:"section"`
	Module  string `json:"module"`
	Type    uint   `json:"type"`
}

func (c *SensorConfig) Validate() bool {
	log.Printf("[CONFIG] Validating sensor config - Name: %s, ID: %d, Section: %s, Module: %s, Type: %d",
		c.Name, c.ID, c.Section, c.Module, c.Type)

	isValid := c.Name != "" && c.Section != "" && c.Module != ""

	if !isValid {
		log.Printf("[CONFIG] Sensor config validation failed - Name: %s, Section: %s, Module: %s",
			c.Name, c.Section, c.Module)
	} else {
		log.Printf("[CONFIG] Sensor config validation successful - Name: %s", c.Name)
	}

	return isValid
}

type MQTTUserConfig struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

func (c *MQTTUserConfig) Validate() bool {
	log.Printf("[CONFIG] Validating MQTT user config - Username: %s", c.Username)

	isValid := c.Username != "" && c.Password != ""

	if !isValid {
		log.Printf("[CONFIG] MQTT user config validation failed - Username: %s, Password provided: %t",
			c.Username, c.Password != "")
	} else {
		log.Printf("[CONFIG] MQTT user config validation successful - Username: %s", c.Username)
	}

	return isValid
}

type Config struct {
	SensorConfigs []SensorConfig   `json:"sensors"`
	MQTT          []MQTTUserConfig `json:"mqtt"`
}

func NewConfig(configs []SensorConfig, mqtt []MQTTUserConfig) *Config {
	log.Printf("[CONFIG] Creating new configuration - Sensors: %d, MQTT user configs: %d",
		len(configs), len(mqtt))

	config := &Config{SensorConfigs: configs, MQTT: mqtt}

	log.Println("[CONFIG] Configuration created successfully")
	return config
}

func NewConfigFromReader(reader io.Reader) (*Config, error) {
	log.Println("[CONFIG] Loading configuration from reader")

	config := &Config{}

	err := json.NewDecoder(reader).Decode(config)
	if err != nil {
		log.Printf("[CONFIG] Error decoding JSON configuration: %v", err)
		return nil, err
	}

	log.Printf("[CONFIG] JSON decoded successfully - Sensors: %d, MQTT configs: %d",
		len(config.SensorConfigs), len(config.MQTT))

	log.Println("[CONFIG] Validating sensor configurations")
	for i, sConfig := range config.SensorConfigs {
		if !sConfig.Validate() {
			log.Printf("[CONFIG] Sensor config validation failed at index %d", i+1)
			return nil, fmt.Errorf("config nº%d not valid", i+1)
		}
	}

	log.Println("[CONFIG] Validating MQTT configurations")
	for i, mConfig := range config.MQTT {
		if !mConfig.Validate() {
			log.Printf("[CONFIG] MQTT config validation failed at index %d", i+1)
			return nil, fmt.Errorf("mqtt config nº%d not valid", i+1)
		}
	}

	log.Println("[CONFIG] All configurations validated successfully")
	return config, nil
}

func (c *Config) GetSensorConfigByID(id uint) (*SensorConfig, error) {
	log.Printf("[CONFIG] Searching for sensor config with ID: %d", id)

	for _, sConfig := range c.SensorConfigs {
		if sConfig.ID == id {
			log.Printf("[CONFIG] Found sensor config - ID: %d, Name: %s, Section: %s, Module: %s",
				sConfig.ID, sConfig.Name, sConfig.Section, sConfig.Module)
			return &sConfig, nil
		}
	}

	log.Printf("[CONFIG] Sensor config not found with ID: %d", id)
	return nil, errors.New("sensor not found")
}
