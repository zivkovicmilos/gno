package forum

import "std"

// Post represents a single forum post
type Post struct {
	id uint

	title string
	body  string

	author std.Address
}

// NewPost creates a new forum post
func NewPost(
	id uint,
	title string,
	body string,
	author std.Address,
) *Post {
	return &Post{
		id:     id,
		title:  title,
		body:   body,
		author: author,
	}
}

// GetID returns the post's ID
func (p Post) GetID() uint {
	return p.id
}

// GetTitle returns the post's title
func (p Post) GetTitle() string {
	return p.title
}

// GetBody returns the post's body
func (p Post) GetBody() string {
	return p.body
}

// GetAuthor returns the post's author (address)
func (p Post) GetAuthor() std.Address {
	return p.author
}
