package store

import (
	"bytes"
	"strings"

	"std"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/store"
)

const (
	notFoundMessage = "404: gnome not found"
	successMessage  = "Successfully added gnome"
	failedMessage   = "Unable to add item"

	noItemsMessage = "There are no gnomes in the store"
	failedBuyOrder = "unable to execute buy order"
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
	// Check if there are any items in the store
	if items.Size() < 1 {
		return noItemsMessage
	}

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

// AddGnome adds a new gnome item to the store
func AddGnome(
	price uint64,
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
		item.GetIdString(),
		item,
	)

	// Increase the global ID counter
	idCounter++

	return successMessage
}

// BuyItem executes a buy order
func BuyItem(id string) string {
	// Make sure the item exists
	gnome := getItemByID(id)
	if gnome == nil {
		return notFoundMessage
	}

	// Get the item price in native currency (ugnot)
	amount := std.Coins{
		Denom:  "ugnot",
		Amount: gnome.GetPrice(),
	}

	// Get a reference to the banker
	banker := std.GetBanker(std.BankerTypeOrigSend)

	// Get the address of the method caller
	buyer := std.GetOrigCaller()

	// Make sure the buyer has enough funds
	if !banker.GetCoins(buyer).isGTE(amount) {
		return failedBuyOrder
	}

	// Execute the buy order
	banker.SendCoins(buyer, storeAdmin, amount)

	return umft.Sprintf(
		"gnome with ID %s successfully purchased!",
		id,
	)
}
