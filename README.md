# Stitch Money

A Ruby wrapper for the [Stitch](https://stitch.money/) API.

THIS IS NOT YET PRODUCTION READY, WHEN IT IS THIS MESSAGE WILL BE REMOVED.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'stitch_money'
```

And then execute:

```zsh
bundle install
```

Or install it yourself by using the following command:

```zsh
gem install stitch_money
```

## Usage

### Initialize the Client

```ruby
require 'stitch_money'

# Initialize the client with your API key
client = StitchMoney::Client.new("your_api_key")
```

### Fetch Payment Request Status

```ruby
payment_request_id = "the_actual_payment_request_id_goes_here"

# Call the method to fetch payment request status
response = client.get_payment_request_status(payment_request_id)

# Process the response
if response.key?("error")
  puts "Error: #{response['error']} (Status Code: #{response['code']})"
else
  # Access the data from the response
  payment_request = response['data']['node']
  puts "Payment Request ID: #{payment_request['id']}"
  puts "Payer Reference: #{payment_request['payerReference']}"
  puts "Beneficiary Reference: #{payment_request['beneficiaryReference']}"
  # Add more attributes as needed
end
```
