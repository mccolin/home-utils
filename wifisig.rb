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

require 'colorize'

puts "Walk around and observe changes to signal, Ctrl-C to break...\n\n"

stats = %w(agrCtlRSSI agrCtlNoise maxRate lastTxRate)
while true
  output = %x{/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I}
  network = output.match(/\s+SSID\:\s+(.+)/)[1]
  signal = output.match(/agrCtlRSSI\:\s+(-?\d*\.{0,1}\d+)/)[1].to_i
  noise = output.match(/agrCtlNoise\:\s+(-?\d*\.{0,1}\d+)/)[1].to_i
  diff = signal - noise

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

  puts "#{network}\tSignal: #{signal.to_s.rjust(4)}\tNoise: #{noise.to_s.rjust(4)}\tDiff: #{diff.to_s.rjust(3)}\t#{strength_eval}\t#{noise_eval}"

  # values = {}
  # stats.each do |stat_name|
  #   re = Regexp.new("#{stat_name}\:\\s+(-?\\d*\\.{0,1}\\d+)")
  #   values[stat_name] = output.match(re)[1].to_i
  # end
  # puts "#{network}\t#{values.to_a.join("\t")}"
  sleep 1
end
