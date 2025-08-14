package api

import (
	"crypto/tls"

	"github.com/mochi-mqtt/server/v2/hooks/auth"
	"github.com/mochi-mqtt/server/v2/listeners"
)

func (a *API) ConfigureMQTT(certs ...tls.Certificate) error {
	authRules := auth.AuthRules{}

	for _, mConfig := range a.config.MQTT {
		authRules = append(authRules, auth.AuthRule{
			Username: auth.RString(mConfig.Username),
			Password: auth.RString(mConfig.Password),
			Allow:    true,
		})
	}

	a.mqttServer.AddHook(&auth.Hook{}, &auth.Options{
		Ledger: &auth.Ledger{
			Auth: authRules,
		},
	})

	a.mqttServer.AddHook(&DataHook{
		db: a.db,
	}, nil)

	listener := listeners.NewTCP(listeners.Config{
		TLSConfig: &tls.Config{
			Certificates: certs,
		},
	})
	a.mqttServer.AddListener(listener)

	return nil
}
