package gno_overflow

import (
	"bytes"
	"fmt"
	"std"
	"strings"

	"gno.land/p/demo/forum"
)

// State of the Realm
var (
	name = "Gno Overflow"
	// TODO define address
	admin      = "?"
	categories = []string{"General", "Announcements", "Devs"}
	tags       = []string{"gno-vm", "news", "roadmap"}

	f           *forum.Forum
	forumPrefix = "/r/demo/gno-overflow:" // used for routing
	postIndex   = 0
)

// init constructs the forum instance during deployment
func init() {
	f = forum.NewForum(name, categories, tags, admin)
}

// AddModerator adds a new moderator to the forum
func AddModerator(moderator std.Address, category string) string {
	if !f.AddModerator(moderator, category) {
		return "unable to add moderator"
	}

	return "moderator successfully added"
}

// AddPost adds a new post to the forum
func AddPost(
	title string,
	body string,
	category string,
	tags []string,
) string {
	// Create a new post
	p := forum.NewPost(postIndex, title, body, std.GetOrigCaller())
	p.SetCategory(category)
	p.SetTags(tags...)

	// Add the post to the forum
	if !f.AddPost(p) {
		return "unable to add post"
	}

	// Increment the global post index
	postIndex++

	return fmt.Sprintf("post successfully added with ID %d", postIndex-1)
}

// AddComment adds a new comment to a post
// AddPost adds a new post to the forum
func AddComment(
	postID uint,
	body string,
) string {
	// Create a new comment
	c := forum.NewComment(body)

	// Add the post to the forum
	if !f.AddComment(postID, c) {
		return "unable to add comment"
	}

	return "comment successfully added"
}

// Render displays the forum's content
func Render(path string) string {
	// Get the resource path
	parts := strings.Split(path, "/")

	switch {
	case path == "":
		return ""
	case len(parts) == 2 && parts[0] == "post":
		post := f.posts.Get(parts[1])
		if post == nil {
			return "post not found"
		}

		return renderPost(post)
	case len(parts) == 2 && parts[0] == "tag":
		tagPosts := f.GetTagPosts(parts[1])
		if tagPosts == nil {
			return "no posts found"
		}

		return renderPostList(tagPosts)
	case len(parts) == 2 && parts[0] == "category":
		categoryPosts := f.GetCategoryPosts(parts[1])
		if categoryPosts == nil {
			return "no posts found"
		}

		return renderPostList(categoryPosts)
	default:
		return "post not found"
	}
}

// renderPostList renders a list of posts with their links
func renderPostList(posts []*forum.Post) string {
	var b bytes.Buffer

	for _, post := range posts {
		postURL := forumPrefix + "post/" + post.GetID()
		b.WriteString(
			fmt.Sprintf("[### %s](%s)", post.GetTitle(), postURL),
		)
	}

	return b.String()
}

// renderHomepage renders the homepage
func renderHomepage() string {
	var b bytes.Buffer

	// Write welcome message
	b.WriteString(
		fmt.Sprintf("## Welcome to the %s forum!", f.GetName()),
	)

	// For each category, write the name
	for _, category := range f.GetCategories() {
		categoryURL := forumPrefix + "category/" + category
		b.WriteString(
			fmt.Sprintf("## [Category: %s](%s)\n", category, categoryURL),
		)
	}

	return b.String()
}

// renderPost renders a post and its accompanying comments
func renderPost(p *forum.Post) string {
	var b bytes.Buffer

	// Write the title
	b.WriteString(
		fmt.Sprintf("## %s\n", p.GetTitle()),
	)

	// Write the author and ID
	b.WriteString(
		fmt.Sprintf("id: %d; author: **%s**\n", p.GetID(), p.GetAuthor().String()),
	)

	// Write the tags
	tags := p.GetTags()
	for index, tag := range tags {
		tagURL := forumPrefix + "tag/" + tag
		b.WriteString(
			fmt.Sprintf("[#%s](%s)", tag, tagURL),
		)

		if index != len(tags)-1 {
			b.WriteString(" ")

			continue
		}

		b.WriteString("\n")
	}

	// Write the body
	b.WriteString(
		fmt.Sprintf("%s\n", p.GetBody()),
	)

	// Write the comment section
	b.WriteString("## Comments\n\n")

	comments := p.GetComments()
	if len(comments) == 0 {
		b.WriteString("No comments to display")
	} else {
		for _, comment := range comments {
			b.WriteString(renderComment(comment))

			b.WriteString("\n")
		}
	}

	return b.String()
}

// renderComment renders a single comment
func renderComment(c *forum.Comment) string {
	var b bytes.Buffer

	// Write out the body
	b.WriteString(
		fmt.Sprintf("%s\n", c.GetBody()),
	)

	// Write out the author
	b.WriteString(
		fmt.Sprintf("author: %s\n", c.GetAuthor().String()),
	)

	return b.String()
}
