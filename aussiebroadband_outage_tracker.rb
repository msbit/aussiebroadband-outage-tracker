#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler'

Bundler.require(:default)

trap 'SIGINT' do
  puts 'Exiting'
  exit 130
end

MULTIPLE_KEYS = %w[areas].freeze
MARKED_UP_KEYS = %w[eta prio].freeze

def get_details(reference)
  uri = URI('https://www.aussiebroadband.com.au')
  uri.path = '/outages.php'
  uri.query = URI.encode_www_form(
    mode: 'View',
    id: reference
  )
  response = HTTParty.get(uri)

  body = JSON.parse(response.body)

  MULTIPLE_KEYS.each { |k| body[k] = body[k].split('<br/>') }
  MARKED_UP_KEYS.each { |k| body[k] = Nokogiri::HTML(body[k]).text }

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
