require 'open-uri'
require 'rexml/document'


module Weatherly

  # This plugin reads an RSS feed from a WeeWX weather station and prints the
  # current conditions to all channels the bot is in.
  class WeewxSource
    include Cinch::Plugin

    attr_reader :current_conditions

    timer 30, method: :fetch
    def fetch
      cond = REXML::XPath.first(
          REXML::Document.new(open(config[:source])),
          "//item/description")
        .text
        .gsub(/\A[\r\n\s]+/m, '')
        .gsub(/[\r\n\s]+\Z/m, '')
        .gsub(/(\s{2,}|[\r\n]+)/m, ' ')

      @bot.channels.each {|c| c.send cond } unless cond.eql? @current_conditions
      @current_conditions = cond
    end
  end
end
