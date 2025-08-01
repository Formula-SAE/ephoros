package api

import (
	"strings"
	"time"
)

type DataRequestBody struct {
	Section string `json:"section"`
	Module  string `json:"module"`
	Sensor  string `json:"sensor"`

	From time.Time `json:"from"`
	To   time.Time `json:"to"`
}

func (b *DataRequestBody) Validate() bool {
	return b.Section != "" && b.Module != "" && b.Sensor != ""
}

type RealTimeRecord struct {
	Section string    `json:"section"`
	Module  string    `json:"module"`
	Sensor  string    `json:"sensor"`
	Value   float64   `json:"value"`
	Time    time.Time `json:"time"`
}

type RealTimeRequest struct {
	Section string `json:"section"`
	Module  string `json:"module"`
	Sensor  string `json:"sensor"`
	Track   bool   `json:"track"`
}

func (r *RealTimeRequest) Validate() bool {
	return r.Section != "" && r.Module != "" && r.Sensor != ""
}

type RealTimeRequestMap struct {
	requests map[string]*RealTimeRequest
}

func NewRealTimeRequestMap(requests map[string]*RealTimeRequest) *RealTimeRequestMap {
	return &RealTimeRequestMap{
		requests: requests,
	}
}

func (m *RealTimeRequestMap) Add(req *RealTimeRequest) {
	m.requests[strings.Join([]string{req.Section, req.Module, req.Sensor}, "-")] = req
}

func (m *RealTimeRequestMap) Remove(req *RealTimeRequest) {
	delete(m.requests, strings.Join([]string{req.Section, req.Module, req.Sensor}, "-"))
}

func (m *RealTimeRequestMap) Find(section, module, sensor string) *RealTimeRequest {
	key := strings.Join([]string{section, module, sensor}, "-")
	return m.requests[key]
}