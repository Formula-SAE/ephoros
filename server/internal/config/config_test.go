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

		assert.Equal(t, test.shouldPass, res)
	}
}

func TestMQTTUserConfigValidate(t *testing.T) {
	tests := []struct {
		config     *MQTTUserConfig
		shouldPass bool
	}{
		{
			config: &MQTTUserConfig{
				Username: "Apex",
				Password: "Corse",
			},
			shouldPass: true,
		},
		{
			config: &MQTTUserConfig{
				Username: "",
				Password: "Corse",
			},
			shouldPass: false,
		},
		{
			config: &MQTTUserConfig{
				Username: "Apex",
				Password: "",
			},
			shouldPass: false,
		},
		{
			config: &MQTTUserConfig{
				Username: "",
				Password: "",
			},
			shouldPass: false,
		},
	}

	for _, test := range tests {
		res := test.config.Validate()

		assert.Equal(t, test.shouldPass, res)
	}
}

func TestNewConfigFromReader(t *testing.T) {
	tests := []struct {
		readerString string
		nConfigs     int
		nMQTT        int
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
			nMQTT:        0,
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
			nMQTT:        0,
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
			nMQTT:        0,
			returnsError: true,
		},
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
				}
			],
			"mqtt": [
				{
					"username": "user1",
					"password": "pass1"
				},
				{
					"username": "user2",
					"password": "pass2"
				}
			]
		}
			`,
			nConfigs:     1,
			nMQTT:        2,
			returnsError: false,
		},
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
				}
			],
			"mqtt": [
				{
					"username": "",
					"password": "pass1"
				}
			]
		}
			`,
			nConfigs:     1,
			nMQTT:        1,
			returnsError: true,
		},
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
				}
			],
			"mqtt": [
				{
					"username": "user1",
					"password": ""
				}
			]
		}
			`,
			nConfigs:     1,
			nMQTT:        1,
			returnsError: true,
		},
		{
			readerString: `
		{
			"sensors": [
				{
					"name": "Temperature-1",
					"id": 1,
					"section": "Engine",
					"module": "Thermal",
					"type": 2
				},
				{
					"name": "Pressure-1",
					"id": 2,
					"section": "Engine",
					"module": "Hydraulic",
					"type": 3
				},
				{
					"name": "Voltage-1",
					"id": 3,
					"section": "Electrical",
					"module": "Power",
					"type": 4
				}
			],
			"mqtt": [
				{
					"username": "admin",
					"password": "secure123"
				},
				{
					"username": "monitor",
					"password": "readonly456"
				},
				{
					"username": "operator",
					"password": "control789"
				}
			]
		}
			`,
			nConfigs:     3,
			nMQTT:        3,
			returnsError: false,
		},
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
				}
			],
			"mqtt": [
				{
					"username": "user1",
					"password": "pass1"
				},
				{
					"username": "user2"
					"password": "pass2"
				}
			]
		}
			`,
			nMQTT:        2,
			returnsError: true,
		},
		{
			readerString: `
		{
			"sensors": [],
			"mqtt": []
		}
			`,
			nConfigs:     0,
			nMQTT:        0,
			returnsError: false,
		},
	}

	for _, test := range tests {
		reader := strings.NewReader(test.readerString)
		config, err := NewConfigFromReader(reader)

		if !test.returnsError {
			assert.Nil(t, err)
			assert.Len(t, config.SensorConfigs, test.nConfigs)
			assert.Len(t, config.MQTT, test.nMQTT)
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
			assert.Equal(t, test.name, sConfig.Name)
		} else {
			assert.Error(t, err)
			assert.Nil(t, sConfig)
		}
	}
}
