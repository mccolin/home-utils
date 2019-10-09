#!/usr/bin/env ruby

require 'table_print'

args = ARGV.dup
base = args.shift.to_i
num_years = (args.shift || 10).to_i
percentages = [4, 6, 8]

def compound_interest(p, r, t, n)
  a = p * (1 + r/n) ** (n*t)
end

def currency(val)
  "$ #{'%9.2f' % val}"
end

results = []

percentages.each do |pct|
  rate = pct / 100.0

  puts "Starting salary of #{currency(base)}, earning #{pct}% raises annually:"

  results = []
  1.upto(num_years) do |year|
    results << {
      year: year,
      sal: currency(compound_interest(base, rate, year, 1))
    }
  end
  tp results
  puts 
end



