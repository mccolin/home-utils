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

@num_polls = 0
@tot_signal = 0
@tot_noise = 0
@tot_diff = 0

class WifiSignal
  attr_reader :network_name, :strength, :noise, :diff, :grade, :clarity, :analysis

  def initialize (network_name:, strength:, noise:, diff:)
    @network_name = network_name
    @strength = strength
    @noise = noise
    @diff = diff
    self.analyze!
  end

  def analyze!
    @analysis = {strength: 'Z', noise: 'Untested'}
    @analysis[:strength] = if @strength > -50
      "A+".green
    elsif @strength > -67
      "A ".green
    elsif @strength > -70
      "B ".yellow
    elsif @strength > -80
      "C ".light_red
    elsif @strength > -90
      "D ".red
    else
      "F ".red
    end
    @analysis[:noise] = if @diff > 20
      "Clear".green
    elsif @diff > 15
      "Murky".yellow
    elsif @diff > 10
      "Polluted".light_red
    else
      "Too Noisy".red
    end
  end

  def pretty_analysis

  end

  def self.capture
    output = %x{/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I}
    network_name = output.match(/\s+SSID\:\s+(.+)/)[1]
    strength = output.match(/agrCtlRSSI\:\s+(-?\d*\.{0,1}\d+)/)[1].to_i
    noise = output.match(/agrCtlNoise\:\s+(-?\d*\.{0,1}\d+)/)[1].to_i
    return WifiSignal.new(
      network_name: network_name,
      strength: strength,
      noise: noise,
      diff: strength - noise
    )
  end
end # WifiSignal

sig = WifiSignal.capture
puts sig.inspect

def handle_interrupt
  puts "\n\nAverage Analysis:"
  puts "- #{@num_polls} #{@num_polls == 1 ? 'poll' : 'polls'}"
  puts "- #{@tot_signal / @num_polls} average signal"
  puts "- #{@tot_noise / @num_polls} average noise"
  puts "- #{@tot_diff / @num_polls} average difference"
  puts "-> Overall Analysis: ** TBD **"
  exit!
end
trap("SIGINT") { handle_interrupt() }

require 'colorize'

puts "Walk around and observe changes to signal, Ctrl-C to break...\n\n"

puts "#{'Network'.ljust(20)} #{'Signal'.ljust(8)} #{'Noise'.ljust(8)} #{'Diff'.ljust(8)} Analysis"

stats = %w(agrCtlRSSI agrCtlNoise maxRate lastTxRate)
while true
  output = %x{/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I}
  network = output.match(/\s+SSID\:\s+(.+)/)[1]
  signal = output.match(/agrCtlRSSI\:\s+(-?\d*\.{0,1}\d+)/)[1].to_i
  noise = output.match(/agrCtlNoise\:\s+(-?\d*\.{0,1}\d+)/)[1].to_i
  diff = signal - noise

  @num_polls += 1
  @tot_signal += signal
  @tot_noise += noise
  @tot_diff += diff

  strength_eval = if signal > -50
    "A+".green
  elsif signal > -67
    "A ".green
  elsif signal > -70
    "B ".yellow
  elsif signal > -80
    "C ".light_red
  elsif signal > -90
    "D ".red
  else
    "F ".red
  end

  noise_eval = if diff > 20
    "Clear".green
  elsif diff > 15
    "Murky".yellow
  elsif diff > 10
    "Polluted".light_red
  else
    "Too Noisy".red
  end

  complete_eval = "#{strength_eval} / #{noise_eval}"

  #puts "#{network}\tSignal: #{signal.to_s.rjust(4)}\tNoise: #{noise.to_s.rjust(4)}\tDiff: #{diff.to_s.rjust(3)}\t#{strength_eval}\t#{noise_eval}"
  puts "#{network.ljust(20)} #{signal.to_s.ljust(8)} #{noise.to_s.ljust(8)} #{diff.to_s.ljust(8)} #{complete_eval}"

  # values = {}
  # stats.each do |stat_name|
  #   re = Regexp.new("#{stat_name}\:\\s+(-?\\d*\\.{0,1}\\d+)")
  #   values[stat_name] = output.match(re)[1].to_i
  # end
  # puts "#{network}\t#{values.to_a.join("\t")}"
  sleep 1
end
