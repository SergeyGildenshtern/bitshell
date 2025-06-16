# frozen_string_literal: true

class Base
  SATOSHI_IN_BTC = BigDecimal('100000000')

  def initialize(key, prompt)
    @key    = key
    @prompt = prompt
  end

  private

  def btc_to_satoshi(btc)
    (BigDecimal(btc.to_s) * SATOSHI_IN_BTC).to_i
  end

  def satoshi_to_btc(satoshi)
    BigDecimal(satoshi.to_s) / SATOSHI_IN_BTC
  end
end
