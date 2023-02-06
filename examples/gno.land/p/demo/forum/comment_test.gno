package forum

import (
	"std"
	"testing"

	"gno.land/p/demo/testutils"
)

// TestComment_New verifies that a
// new forum post comment can be created successfully
func TestComment_New(t *testing.T) {
	const (
		body   string      = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
		author std.Address = testutils.TestAddress("author")
	)

	// Create a new post
	std.TestSetOrigCaller(author)
	p := NewComment(body)

	// Check that the data matches
	if p.GetBody() != body {
		t.Fatalf("invalid body")
	}

	if p.GetAuthor().String() != author.String() {
		t.Fatalf("invalid author")
	}
}
