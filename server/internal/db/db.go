package db

import (
	"errors"
	"time"

	"gorm.io/gorm"
)

type DB struct {
	db *gorm.DB
}

func NewDB(db *gorm.DB) *DB {
	return &DB{db: db}
}

func (d *DB) InsertRecord(record *Record) error {
	tx := d.db.Create(record)

	return tx.Error
}

func (d *DB) InsertSensor(sensor *Sensor) error {
	tx := d.db.Create(sensor)

	return tx.Error
}

func (d *DB) InsertModule(module *Module) error {
	tx := d.db.Create(module)

	return tx.Error
}

func (d *DB) InsertSection(section *Section) error {
	tx := d.db.Create(section)

	return tx.Error
}

func (d *DB) InsertUser(user *User) error {
	tx := d.db.Create(user)

	return tx.Error
}

func (d *DB) GetModuleById(id uint) (*Module, error) {
	module := &Module{}
	tx := d.db.Preload("Sensors").First(module, id)

	if tx.RowsAffected == 0 {
		return nil, errors.New("module not found")
	}

	if tx.Error != nil {
		return nil, tx.Error
	}

	return module, nil
}

func (d *DB) GetSectionById(id uint) (*Section, error) {
	section := &Section{}
	tx := d.db.Preload("Modules").First(section, id)

	if tx.RowsAffected == 0 {
		return nil, errors.New("section not found")
	}

	if tx.Error != nil {
		return nil, tx.Error
	}

	return section, nil
}

func (d *DB) GetSectionByName(name string) (*Section, error) {
	section := &Section{}
	tx := d.db.Preload("Modules").Where("name = ?", name).First(section)

	if tx.RowsAffected == 0 {
		return nil, errors.New("section not found")
	}

	if tx.Error != nil {
		return nil, tx.Error
	}

	return section, nil
}

func (d *DB) GetModuleByNameAndSection(sectionName, moduleName string) (*Module, error) {
	module := &Module{}
	tx := d.db.
		Joins("JOIN sections ON sections.id = modules.section_id").
		Where("sections.name = ?", sectionName).
		Where("modules.name = ?", moduleName).
		First(module)

	if tx.RowsAffected == 0 {
		return nil, errors.New("module not found")
	}

	if tx.Error != nil {
		return nil, tx.Error
	}

	return module, nil
}

func (d *DB) GetSensorById(sensorID uint, from, to time.Time) (*Sensor, error) {
	sensor := &Sensor{}

	timeCondition := ""
	params := make([]any, 0, 2)
	if !from.IsZero() && !to.IsZero() {
		timeCondition = "created_at BETWEEN ? AND ?"
		params = append(params, from)
		params = append(params, to)
	} else if !from.IsZero() {
		timeCondition = "created_at <= ?"
		params = append(params, to)
	} else if !to.IsZero() {
		timeCondition = "created_at >= ?"
		params = append(params, from)
	} else {
		timeCondition = "created_at >= ?"
		params = append(params, time.Now().Add(-30*time.Minute))
	}

	tx := d.db.Preload(
		"Records",
		d.db.Where(timeCondition, params...),
	).First(&sensor, sensorID)

	if tx.RowsAffected == 0 {
		return nil, errors.New("sensor not found")
	}

	if tx.Error != nil {
		return nil, tx.Error
	}

	return sensor, nil
}

func (d *DB) GetSensorByNameAndModuleAndSection(sensorName, moduleName, sectionName string, from, to time.Time) (*Sensor, error) {
	sensor := &Sensor{}

	timeCondition := ""
	params := make([]any, 0, 2)
	if !from.IsZero() && !to.IsZero() {
		timeCondition = "created_at BETWEEN ? AND ?"
		params = append(params, from)
		params = append(params, to)
	} else if !from.IsZero() {
		timeCondition = "created_at >= ?"
		params = append(params, to)
	} else if !to.IsZero() {
		timeCondition = "created_at <= ?"
		params = append(params, from)
	} else {
		timeCondition = "created_at >= ?"
		params = append(params, time.Now().Add(-30*time.Minute))
	}

	tx := d.db.
		Joins("JOIN modules ON modules.id = sensors.module_id").
		Joins("JOIN sections ON sections.id = modules.section_id").
		Where("sections.name = ?", sectionName).
		Where("modules.name = ?", moduleName).
		Where("sensors.name = ?", sensorName).
		Preload("Records", d.db.Where(timeCondition, params...)).
		First(sensor)

	if tx.RowsAffected == 0 {
		return nil, errors.New("sensor not found")
	}

	if tx.Error != nil {
		return nil, tx.Error
	}

	return sensor, nil
}

func (d *DB) GetUserByUsername(username string) (*User, error) {
	user := &User{}
	tx := d.db.Where("username = ?", username).First(user)

	if tx.RowsAffected == 0 {
		return nil, errors.New("user not found")
	}

	if tx.Error != nil {
		return nil, tx.Error
	}

	return user, nil
}
