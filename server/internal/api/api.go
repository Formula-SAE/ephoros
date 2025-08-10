package api

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"

	"github.com/ApexCorse/ephoros/server/internal/config"
	"github.com/ApexCorse/ephoros/server/internal/db"
	"github.com/gorilla/mux"
	mqtt "github.com/mochi-mqtt/server/v2"
)

type API struct {
	db         *db.DB
	r          *mux.Router
	address    string
	mqttServer *mqtt.Server
	config     *config.Config
}

func NewAPI(
	address string,
	db *db.DB,
	r *mux.Router,
	mqtt *mqtt.Server,
	config *config.Config,
) *API {
	return &API{
		db:         db,
		r:          r,
		address:    address,
		mqttServer: mqtt,
		config:     config,
	}
}

func (a *API) Start() {
	go a.mqttServer.Serve()

	a.r.HandleFunc("/auth", a.handleAuth).Methods("POST")
	a.r.HandleFunc("/data", a.handleSendData).Methods("POST")

	go a.mqttServer.Serve()

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
