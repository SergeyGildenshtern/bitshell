# frozen_string_literal: true

require_relative 'wallet_initializer'
%w[wallet_printer balance_fetcher funds_sender].each do |handler|
  require_relative "handlers/#{handler}"
end

class Bitshell
  def initialize
    @key = WalletInitializer.new.call
    @prompt = TTY::Prompt.new(track_history: false, interrupt: :signal)

    clear_output
    @prompt.ok('Welcome to BitShell!')
  end

  def call
    loop do
      handler = @prompt.select("\nMenu:", cycle: true) do |menu|
        menu.choice 'Wallet address', WalletPrinter
        menu.choice 'Get balance', BalanceFetcher
        menu.choice 'Send funds', FundsSender
        menu.choice 'Exit', -> { exit }
      end

      clear_output
      handler.new(@key, @prompt).call
    end
  rescue Interrupt
    nil
  end

  private

  def clear_output
    system 'clear'
  end
end
