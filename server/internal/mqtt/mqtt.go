package mqtt

import (
	"crypto/tls"
	"log"

	"github.com/ApexCorse/ephoros/server/internal/config"
	"github.com/ApexCorse/ephoros/server/internal/db"
	mqtt "github.com/mochi-mqtt/server/v2"
	"github.com/mochi-mqtt/server/v2/hooks/auth"
	"github.com/mochi-mqtt/server/v2/listeners"
)

type HookConfig struct {
	Hook    mqtt.Hook
	Options *mqtt.Options
}

type MQTTConfig struct {
	Certificates []tls.Certificate
	Config       *config.Config
	DB           *db.DB
	Hooks        []HookConfig
	Listeners    []listeners.Listener
	Server       *mqtt.Server
}

type MQTT struct {
	s      *mqtt.Server
	config *config.Config
	db     *db.DB
}

func NewMQTT(cfg *MQTTConfig) *MQTT {
	if cfg.DB == nil {
		log.Println("[MQTT] db is nil, caution")
	}

	s := cfg.Server
	if s == nil {
		log.Println("[MQTT] server is nil, caution")
	}

	if cfg.Config == nil {
		log.Println("[MQTT] config is nil, caution")
	}

	authRules := auth.AuthRules{}
	for _, mConfig := range cfg.Config.MQTT {
		authRules = append(authRules, auth.AuthRule{
			Username: auth.RString(mConfig.Username),
			Password: auth.RString(mConfig.Password),
			Allow:    true,
		})
	}
	s.AddHook(&auth.Hook{}, &auth.Options{
		Ledger: &auth.Ledger{
			Auth: authRules,
		},
	})

	for _, hook := range cfg.Hooks {
		s.AddHook(hook.Hook, hook.Options)
	}

	for _, listener := range cfg.Listeners {
		s.AddListener(listener)
	}

	return &MQTT{
		s:      s,
		config: cfg.Config,
		db:     cfg.DB,
	}
}
