# frozen_string_literal: true

class WalletInitializer
  PRIVATE_KEY_PATH = File.expand_path('../../.wallet/private.key', $PROGRAM_NAME)
  KEY_TYPE = Bitcoin::Key::TYPES[:p2wpkh]

  def call
    create_wallet_directory
    private_key_exist? ? read_key : generate_key
  end

  private

  def create_wallet_directory
    FileUtils.mkdir_p(File.dirname(PRIVATE_KEY_PATH))
  end

  def private_key_exist?
    File.exist?(PRIVATE_KEY_PATH)
  end

  def read_key
    private_key = File.read(PRIVATE_KEY_PATH)
    Bitcoin::Key.new(priv_key: private_key, key_type: KEY_TYPE)
  end

  def generate_key
    key = Bitcoin::Key.generate(KEY_TYPE)
    File.write(PRIVATE_KEY_PATH, key.priv_key)

    key
  end
end
