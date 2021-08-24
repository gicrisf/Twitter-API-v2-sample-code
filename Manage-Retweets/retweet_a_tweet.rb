# This script implements the PIN-based OAuth flow to obtain access tokens for a user context request
# It then makes a User lookup request (by usernames) with OAuth 1.0a authentication (user context)
require 'oauth'
require 'json'
require 'typhoeus'
require 'oauth/request_proxy/typhoeus_request'

# The code below sets the consumer key and secret from your environment variables
# To set environment variables on Mac OS X, run the export command below from the terminal:
# export CONSUMER_KEY='YOUR-KEY', CONSUMER_SECRET='YOUR-SECRET'
consumer_key = ENV["CONSUMER_KEY"]
consumer_secret = ENV["CONSUMER_SECRET"]

# Be sure to add replace id of the user you wish to retweet on behalf of.
# You can find a user ID by using the user lookup endpoint
id = "your-user-id"
retweets_url = "https://api.twitter.com/2/users/#{id}/retweets"

# Be sure to replace tweet-id with your the Tweet ID you want to retweet
# You can find a Tweet ID by using the Tweet lookup endpoint
@tweet_id = { "tweet_id": "1412865600439738368" }

consumer = OAuth::Consumer.new(consumer_key, consumer_secret,
	                                :site => 'https://api.twitter.com',
	                                :authorize_path => '/oauth/authenticate',
	                                :debug_output => false)

def get_request_token(consumer)

	request_token = consumer.get_request_token()

  return request_token
end

def get_user_authorization(request_token)
	puts "Follow this URL to have a user authorize your app: #{request_token.authorize_url()}"
	puts "Enter PIN: "
	pin = gets.strip

  return pin
end

def obtain_access_token(consumer, request_token, pin)
	token = request_token.token
	token_secret = request_token.secret
	hash = { :oauth_token => token, :oauth_token_secret => token_secret }
	request_token  = OAuth::RequestToken.from_hash(consumer, hash)

	# Get access token
	access_token = request_token.get_access_token({:oauth_verifier => pin})

	return access_token
end


def user_retweet(url, oauth_params)
	options = {
	    :method => :post,
	    headers: {
	     	"User-Agent": "v2retweetUserRuby",
        "content-type": "application/json"
	    },
	    body: JSON.dump(@tweet_id)
	}
	request = Typhoeus::Request.new(url, options)
	oauth_helper = OAuth::Client::Helper.new(request, oauth_params.merge(:request_uri => url))
	request.options[:headers].merge!({"Authorization" => oauth_helper.header}) # Signs the request
	response = request.run

	return response
end



# PIN-based OAuth flow - Step 1
request_token = get_request_token(consumer)
# PIN-based OAuth flow - Step 2
pin = get_user_authorization(request_token)
# PIN-based OAuth flow - Step 3
access_token = obtain_access_token(consumer, request_token, pin)

oauth_params = {:consumer => consumer, :token => access_token}


response = user_retweet(retweets_url, oauth_params)
puts response.code, JSON.pretty_generate(JSON.parse(response.body))