package config

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
)

type SensorConfig struct {
	Name    string `json:"name"`
	ID      uint   `json:"id"`
	Section string `json:"section"`
	Module  string `json:"module"`
	Type    uint   `json:"type"`
}

func (c *SensorConfig) Validate() bool {
	return c.Name != "" && c.Section != "" && c.Module != ""
}

type MQTTConfig struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

func (c *MQTTConfig) Validate() bool {
	return c.Username != "" && c.Password != ""
}

type Config struct {
	SensorConfigs []SensorConfig `json:"sensors"`
	MQTT          []MQTTConfig   `json:"mqtt"`
}

func NewConfig(configs []SensorConfig, mqtt []MQTTConfig) *Config {
	return &Config{SensorConfigs: configs, MQTT: mqtt}
}

func NewConfigFromReader(reader io.Reader) (*Config, error) {
	config := &Config{}

	err := json.NewDecoder(reader).Decode(config)
	if err != nil {
		return nil, err
	}

	for i, sConfig := range config.SensorConfigs {
		if !sConfig.Validate() {
			return nil, fmt.Errorf("config nº%d not valid", i+1)
		}
	}

	for i, mConfig := range config.MQTT {
		if !mConfig.Validate() {
			return nil, fmt.Errorf("mqtt config nº%d not valid", i+1)
		}
	}

	return config, nil
}

func (c *Config) GetSensorConfigByID(id uint) (*SensorConfig, error) {
	for _, sConfig := range c.SensorConfigs {
		if sConfig.ID == id {
			return &sConfig, nil
		}
	}

	return nil, errors.New("sensor not found")
}
