class InstagramPostSchema < RubyLLM::Schema
  string :title, description: "A short, descriptive title for the Instagram post (internal label)."
  string :hook, description: "The opening line of the caption — the hook visible before 'more'."
  string :body, description: "The full caption body following the hook, including hashtags."
end
