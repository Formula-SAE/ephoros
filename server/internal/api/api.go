package api

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/ApexCorse/ephoros/server/internal/db"
	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
)

type API struct {
	db       *db.DB
	r        *mux.Router
	address  string
	upgrader *websocket.Upgrader
	data     chan *RealTimeRecord
}

func NewAPI(address string, db *db.DB, r *mux.Router, upgrader *websocket.Upgrader, data chan *RealTimeRecord) *API {
	return &API{
		db:       db,
		r:        r,
		address:  address,
		upgrader: upgrader,
		data:     data,
	}
}

func (a *API) Start() {
	a.r.HandleFunc("/auth", a.handleAuth).Methods("POST")
	a.r.HandleFunc("/data", a.handleSendData).Methods("POST")
	a.r.HandleFunc("/ws", a.handleWebSocket)

	http.ListenAndServe(a.address, a.r)
}

func (a *API) handleAuth(w http.ResponseWriter, r *http.Request) {
	token, err := a.getTokenFromRequest(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusUnauthorized)
		return
	}

	if err := a.validateUser(token); err != nil {
		http.Error(w, err.Error(), http.StatusUnauthorized)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	json.NewEncoder(w).Encode(
		map[string]string{
			"message": "Authorized",
		},
	)
}

func (a *API) handleSendData(w http.ResponseWriter, r *http.Request) {
	token, err := a.getTokenFromRequest(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusUnauthorized)
		return
	}

	if err := a.validateUser(token); err != nil {
		http.Error(w, err.Error(), http.StatusUnauthorized)
		return
	}

	body := &DataRequestBody{}
	if err := json.NewDecoder(r.Body).Decode(body); err != nil {
		http.Error(w, "bad request", http.StatusBadRequest)
		return
	}

	if !body.Validate() {
		http.Error(w, "bad request", http.StatusBadRequest)
		return
	}

	sensor, err := a.db.GetSensorByNameAndModuleAndSection(
		body.Sensor,
		body.Module,
		body.Section,
		body.From,
		body.To,
	)
	if err != nil {
		http.Error(w, "sensor not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	json.NewEncoder(w).Encode(
		map[string]any{
			"module":  body.Module,
			"name":    sensor.Name,
			"records": sensor.Records,
			"section": body.Section,
		},
	)
}

func (a *API) handleWebSocket(w http.ResponseWriter, r *http.Request) {
	token, err := a.getTokenFromRequest(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusUnauthorized)
		return
	}

	if err := a.validateUser(token); err != nil {
		http.Error(w, err.Error(), http.StatusUnauthorized)
		return
	}

	conn, err := a.upgrader.Upgrade(w, r, nil)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer conn.Close()

	requests := NewRealTimeRequestMap(make(map[string]*RealTimeRequest))

	done := make(chan struct{})
	defer close(done)

	go func() {
		defer func() {
			select {
			case done <- struct{}{}:
			default:
			}
		}()

		for {
			messageType, message, err := conn.ReadMessage()
			if err != nil {
				return
			}

			if messageType == websocket.TextMessage {
				req := &RealTimeRequest{}
				if err := json.Unmarshal(message, req); err != nil {
					conn.WriteMessage(websocket.TextMessage, []byte("bad request"))
					return
				}

				if !req.Validate() {
					conn.WriteMessage(websocket.TextMessage, []byte("bad request"))
					return
				}

				if req.Track {
					requests.Add(req)
				} else {
					requests.Remove(req)
				}
			}
		}
	}()

	for {
		select {
		case record := <-a.data:
			if req := requests.Find(record.Section, record.Module, record.Sensor); req != nil {
				if err := conn.WriteJSON(record); err != nil {
					return
				}
			}
		case <-done:
			return
		default:
			time.Sleep(100 * time.Millisecond)
		}
	}
}

func (a *API) validateUser(token string) error {
	_, err := a.db.GetUserByToken(token)
	if err != nil {
		return errors.New("invalid credentials")
	}

	return nil
}

func (a *API) getTokenFromRequest(r *http.Request) (string, error) {
	token := r.Header.Get("Authorization")
	if token == "" {
		return "", errors.New("no token provided")
	}

	parts := strings.Split(token, " ")
	if len(parts) != 2 || parts[0] != "Bearer" {
		return "", errors.New("invalid token format")
	}

	return parts[1], nil
}
