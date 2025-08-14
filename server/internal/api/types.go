package api

import (
	"time"
)

type SensorData struct {
	Section string `json:"section"`
	Module  string `json:"module"`
	Sensor  string `json:"sensor"`
}

type DataRequestBody struct {
	SensorData

	From time.Time `json:"from"`
	To   time.Time `json:"to"`
}

func (b *DataRequestBody) Validate() bool {
	return b.Section != "" && b.Module != "" && b.Sensor != ""
}
