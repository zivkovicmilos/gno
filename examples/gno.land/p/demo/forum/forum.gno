package forum

import (
	"std"

	"gno.land/p/demo/avl"
)

// Forum represents a single forum instance
type Forum struct {
	name string

	posts avl.Tree // post id -> post

	categories avl.Tree // category name -> []post (for lookups)
	tags       avl.Tree // tag name -> []post (for lookups)

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
		posts:      avl.Tree{},
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
func (f Forum) AddPost(post *Post) bool {
	// Check if the post exists
	_, found := f.posts.Get(post.GetID())
	if found {
		// Post with this ID already exists
		return false
	}

	// Check if the category exists
	postsRaw, found := f.categories.Get(post.GetCategory())
	if !found {
		// Invalid category specified
		return false
	}

	// Add the post reference
	posts, _ := postsRaw.([]*Post)
	posts = append(posts, post)
	f.categories.Set(category, posts)

	// Attempt to apply tags
	for _, tag := range post.GetTags() {
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

	// Save the post
	f.posts.Set(post.GetID(), post)

	return true
}

// AddComment appends a new comment to a post, if it exists
func (f Forum) AddComment(postID uint, body string) bool {
	postRaw, found := f.posts.Get(postID)
	if !found {
		// Post does not exist
		return false
	}

	post, _ := postRaw.(*Post)

	post.AddComment(NewComment(body))

	return true
}

// GetComments fetches the comments for a specific post
func (f Forum) GetComments(postID uint) []*Comment {
	postRaw, found := f.posts.Get(postID)
	if !found {
		// Post does not exist
		return nil
	}

	post, _ := postRaw.(*Post)

	return post.GetComments()
}

// RemovePost removes the specific post
// from the forum, and its underlying comments.
// This method is highly ineffective, and is simply meant
// to demonstrate how post removal can work.
// In this example, only moderators can remove posts
func (f Forum) RemovePost(id uint) bool {
	postRemoved := false

	postRaw, found := f.posts.Get(id)
	if !found {
		// Post does not exist
		return false
	}

	post, _ := postRaw.(*Post)

	// Check if the caller is a moderator for this category
	if !f.isModerator(std.GetOrigCaller(), post.GetCategory()) {
		// User is not a moderator, continue
		return false
	}

	// Remove the post from the category
	categoryPostsRaw, found := f.categories.Get(post.GetCategory())
	if !found {
		// Category for this post is not found (impossible)
		return false
	}

	categoryPosts, _ := categoryPostsRaw.([]*Post)

	for index, post := range categoryPosts {
		// Check if this is the post to be deleted
		if post.GetID() == id {
			// Prune out the element
			posts = append(posts[:index], posts[index+1:]...)
			postRemoved = true

			f.categories.Set(post.GetCategory(), posts)
		}
	}

	// No need to remove the post from tags
	// if it didn't exist in the first place
	if !postRemoved {
		return postRemoved
	}

	// Find the specific tag, if any, and remove the post
outer:
	for _, tag := range post.GetTags() {
		tagPostsRaw, found := f.tags.Get(tag)
		if !found {
			// No posts found for this tag
			continue
		}

		tagPosts, _ := tagPostsRaw.([]*Post)

		for index, post := range tagPosts {
			// Check if this is the post to be deleted
			if post.GetID() == id {
				// Prune out the element
				posts = append(posts[:index], posts[index+1:]...)

				f.tags.Set(tag, posts)

				break outer
			}
		}
	}

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
