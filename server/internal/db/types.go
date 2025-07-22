package db

import "time"

type Record struct {
	ID        uint `gorm:"primarykey"`
	CreatedAt time.Time
	Value     float32

	SensorID uint
}

type Sensor struct {
	ID        uint `gorm:"primarykey"`
	Name      string
	CreatedAt time.Time

	Records  []Record
	ModuleID uint
}

type Module struct {
	ID   uint `gorm:"primarykey"`
	Name string

	Sensors   []Sensor
	SectionID uint
}

type Section struct {
	ID   uint `gorm:"primarykey"`
	Name string

	Modules []Module
}

type User struct {
	ID           uint `gorm:"primarykey"`
	Username     string
	HashPassword string
	Salt         string
	CreatedAt    time.Time
}
