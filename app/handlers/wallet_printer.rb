# frozen_string_literal: true

require_relative 'base'

class WalletPrinter < Base
  def call
    @prompt.ok("Your wallet address: #{@key.to_addr}")
  end
end
