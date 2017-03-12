require 'open-uri'
require 'rexml/document'


module Weatherly
  class WeewxSource
    include Cinch::Plugin

    attr_reader :current_feed_state

    timer 30, method: :fetch
    def fetch
      feed = REXML::Document.new open(config[:source])

      if @current_feed_state != feed
        @bot.channels.each do |c| 
          c.send REXML::XPath.first(feed, "//item/description").text
        end
      end

      @current_feed_state = feed
    end
  end
end
