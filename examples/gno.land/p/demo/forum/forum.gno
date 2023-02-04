package forum

import (
	"std"

	"gno.land/p/demo/avl"
)

// Forum represents a single forum instance
type Forum struct {
	name string

	categories avl.Tree // category name -> []post
	tags       avl.Tree // tag name -> []post

	admin      std.Address
	moderators avl.Tree // category name -> []address
}

// NewForum creates a new forum instance
func NewForum(
	name string,
	categories []string,
	tags []string,
	admin std.Address,
) *Forum {
	// Create a new forum instance
	f := &Forum{
		name:       name,
		categories: avl.Tree{},
		tags:       avl.Tree{},
		admin:      admin,
		moderators: avl.Tree{},
	}

	// Instantiate the categories
	for _, category := range categories {
		f.categories.Set(category, make([]*Post, 0))

		// Instantiate the initial moderator set
		f.moderators.Set(category, []std.Address{admin})
	}

	// Instantiate the tags
	for _, tag := range tags {
		f.tags.Set(tag, make([]*Post, 0))
	}

	return f
}

// GetName returns the forum name
func (f Forum) GetName() string {
	return f.name
}

// GetCategories fetches the forum categories
func (f Forum) GetCategories() []string {
	var (
		categories = make([]string, f.categories.Size())
		index      = 0
	)

	f.categories.Iterate("", "", func(category *avl.Node) bool {
		// Add the category to the list
		categories[index] = category.Key()

		index++

		// Continue iteration
		return false
	})

	return categories
}

// GetTags fetches the forum tags
func (f Forum) GetTags() []string {
	var (
		tags  = make([]string, f.tags.Size())
		index = 0
	)

	f.tags.Iterate("", "", func(tag *avl.Node) bool {
		// Add the tag to the list
		tags[index] = tag.Key()

		index++

		// Continue iteration
		return false
	})

	return tags
}

// AddModerator adds a moderator for the category,
// and returns a status indicating if it was a success
func (f Forum) AddModerator(
	moderator std.Address,
	category string,
) bool {
	// Check if the caller is the admin
	if !f.isAdmin(std.GetOrigCaller()) {
		return false
	}

	// Check if the category exists
	moderatorsRaw, found := f.moderators.Get(category)
	if !found {
		// Category is invalid
		return false
	}

	if f.isModerator(moderator, category) {
		// This moderator already exists for this category
		return false
	}

	// Add the moderator to the moderator set
	moderators, _ := moderatorsRaw.([]std.Address)
	moderators = append(moderators, moderator)

	// Save the new moderator set
	f.moderators.Set(category, moderators)

	return true
}

// AddPost adds a new post to the forum
func (f Forum) AddPost(
	post *Post,
	category string,
	tags ...string,
) bool {
	// Check if the category exists
	postsRaw, found := f.categories.Get(category)
	if !found {
		// Invalid category specified
		return false
	}

	// Add the post reference
	posts, _ := postsRaw.([]*Post)
	posts = append(posts, post)
	f.categories.Set(category, posts)

	// Attempt to apply tags
	for _, tag := range tags {
		taggedPostsRaw, found := f.tags.Get(tag)
		if !found {
			// Tag does not exist, so it won't be applied
			continue
		}

		// Add the post reference
		taggedPosts, _ := taggedPostsRaw.([]*Post)
		taggedPosts = append(taggedPosts, post)

		f.tags.Set(tag, taggedPosts)
	}

	return true
}

// RemovePost removes the specific post
// from the forum, and its underlying comments.
// This method is highly ineffective, and is simply meant
// to demonstrate how post removal can work.
// In this example, only moderators can remove posts
func (f Forum) RemovePost(id uint) bool {
	postRemoved := false

	// Find the specific category, and remove the post
	f.categories.Iterate("", "", func(category *avl.Node) bool {
		categoryName := category.Key()

		// Check if the caller is a moderator for this category
		if !f.isModerator(std.GetOrigCaller(), categoryName) {
			// User is not a moderator, continue
			return true
		}

		postsRaw := category.Value()
		posts, _ := postsRaw.([]*Post)

		for index, post := range posts {
			// Check if this is the post to be deleted
			if post.GetID() == id {
				// Prune out the element
				posts = append(posts[:index], posts[index+1:]...)
				postRemoved = true

				f.categories.Set(categoryName, posts)

				return true
			}
		}

		// Continue the search
		return false
	})

	// No need to remove the post from tags
	// if it didn't exist in the first place
	if !postRemoved {
		return postRemoved
	}

	// Find the specific tag, if any, and remove the post
	f.tags.Iterate("", "", func(tag *avl.Node) bool {
		tagName := tag.Key()

		tagsRaw := tag.Value()
		tags, _ := tagsRaw.([]*Post)

		for index, post := range tags {
			// Check if this is the post to be deleted
			if post.GetID() == id {
				// Prune out the element
				posts = append(posts[:index], posts[index+1:]...)

				f.tags.Set(tagName, posts)

				return true
			}
		}

		// Continue the search
		return false
	})

	return true
}

// isAdmin checks if the address belongs to the forum admin
func (f Forum) isAdmin(address std.Address) bool {
	return address.String() == f.admin.String()
}

// isModerator checks if the address matches a moderator for the given category
func (f Forum) isModerator(address std.Address, category string) bool {
	// Grab the category moderator list
	moderatorsRaw, found := f.moderators.Get(category)
	if !found {
		// Category does not exist
		return false
	}

	// Check to see if this moderator exists
	moderators, _ := moderatorsRaw.([]std.Address)

	// This lookup can be improved if we keep a map of moderators
	// instead of a list, but for demo purposes this is acceptable
	for _, moderator := range moderators {
		if moderator.String() == address {
			return true
		}
	}

	return false
}
