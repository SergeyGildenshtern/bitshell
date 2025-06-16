# frozen_string_literal: true

require_relative 'base'

class FundsSender < Base
  INPUT_SIZE_IN_BYTES  = 148
  OUTPUT_SIZE_IN_BYTES = 34
  HEADER_SIZE_IN_BYTES = 10

  def call
    amount, address = ask_for_transaction_details
    return unless sufficient_funds?(amount)

    tx = create_transaction(amount, address)
    txid = Mempool.post('tx', tx.to_hex).body

    @prompt.ok("Transaction created successfully: #{txid}")
  rescue Faraday::Error
    @prompt.error('Network error')
  end

  private

  def ask_for_transaction_details
    amount = @prompt.ask('Enter the amount of BTC to send:') do |q|
      q.validate(/^\d+(\.\d{1,8})?$/)
      q.validate ->(input) { input.to_f.positive? }
      q.messages[:valid?] = 'Please enter a valid amount'
    end

    address = @prompt.ask('Enter the address to send BTC to:') do |q|
      q.validate(/^[a-zA-Z0-9]+$/)
      q.messages[:valid?] = 'Please enter a valid address'
    end

    [btc_to_satoshi(amount), address]
  end

  def sufficient_funds?(amount)
    total_available = available_utxos.sum { |utxo| utxo[:value] }
    fee = calculate_fee(in_count: available_utxos.size, out_count: 1)

    if total_available < amount + fee
      available_funds = 'Available: %.8f BTC' % satoshi_to_btc(total_available)
      unless total_available.zero?
        available_funds += ' (including fee: %.8f BTC)' % satoshi_to_btc(fee)
      end

      @prompt.error('Insufficient funds')
      @prompt.error(available_funds)
      return false
    end

    true
  end

  def create_transaction(amount, address)
    tx = Bitcoin::Tx.new
    change_script = Bitcoin::Script.parse_from_addr(@key.to_addr)
    recipient_script = Bitcoin::Script.parse_from_addr(address)

    utxos, fee = get_utxos_and_fee(amount)
    total_input = utxos.sum { |utxo| utxo[:value] }
    change_amount = total_input - amount - fee

    utxos.each do |utxo|
      tx.inputs << Bitcoin::TxIn.new(
        out_point: Bitcoin::OutPoint.from_txid(utxo[:txid], utxo[:vout])
      )
    end

    tx.outputs << Bitcoin::TxOut.new(value: amount, script_pubkey: recipient_script)
    if change_amount.positive?
      tx.outputs << Bitcoin::TxOut.new(value: change_amount, script_pubkey: change_script)
    end

    utxos.each_with_index do |utxo, index|
      sig_hash = tx.sighash_for_input(
        index,
        change_script,
        amount: utxo[:value],
        sig_version: :witness_v0
      )
      signature = @key.sign(sig_hash, false) + [Bitcoin::SIGHASH_TYPE[:all]].pack('C')

      tx.inputs[index].script_witness.stack << signature
      tx.inputs[index].script_witness.stack << @key.pubkey.htb
    end

    tx
  end

  def get_utxos_and_fee(amount)
    fee = calculate_fee(in_count: 1, out_count: 1)
    exact_utxo = available_utxos.find { |utxo| utxo[:value] == amount + fee }
    return [[exact_utxo], fee] if exact_utxo

    selected_utxos = []
    total_value = 0

    available_utxos.each do |utxo|
      selected_utxos << utxo
      total_value += utxo[:value]

      fee = calculate_fee(in_count: selected_utxos.size, out_count: 2)
      break if total_value >= amount + fee
    end

    [selected_utxos, calculate_fee(in_count: selected_utxos.size, out_count: 2)]
  end

  def available_utxos
    return @available_utxos if defined?(@available_utxos)

    utxos = Mempool.get("address/#{@key.to_addr}/utxo").body

    @available_utxos = utxos.select { |utxo| utxo.dig(:status, :confirmed) }
                            .map { |utxo| utxo.except(:status) }
                            .sort_by { |utxo| utxo[:value] }
                            .reverse
  end

  def calculate_fee(in_count:, out_count:)
    fee_per_vbyte * (
      (in_count * INPUT_SIZE_IN_BYTES) +
      (out_count * OUTPUT_SIZE_IN_BYTES) +
      HEADER_SIZE_IN_BYTES
    )
  end

  def fee_per_vbyte
    @fee_per_vbyte ||= Mempool.get('v1/fees/recommended').body[:hourFee]
  end
end
