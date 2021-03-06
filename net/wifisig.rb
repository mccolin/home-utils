#!/usr/bin/env ruby
#
# Mac Wifi Signal Strength Analyzer
#
# Signal: http://www.metageek.com/training/resources/understanding-rssi.html
# RSSI -30 dBm: Amazing; max achievable strength (unlikely in practice)
# RSSI -67 dBm: Very Good; min signal strength for VoIP, streaming vid, etc.
# RSSI -70 dBm: Okay; min signal strength for reliable packet delivery (can do email, web)
# RSSI -80 dBm: Not Good; min signal strength for basic connectivity
# RSSI -90 dBm: Unusable; approaching floor of functionality
#
# About Signal vs. Noise: https://www.itdojo.com/osx-airport-cli-tool-not-just-for-airport-aps/
# RSSI - Noise > 20dBm => Stable
# RSSI - Noise < 20dBm => Unstable

begin
  require 'colorize'
  puts "Output will be colorized."
rescue Exception => e
  puts "Output will not be colorized (Install colorize gem to add colorization)."
end

def color_it(str, color)
  if str.methods.include?(color.to_sym)
    str.send(color)
  else
    return str
  end
end


class WifiSignal
  attr_reader :network_name, :network_bssid, :strength, :noise, :diff, :grade, :clarity, :analysis

  def initialize (name:, bssid:, strength:, noise:, diff:)
    @network_name = name
    @network_bssid = bssid
    @strength = strength
    @noise = noise
    @diff = diff
    self.analyze!
  end

  def analyze!
    if @strength == 0
      @grade = 'N/A'
    elsif @strength > -50
      @grade = 'A+'
    elsif @strength > -67
      @grade = 'A'  # green
    elsif @strength > -70
      @grade = 'B'  # yellow
    elsif @strength > -80
      @grade = 'C'  # light_red
    elsif @strength > -90
      @grade = 'D'  # red
    else
      @grade = 'F'  # red
    end

    if @noise == 0
      @clarity = "Not Connected"    # purple
    elsif @diff > 20
      @clarity = "Clear"  # green
    elsif @diff > 15
      @clarity = "Murky"  # yellow
    elsif @diff > 10
      @clarity = "Polluted" # light_red
    else
      @clarity = "Too Noisy"  # red
    end

    @analysis = "#{@grade} / #{@clarity}"
  end

  def pretty_analysis
    grade_color = {
      green: /^A.*/,
      yellow: /^B/,
      light_red: /^C/,
      red: /^D|F/,
      purple: /^N/
    }.detect {|color, grade_matcher| @grade =~ grade_matcher }[0]
    clarity_color = {
      green: 'Clear',
      yellow: 'Murky',
      light_red: 'Polluted',
      red: 'Too Noisy',
      purple: 'Not Connected'
    }.detect {|color, clarity| @clarity == clarity }[0]
    return "#{color_it(@grade, grade_color)} / #{color_it(@clarity, clarity_color)}"
  end

  def self.capture
    output = %x{/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I}
    network_name = output.match(/\s+SSID\:\s+(.+)/)[1]
    network_bssid = output.match(/\s+BSSID\:\s+(.+)/)[1]
    strength = output.match(/agrCtlRSSI\:\s+(-?\d*\.{0,1}\d+)/)[1].to_i
    noise = output.match(/agrCtlNoise\:\s+(-?\d*\.{0,1}\d+)/)[1].to_i
    return WifiSignal.new(
      name: network_name,
      bssid: network_bssid,
      strength: strength,
      noise: noise,
      diff: strength - noise
    )
  end
end # WifiSignal

class WifiLocation
  attr_reader :name, :bssid, :signals
  def initialize()
    @name = "Pending..."
    @bssid = "Pending..."
    @signals = []
  end
  def add(signal)
    @name = signal.network_name
    @bssid = signal.network_bssid
    @signals << signal
  end
  def num_polls
    @signals.length
  end
  def average_strength
    @signals.collect(&:strength).sum / num_polls
  end
  def average_noise
    @signals.collect(&:noise).sum / num_polls
  end
  def average_diff
    @signals.collect(&:diff).sum / num_polls
  end
  def pretty_analysis
    WifiSignal.new(
      name: @name,
      bssid: @bssid,
      strength: average_strength,
      noise: average_noise,
      diff: average_diff
    ).pretty_analysis
  end
end


@location = WifiLocation.new()

def handle_interrupt
  puts "\n\nAverage Analysis:"
  disp_name = "#{@location.name} (#{@location.num_polls} #{@location.num_polls == 1 ? 'poll' : 'polls'})"
  puts "#{disp_name.ljust(20)} #{@location.average_strength.to_s.ljust(8)} #{@location.average_noise.to_s.ljust(8)} #{@location.average_diff.to_s.ljust(8)} #{@location.pretty_analysis}\n\n"
  exit(0)
end
trap("SIGINT") { handle_interrupt() }

puts "Walk around and observe changes to signal, Ctrl-C to break...\n\n"

puts "#{'Network'.ljust(20)} #{'BSSID'.ljust(20)} #{'Signal'.ljust(8)} #{'Noise'.ljust(8)} #{'Diff'.ljust(8)} Analysis"

while true
  signal = WifiSignal.capture()
  @location.add( signal )

  puts "#{signal.network_name.ljust(20)} #{signal.network_bssid.ljust(20)} #{signal.strength.to_s.ljust(8)} #{signal.noise.to_s.ljust(8)} #{signal.diff.to_s.ljust(8)} #{signal.pretty_analysis}"

  sleep 1
end
