package store

import (
	"bytes"
	"fmt"
	"strings"

	"std"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/store"
)

const (
	notFoundMessage = "404: item not found"
	successMessage  = "Successfully added item"
	failedMessage   = "Unable to add item"
)

var (
	storeAdmin std.Address = "g1hm7f7sjmlmzqzavhcaqmxzh4nah0m4kchc2ue3"

	items     avl.Tree
	idCounter uint
)

// isStoreAdmin checks if the address is the store admin
func isStoreAdmin(address std.Address) bool {
	return address == storeAdmin
}

// Render displays the store's contents
func Render(path string) string {
	// Get the resource path
	parts := strings.Split(path, "/")

	switch {
	case path == "":
		// Show all the store items
		return renderItems()
	case len(parts) == 2 && parts[0] == "item":
		// Check if the item exists
		item := getItemByID(parts[1])
		if item != nil {
			return notFoundMessage
		}

		return item.GetInfo()
	default:
		return notFoundMessage
	}
}

// renderItems renders all available store items
func renderItems() string {
	var buffer bytes.Buffer

	items.Iterate("", "", func(t *avl.Node) bool {
		item, _ := t.Value().(*store.Item)

		buffer.WriteString(item.GetInfo())
		buffer.WriteString("\n\n")

		return false
	})

	return buffer.String()
}

// getItemByID fetches an item using an ID
func getItemByID(id string) *store.Item {
	item, found := items.Get(id)
	if !found {
		return nil
	}

	return item.(*store.Item)
}

// AddItem adds a new item to the store
func AddItem(
	price int64,
	description string,
) string {
	// Only store owners can modify
	// the contents of the store
	if !isStoreAdmin(std.GetOrigCaller()) {
		return failedMessage
	}

	// Create a new item
	item := store.NewItem(
		idCounter,
		price,
		description,
	)

	// Add the item to the store
	items.Set(
		fmt.Sprintf("%d", item.GetId()),
		item,
	)

	// Increase the global ID counter
	idCounter++

	return successMessage
}
