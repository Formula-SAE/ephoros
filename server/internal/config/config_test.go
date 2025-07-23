package config

import (
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestSensorConfigValidate(t *testing.T) {
	tests := []struct {
		config     *SensorConfig
		shouldPass bool
	}{
		{
			config: &SensorConfig{
				Name:    "NTC-1",
				ID:      1,
				Section: "Battery",
				Module:  "Module 1",
				Type:    0,
			},
			shouldPass: true,
		},
		{
			config: &SensorConfig{
				Name:    "",
				ID:      1,
				Section: "Battery",
				Module:  "Module 1",
				Type:    0,
			},
			shouldPass: false,
		},
		{
			config: &SensorConfig{
				Name:    "NTC-1",
				ID:      1,
				Section: "",
				Module:  "Module 1",
				Type:    0,
			},
			shouldPass: false,
		},
		{
			config: &SensorConfig{
				Name:    "NTC-1",
				ID:      1,
				Section: "Battery",
				Module:  "",
				Type:    0,
			},
			shouldPass: false,
		},
	}

	for _, test := range tests {
		res := test.config.Validate()

		assert.Equal(t, res, test.shouldPass)
	}
}

func TestNewConfigFromReader(t *testing.T) {
	tests := []struct {
		readerString string
		nConfigs     int
		returnsError bool
	}{
		{
			readerString: `
		{
			"sensors": [
				{
					"name": "NTC-1",
					"id": 1,
					"section": "Battery",
					"module": "Module 1",
					"type": 1
				},
				{
					"name": "NTC-2",
					"id": 2,
					"section": "Battery",
					"module": "Module 1",
					"type": 1
				},
				{
					"name": "NTC-3",
					"id": 3,
					"section": "Battery",
					"module": "Module 1",
					"type": 1
				}
			]
		}
			`,
			nConfigs:     3,
			returnsError: false,
		},
		{
			// error in curly braces
			readerString: `
		{
			"sensors": [
				{}
					"name": "NTC-1",
					"id": 1,
					"section": "Battery",
					"module": "Module 1",
					"type": 1
				},
				{
					"name": "NTC-2",
					"id": 2,
					"section": "Battery",
					"module": "Module 1",
					"type": 1
				},
				{
					"name": "NTC-3",
					"id": 3,
					"section": "Battery",
					"module": "Module 1",
					"type": 1
				}
			]
		}
			`,
			returnsError: true,
		}, {
			// missing name in third config
			readerString: `
		{
			"sensors": [
				{
					"name": "NTC-1",
					"id": 1,
					"section": "Battery",
					"module": "Module 1",
					"type": 1
				},
				{
					"name": "NTC-2",
					"id": 2,
					"section": "Battery",
					"module": "Module 1",
					"type": 1
				},
				{
					"name": "",
					"id": 3,
					"section": "Battery",
					"module": "Module 1",
					"type": 1
				}
			]
		}
			`,
			nConfigs:     3,
			returnsError: true,
		},
	}

	for _, test := range tests {
		reader := strings.NewReader(test.readerString)
		config, err := NewConfigFromReader(reader)

		if !test.returnsError {
			assert.Nil(t, err)
			assert.Len(t, config.SensorConfigs, test.nConfigs)
		} else {
			assert.Error(t, err)
		}
	}
}

func TestGetSensorConfigByID(t *testing.T) {
	tests := []struct {
		config     *Config
		id         uint
		shouldPass bool
		name       string
	}{
		{
			config: &Config{
				SensorConfigs: []SensorConfig{
					{
						Name: "NTC-1",
						ID:   1,
					},
					{
						Name: "NTC-2",
						ID:   2,
					}, {
						Name: "NTC-1",
						ID:   3,
					},
				},
			},
			id:         1,
			shouldPass: true,
			name:       "NTC-1",
		},
		{
			config: &Config{
				SensorConfigs: []SensorConfig{
					{
						Name: "NTC-1",
						ID:   1,
					},
					{
						Name: "NTC-2",
						ID:   2,
					}, {
						Name: "NTC-1",
						ID:   3,
					},
				},
			},
			id:         4,
			shouldPass: false,
		},
	}

	for _, test := range tests {
		sConfig, err := test.config.GetSensorConfigByID(test.id)

		if test.shouldPass {
			assert.Nil(t, err)
			assert.Equal(t, sConfig.Name, test.name)
		} else {
			assert.Error(t, err)
			assert.Nil(t, sConfig)
		}
	}
}
