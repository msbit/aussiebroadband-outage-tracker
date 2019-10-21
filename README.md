# Aussie Broadband Outage Tracker

Script to track changes to a specific outage of Aussie Broadband, as listed [here](https://www.aussiebroadband.com.au/help-centre/system-outages/), and to send an email with those changes.

## Implementation

The script polls the `outages` page every minute, and compares the previous details with the current. If there is a change, it will send an email to the nominated email address, with the changes and the current details.

## Usage

    EMAIL_TO=<email address> OUTAGE_REFERENCE=<outage reference number> ./aussiebroadband_outage_tracker.rb
