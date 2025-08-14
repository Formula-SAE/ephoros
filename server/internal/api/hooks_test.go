package api

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestGetSensorDataFromTopic(t *testing.T) {
	tests := []struct {
		topic       string
		expected    *SensorData
		expectError bool
		errorMsg    string
	}{
		{
			topic: "section1/module2/sensor3",
			expected: &SensorData{
				Section: "section1",
				Module:  "module2",
				Sensor:  "sensor3",
			},
			expectError: false,
		},
		{
			topic: "section_1/module_2/sensor_3",
			expected: &SensorData{
				Section: "section_1",
				Module:  "module_2",
				Sensor:  "sensor_3",
			},
			expectError: false,
		},
		{
			topic: "Section1/Module2/Sensor3",
			expected: &SensorData{
				Section: "Section1",
				Module:  "Module2",
				Sensor:  "Sensor3",
			},
			expectError: false,
		},
		{
			topic: "building1/floor2/temperature",
			expected: &SensorData{
				Section: "building1",
				Module:  "floor2",
				Sensor:  "temperature",
			},
			expectError: false,
		},
		{
			topic: "zone_a/room_101/humidity",
			expected: &SensorData{
				Section: "zone_a",
				Module:  "room_101",
				Sensor:  "humidity",
			},
			expectError: false,
		},
		{
			topic:       "section1/module2",
			expected:    nil,
			expectError: true,
			errorMsg:    "invalid topic: section1/module2",
		},
		{
			topic:       "section1/module2/sensor3/extra",
			expected:    nil,
			expectError: true,
			errorMsg:    "invalid topic: section1/module2/sensor3/extra",
		},
		{
			topic:       "raw/section1/module2/sensor3",
			expected:    nil,
			expectError: true,
			errorMsg:    "invalid topic: raw/section1/module2/sensor3",
		},
		{
			topic:       "processed/section1/module2/sensor3",
			expected:    nil,
			expectError: true,
			errorMsg:    "invalid topic: processed/section1/module2/sensor3",
		},
		{
			topic:       "",
			expected:    nil,
			expectError: true,
			errorMsg:    "invalid topic: ",
		},
		{
			topic:       "section1",
			expected:    nil,
			expectError: true,
			errorMsg:    "invalid topic: section1",
		},
		{
			topic:       "section1/module2/sensor3/extra/another",
			expected:    nil,
			expectError: true,
			errorMsg:    "invalid topic: section1/module2/sensor3/extra/another",
		},
	}

	for _, tt := range tests {
		result, err := getSensorDataFromTopic(tt.topic)

		if tt.expectError {
			assert.Error(t, err)
			if tt.errorMsg != "" {
				assert.Equal(t, tt.errorMsg, err.Error())
			}
			assert.Nil(t, result)
		} else {
			assert.NoError(t, err)
			assert.NotNil(t, result)
			assert.Equal(t, tt.expected.Section, result.Section)
			assert.Equal(t, tt.expected.Module, result.Module)
			assert.Equal(t, tt.expected.Sensor, result.Sensor)
		}
	}
}
