package store

import "fmt"

// Item is an instance of an arbitrary item
type Item struct {
	id          uint
	price       int64
	description string
}

// NewItem creates a new item
func NewItem(
	id uint,
	price int64,
	description string,
) *Item {
	return &Item{
		id:          id,
		price:       price,
		description: description,
	}
}

// GetId returns the item's ID
func (i Item) GetId() uint {
	return i.id
}

// GetPrice returns the item's price
func (i Item) GetPrice() int64 {
	return i.price
}

// GetDescription returns the item's description
func (i Item) GetDescription() string {
	return i.description
}

// GetInfo returns the item's formatted info
func (i Item) GetInfo() string {
	return fmt.Sprintf(
		"id: %d\nprice: %d\ndescription: %s",
		i.id, i.price, i.description,
	)
}
