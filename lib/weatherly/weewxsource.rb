require 'rss'
require 'open-uri'


module Weatherly
  class WeewxSource

    attr_reader :current_feed

    def fetch
      open(options[:source]) do |rss|
        @current_feed = RSS::Parser.parse rss
      end
    end
  end
end
