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

func NewDataHook(db *db.DB) *DataHook {
	return &DataHook{
		HookBase: mqtt.HookBase{},
		db:       db,
	}
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
	log.Printf("[MQTT] Processing publish from client %s on topic: %s", cl.ID, pk.TopicName)

	sensorsData, err := getSensorDataFromTopic(pk.TopicName)
	if err != nil {
		log.Printf("[MQTT] Error parsing sensor data from topic '%s': %v", pk.TopicName, err)
		return pk, err
	}

	log.Printf("[MQTT] Extracted sensor data - Section: %s, Module: %s, Sensor: %s",
		sensorsData.Section, sensorsData.Module, sensorsData.Sensor)

	sensor, err := h.db.GetSensorByNameAndModuleAndSection(
		sensorsData.Sensor,
		sensorsData.Module,
		sensorsData.Section,
		time.Now(),
		time.Now(),
	)
	if err != nil {
		log.Printf("[MQTT] Error retrieving sensor from database - Sensor: %s, Module: %s, Section: %s, Error: %v",
			sensorsData.Sensor, sensorsData.Module, sensorsData.Section, err)
		return pk, err
	}

	log.Printf("[MQTT] Found sensor in database - ID: %d, Name: %s", sensor.ID, sensor.Name)

	if len(pk.Payload) != 8 {
		log.Printf("[MQTT] Invalid payload length: %d bytes (expected 8) for topic: %s", len(pk.Payload), pk.TopicName)
		return pk, fmt.Errorf("invalid payload length: %d", len(pk.Payload))
	}

	log.Printf("[MQTT] Processing payload of %d bytes for sensor %s", len(pk.Payload), sensor.Name)

	timestampBytes := pk.Payload[:4]
	timestamp := binary.BigEndian.Uint32(timestampBytes)
	time := time.Unix(int64(timestamp), 0)

	log.Printf("[MQTT] Extracted timestamp: %s (Unix: %d)", time.Format("2006-01-02T15:04:05Z07:00"), timestamp)

	valueBytes := pk.Payload[4:]
	var value float32
	err = binary.Read(bytes.NewReader(valueBytes), binary.LittleEndian, &value)
	if err != nil {
		log.Printf("[MQTT] Error reading value from payload bytes %v: %v", valueBytes, err)
		return pk, err
	}

	log.Printf("[MQTT] Extracted value: %f for sensor %s", value, sensor.Name)

	record := &db.Record{
		SensorID:  sensor.ID,
		Value:     value,
		CreatedAt: time,
	}

	log.Printf("[MQTT] Creating record - SensorID: %d, Value: %f, Timestamp: %s",
		record.SensorID, record.Value, record.CreatedAt.Format("2006-01-02T15:04:05Z07:00"))

	err = h.db.InsertRecord(record)
	if err != nil {
		log.Printf("[MQTT] Error inserting record into database - SensorID: %d, Value: %f, Error: %v",
			record.SensorID, record.Value, err)
		return pk, err
	}

	log.Printf("[MQTT] Successfully inserted record - SensorID: %d, Value: %f, Timestamp: %s",
		record.SensorID, record.Value, record.CreatedAt.Format("2006-01-02T15:04:05Z07:00"))

	return pk, nil
}

func getSensorDataFromTopic(topic string) (*SensorData, error) {
	log.Printf("[MQTT] Parsing topic: %s", topic)

	parts := strings.Split(topic, "/")

	if len(parts) != 3 {
		log.Printf("[MQTT] Invalid topic format - expected 3 parts, got %d: %s", len(parts), topic)
		return nil, fmt.Errorf("invalid topic: %s", topic)
	}

	sensorData := &SensorData{
		Section: parts[0],
		Module:  parts[1],
		Sensor:  parts[2],
	}

	log.Printf("[MQTT] Successfully parsed topic - Section: %s, Module: %s, Sensor: %s",
		sensorData.Section, sensorData.Module, sensorData.Sensor)

	return sensorData, nil
}
