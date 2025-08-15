package mqtt

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"log"
	"strings"
	"time"

	"github.com/ApexCorse/ephoros/server/internal/db"
	mqtt "github.com/mochi-mqtt/server/v2"
	"github.com/mochi-mqtt/server/v2/packets"
)

type SensorData struct {
	Section string `json:"section"`
	Module  string `json:"module"`
	Sensor  string `json:"sensor"`
}

type DataHook struct {
	mqtt.HookBase
	db *db.DB
}

func (h *DataHook) ID() string {
	return "data"
}

func (h *DataHook) Provides(b byte) bool {
	return true
}

func (h *DataHook) OnPublish(cl *mqtt.Client, pk packets.Packet) (packets.Packet, error) {
	sensorsData, err := getSensorDataFromTopic(pk.TopicName)
	if err != nil {
		log.Printf("error getting sensor data from topic: %s", err)
		return pk, err
	}

	sensor, err := h.db.GetSensorByNameAndModuleAndSection(
		sensorsData.Sensor,
		sensorsData.Module,
		sensorsData.Section,
		time.Now(),
		time.Now(),
	)
	if err != nil {
		log.Printf("error getting sensor: %s", err)
		return pk, err
	}

	if len(pk.Payload) != 8 {
		log.Printf("invalid payload length: %d", len(pk.Payload))
		return pk, fmt.Errorf("invalid payload length: %d", len(pk.Payload))
	}

	timestampBytes := pk.Payload[:4]
	timestamp := binary.BigEndian.Uint32(timestampBytes)
	time := time.Unix(int64(timestamp), 0)

	valueBytes := pk.Payload[4:]
	var value float32
	err = binary.Read(bytes.NewReader(valueBytes), binary.LittleEndian, &value)
	if err != nil {
		log.Printf("error reading value from payload: %s", err)
		return pk, err
	}

	record := &db.Record{
		SensorID:  sensor.ID,
		Value:     value,
		CreatedAt: time,
	}

	err = h.db.InsertRecord(record)
	if err != nil {
		log.Printf("error inserting record: %s", err)
		return pk, err
	}

	return pk, nil
}

func getSensorDataFromTopic(topic string) (*SensorData, error) {
	parts := strings.Split(topic, "/")

	if len(parts) != 3 {
		return nil, fmt.Errorf("invalid topic: %s", topic)
	}

	return &SensorData{
		Section: parts[0],
		Module:  parts[1],
		Sensor:  parts[2],
	}, nil
}
