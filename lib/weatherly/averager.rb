module Weatherly

  # This plugin uses the output of another weather bot to print 3h-averages.
  class Averager
    include Cinch::Plugin

    AVERAGING_INTERVAL = 3 * 60 * 60

    def initialize(*args)
      super

      @values = []
      @mutex = Mutex.new
      @summarizer = Thread.new do
        while true do
          now = Time.now
          alarm = now.to_i -
            (now.to_i % AVERAGING_INTERVAL) +
            AVERAGING_INTERVAL
          sleep alarm.to_i - now.to_i

          print_summary unless @values.empty?
        end
      end
    end

    match /Outside\stemperature:\s([\d.]+)°C;\s
          Barometer:\s(\d+)\smbar;\s
          Wind:\s((?:[\d.]+\sm\/s)|(?:N\/A))\sfrom\s((?:\d+°)|(?:N\/A));\s
          Rain\srate:\s([\d.]+)\smm\/h;\s
          Inside\stemperature:\s([\d.]+)°C/x,
      use_prefix: false
    def execute(m, *matches)
      @mutex.synchronize do
        @values.push(matches.map do |v|
          v.gsub! /[^\d.]/, ''
          v == '' ? nil : v.to_f
        end)
      end
    end

    def print_summary
      num_values = 0
      num_wind_values = 0

      @mutex.lock

      sums = @values.reduce [0.0, 0.0, 0.0, 0.0, 0.0, 0.0] do |sum, v|
        num_values += 1
        num_wind_values += 1 if v[2]

        sum[0] += v[0]
        sum[1] += v[1]
        sum[2] += (v[2] ? v[2] : 0.0)
        sum[3] += (v[3] ? v[3] : 0.0)
        sum[4] += v[4]
        sum[5] += v[5]

        sum
      end

      @values = []
      @mutex.unlock

      sums[0] /= num_values.to_f
      sums[1] /= num_values.to_f
      sums[2] /= (num_wind_values > 0 ? num_wind_values.to_f : 1)
      sums[3] /= (num_wind_values > 0 ? num_wind_values.to_f : 1)
      sums[4] /= num_values.to_f
      sums[5] /= num_values.to_f

      cond = sprintf("Outside temperature: %.2f°C; Barometer: %.1f mbar; " +
        "Wind: %.2f m/s from %.1f°; Rain rate: %.1f mm/h; " +
        "Inside temperature: %.2f", *sums)
      @bot.channels.each {|c| c.send cond }
    end
  end
end
