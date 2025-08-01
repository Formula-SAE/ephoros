package api

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/ApexCorse/ephoros/server/internal/db"
	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
	"github.com/stretchr/testify/assert"
)

func TestValidateUser_Success(t *testing.T) {
	gormDb, cleanUp, err := db.TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	api := NewAPI("", db.NewDB(gormDb), mux.NewRouter(), &websocket.Upgrader{}, make(chan *RealTimeRecord))

	user := &db.User{
		Username: "Apex",
		Token:    "Corse",
	}
	gormDb.Create(user)

	err = api.validateUser("Corse")
	assert.Nil(t, err)
}

func TestValidateUser_Failure(t *testing.T) {
	gormDb, cleanUp, err := db.TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	api := NewAPI("", db.NewDB(gormDb), mux.NewRouter(), &websocket.Upgrader{}, make(chan *RealTimeRecord))

	user := &db.User{
		Username: "Apex",
		Token:    "Corse",
	}
	gormDb.Create(user)

	err = api.validateUser("Cors")
	assert.Error(t, err)
}

func TestHandleSendData_Success(t *testing.T) {
	gormDb, cleanUp, err := db.TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	api := NewAPI("", db.NewDB(gormDb), mux.NewRouter(), &websocket.Upgrader{}, make(chan *RealTimeRecord))

	user := &db.User{
		Username: "Apex",
		Token:    "Corse",
	}
	gormDb.Create(user)

	section := &db.Section{
		Name: "Test",
	}
	gormDb.Create(section)

	module := &db.Module{
		Name:      "Test",
		SectionID: section.ID,
	}
	gormDb.Create(module)

	sensor := &db.Sensor{
		Name:     "Test",
		ModuleID: module.ID,
	}
	gormDb.Create(sensor)

	records := []*db.Record{
		{
			Value:    42,
			SensorID: sensor.ID,
		},
		{
			Value:    43,
			SensorID: sensor.ID,
		},
		{
			Value:    44,
			SensorID: sensor.ID,
		},
	}
	gormDb.Create(records)

	requestBody := &DataRequestBody{
		Section: "Test",
		Module:  "Test",
		Sensor:  "Test",
	}
	b, err := json.Marshal(requestBody)
	assert.Nil(t, err)

	server := httptest.NewServer(http.HandlerFunc(api.handleSendData))
	defer server.Close()

	request, err := http.NewRequest(http.MethodPost, server.URL, bytes.NewBuffer(b))
	assert.Nil(t, err)
	request.Header.Set("Authorization", "Bearer Corse")

	resp, err := http.DefaultClient.Do(request)
	assert.Nil(t, err)
	assert.Equal(t, http.StatusOK, resp.StatusCode)

	body, err := io.ReadAll(resp.Body)
	assert.Nil(t, err)
	assert.Equal(t, "application/json", resp.Header.Get("Content-Type"))

	response := make(map[string]any)
	err = json.Unmarshal(body, &response)
	assert.Nil(t, err)

	assert.Equal(t, "Test", response["section"])
	assert.Equal(t, "Test", response["module"])
	assert.Equal(t, "Test", response["name"])
	assert.Len(t, response["records"], 3)
	assert.IsType(t, []any{}, response["records"])
	assert.IsType(t, map[string]any{}, response["records"].([]any)[0])
	assert.IsType(t, float64(0), response["records"].([]any)[0].(map[string]any)["value"])
	assert.Equal(t, float64(42), response["records"].([]any)[0].(map[string]any)["value"])
	assert.Equal(t, float64(43), response["records"].([]any)[1].(map[string]any)["value"])
	assert.Equal(t, float64(44), response["records"].([]any)[2].(map[string]any)["value"])
}

func TestHandleSendData_AuthenticationFailure(t *testing.T) {
	gormDb, cleanUp, err := db.TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	api := NewAPI("", db.NewDB(gormDb), mux.NewRouter(), &websocket.Upgrader{}, make(chan *RealTimeRecord))

	user := &db.User{
		Username: "Apex",
		Token:    "ValidToken",
	}
	gormDb.Create(user)

	requestBody := &DataRequestBody{
		Section: "Test",
		Module:  "Test",
		Sensor:  "Test",
	}
	b, err := json.Marshal(requestBody)
	assert.Nil(t, err)

	server := httptest.NewServer(http.HandlerFunc(api.handleSendData))
	defer server.Close()

	request, err := http.NewRequest(http.MethodPost, server.URL, bytes.NewBuffer(b))
	assert.Nil(t, err)
	request.Header.Set("Authorization", "Bearer InvalidToken")

	resp, err := http.DefaultClient.Do(request)
	assert.Nil(t, err)
	assert.Equal(t, http.StatusUnauthorized, resp.StatusCode)

	body, err := io.ReadAll(resp.Body)
	assert.Nil(t, err)
	assert.Equal(t, "invalid credentials\n", string(body))
}

func TestHandleWebSocket_Success(t *testing.T) {
	gormDb, cleanUp, err := db.TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	user := &db.User{
		Username: "Apex",
		Token:    "ValidToken",
	}
	gormDb.Create(user)

	recordChan := make(chan *RealTimeRecord)
	api := NewAPI("", db.NewDB(gormDb), mux.NewRouter(), &websocket.Upgrader{}, recordChan)

	server := httptest.NewServer(http.HandlerFunc(api.handleWebSocket))
	defer server.Close()

	u := "ws://" + strings.TrimPrefix(server.URL, "http://")

	conn, _, err := websocket.DefaultDialer.Dial(u, http.Header{
		"Authorization": {"Bearer ValidToken"},
	})
	assert.Nil(t, err)
	assert.NotNil(t, conn)
	defer conn.Close()

	req := &RealTimeRequest{
		Section: "Test",
		Module:  "Test",
		Sensor:  "Test",
		Track:   true,
	}
	b, err := json.Marshal(req)
	assert.Nil(t, err)

	err = conn.WriteMessage(websocket.TextMessage, b)
	assert.Nil(t, err)

	record := &RealTimeRecord{
		Section: "Test",
		Module:  "Test",
		Sensor:  "Test",
		Value:   42.0,
		Time:    time.Now(),
	}
	recordChan <- record

	messageType, message, err := conn.ReadMessage()
	assert.Nil(t, err)
	assert.Equal(t, websocket.TextMessage, messageType)

	data := &RealTimeRecord{}
	err = json.Unmarshal(message, data)
	assert.Nil(t, err)
	assert.Equal(t, record.Section, data.Section)
	assert.Equal(t, record.Module, data.Module)
	assert.Equal(t, record.Sensor, data.Sensor)
	assert.Equal(t, record.Value, data.Value)
	assert.Equal(t, record.Time.Unix(), data.Time.Unix())
}

func TestHandleWebSocket_InvalidRequest(t *testing.T) {
	gormDb, cleanUp, err := db.TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	user := &db.User{
		Username: "Apex",
		Token:    "ValidToken",
	}
	gormDb.Create(user)

	recordChan := make(chan *RealTimeRecord)
	api := NewAPI("", db.NewDB(gormDb), mux.NewRouter(), &websocket.Upgrader{}, recordChan)

	server := httptest.NewServer(http.HandlerFunc(api.handleWebSocket))
	defer server.Close()

	u := "ws://" + strings.TrimPrefix(server.URL, "http://")

	conn, _, err := websocket.DefaultDialer.Dial(u, http.Header{
		"Authorization": {"Bearer ValidToken"},
	})
	assert.Nil(t, err)
	assert.NotNil(t, conn)
	defer conn.Close()

	err = conn.WriteMessage(websocket.TextMessage, []byte("invalid json"))
	assert.Nil(t, err)

	messageType, message, err := conn.ReadMessage()
	assert.Nil(t, err)
	assert.Equal(t, websocket.TextMessage, messageType)
	assert.Equal(t, "bad request", string(message))
}

func TestHandleWebSocket_AuthenticationFailure(t *testing.T) {
	gormDb, cleanUp, err := db.TestDB()
	if err != nil {
		t.Fatal("cannot setup db")
	}
	defer cleanUp()

	user := &db.User{
		Username: "Apex",
		Token:    "ValidToken",
	}
	gormDb.Create(user)

	recordChan := make(chan *RealTimeRecord)
	api := NewAPI("", db.NewDB(gormDb), mux.NewRouter(), &websocket.Upgrader{}, recordChan)

	server := httptest.NewServer(http.HandlerFunc(api.handleWebSocket))
	defer server.Close()

	u := "ws://" + strings.TrimPrefix(server.URL, "http://")

	_, resp, err := websocket.DefaultDialer.Dial(u, http.Header{
		"Authorization": {"Bearer InvalidToken"},
	})
	assert.Error(t, err)
	assert.Equal(t, http.StatusUnauthorized, resp.StatusCode)

	body, err := io.ReadAll(resp.Body)
	assert.Nil(t, err)
	assert.Equal(t, "invalid credentials\n", string(body))
}
