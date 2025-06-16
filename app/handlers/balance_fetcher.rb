# frozen_string_literal: true

require_relative 'base'

class BalanceFetcher < Base
  def call
    confirmed_balance   = calculate_balance(address[:chain_stats])
    unconfirmed_balance = calculate_balance(address[:mempool_stats])
    balance             = confirmed_balance + unconfirmed_balance

    @prompt.ok   "Your balance:      #{format_balance(balance)} BTC"
    @prompt.warn "Confirmed funds:   #{format_balance(confirmed_balance)} BTC"
    @prompt.warn "Unconfirmed funds: #{format_balance(unconfirmed_balance)} BTC"
  rescue Faraday::Error
    @prompt.error('Network error')
  end

  private

  def address
    @address ||= Mempool.get("address/#{@key.to_addr}").body
  end

  def calculate_balance(stats)
    satoshi_to_btc(stats[:funded_txo_sum] - stats[:spent_txo_sum])
  end

  def format_balance(value)
    format('%15.8f', value)
  end
end
