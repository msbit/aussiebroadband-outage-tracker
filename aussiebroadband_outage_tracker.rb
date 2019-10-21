#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler'

Bundler.require(:default)

trap 'SIGINT' do
  puts 'Exiting'
  exit 130
end

DETAILS_MIDDLEWARE = []

DETAILS_MIDDLEWARE.push(lambda do |details|
  ['areas'].each { |k| details[k] = details[k].split('<br/>') }
end)

DETAILS_MIDDLEWARE.push(lambda do |details|
  ['eta', 'prio'].each { |k| details[k] = Nokogiri::HTML(details[k]).text }
end)

DETAILS_MIDDLEWARE.push(lambda do |details|
  details.delete('eta') if details['future']
end)

def get_details(reference)
  uri = URI('https://www.aussiebroadband.com.au')
  uri.path = '/outages.php'
  uri.query = URI.encode_www_form(
    mode: 'View',
    id: reference
  )
  response = HTTParty.get(uri)

  details = JSON.parse(response.body)

  DETAILS_MIDDLEWARE.each { |m| m.call(details) }

  details
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
