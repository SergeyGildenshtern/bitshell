# frozen_string_literal: true

require 'bundler/setup'
Bundler.require(:default)

Bitcoin.chain_params = :signet

Mempool = Faraday.new('https://mempool.space/signet/api') do |faraday|
  faraday.request :json
  faraday.response :json, parser_options: { symbolize_names: true }
  faraday.response :raise_error
end
