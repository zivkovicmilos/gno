package forum

import (
	"std"
	"testing"

	"gno.land/p/demo/testutils"
)

// TestPost_New verifies that a
// new forum post can be created successfully
func TestPost_New(t *testing.T) {
	const (
		id     uint        = 123
		title  string      = "Example Post Title"
		body   string      = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
		author std.Address = testutils.TestAddress("author")
	)

	// Create a new post
	p := NewPost(id, title, body, author)

	// Check that the data matches
	if p.GetID() != id {
		t.Fatalf("invalid ID")
	}

	if p.GetTitle() != title {
		t.Fatalf("invalid title")
	}

	if p.GetBody() != body {
		t.Fatalf("invalid body")
	}

	if p.GetAuthor().String() != author.String() {
		t.Fatalf("invalid author")
	}
}
