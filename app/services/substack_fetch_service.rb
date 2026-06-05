require "open-uri"

# Fetches and caches posts from a single SubstackSource's RSS feed.
#
# Uses feedjira instead of stdlib rss: Substack feeds embed raw HTML in
# description elements which breaks REXML (the strict XML parser behind the
# stdlib gem). Feedjira uses Nokogiri and handles real-world malformed feeds.
#
# Usage:
#   SubstackFetchService.call(source) # => true on success, false on network error
#
# Caps at MAX_ENTRIES so a large feed doesn't hammer the DB on first import.
class SubstackFetchService
  TIMEOUT     = 10
  MAX_ENTRIES = 20

  def self.call(source)
    new(source).call
  end

  def initialize(source)
    @source = source
  end

  def call
    feed = fetch_feed
    return false unless feed

    upsert_posts(feed.entries)
    @source.update_columns(fetched_at: Time.current)
    true
  rescue => e
    Rails.logger.error("SubstackFetchService error (source #{@source.id}): #{e.message}")
    false
  end

  private

  def fetch_feed
    # open-uri follows redirects automatically, which handles Substack publications
    # that have moved to a custom domain (they 301 from *.substack.com/feed).
    xml = URI.open(@source.feed_url, read_timeout: TIMEOUT, open_timeout: TIMEOUT, &:read)
    Feedjira.parse(xml)
  rescue Feedjira::NoParserAvailable
    Rails.logger.warn("SubstackFetchService: #{@source.feed_url} did not return a valid feed (got HTML?)")
    nil
  rescue OpenURI::HTTPError, SocketError, Timeout::Error, RuntimeError => e
    Rails.logger.warn("SubstackFetchService: could not reach #{@source.feed_url} — #{e.message}")
    nil
  end

  def upsert_posts(entries)
    entries.first(MAX_ENTRIES).each do |entry|
      guid = entry.entry_id.presence || entry.url
      next if guid.blank?

      record = @source.substack_posts.find_or_initialize_by(guid: guid)
      record.title        = entry.title.presence
      record.url          = entry.url.presence
      record.author       = entry.author.presence
      record.published_at = entry.published
      record.summary      = summary_for(entry)
      record.save!
    end
  end

  def summary_for(entry)
    raw = entry.summary.presence || entry.content.presence || ""
    ActionController::Base.helpers.strip_tags(raw).gsub(/\s+/, " ").strip.truncate(500)
  end
end
