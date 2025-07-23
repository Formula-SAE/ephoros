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

type Config struct {
	SensorConfigs []SensorConfig `json:"sensors"`
}

func NewConfig(configs []SensorConfig) *Config {
	return &Config{SensorConfigs: configs}
}

func NewConfigFromReader(reader io.Reader) (*Config, error) {
	config := &Config{}

	err := json.NewDecoder(reader).Decode(config)
	if err != nil {
		return nil, err
	}

	for i, sConfig := range config.SensorConfigs {
		if !sConfig.Validate() {
			return nil, fmt.Errorf("config nº%d not valid", i)
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
