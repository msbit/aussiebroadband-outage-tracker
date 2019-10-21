#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler'

Bundler.require(:default)

trap 'SIGINT' do
  puts 'Exiting'
  exit 130
end

def get_details(reference)
  response = HTTParty.get("https://www.aussiebroadband.com.au/outages.php?mode=View&id=#{reference}")

  body = JSON.parse(response.body)

  body
end

puts 'Fetching initial'
previous_details = get_details(ENV['OUTAGE_REFERENCE'])

loop do
  sleep(60)

  puts 'Fetching current'
  current_details = get_details(ENV['OUTAGE_REFERENCE'])

  diff = Hashdiff.diff(previous_details, current_details)
  next if diff.empty?

  pretty_diff = JSON.pretty_generate(diff)
  pretty_current_details = JSON.pretty_generate(current_details)

  Pony.mail(
    to: ENV['EMAIL_TO'],
    via: :sendmail,
    subject: "Outage #{ENV['OUTAGE_REFERENCE']} has changed",
    body: "Changes:\n\n#{pretty_diff}\n\nCurrent:\n\n#{pretty_current_details}"
  )

  previous_details = current_details
end
