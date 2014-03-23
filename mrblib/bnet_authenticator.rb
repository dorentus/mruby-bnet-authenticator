# The Battle.net authenticator
class BnetAuthenticator
  # @!attribute [r] serial
  # @return [String] serial
  def serial
    self.class.prettify_serial(@normalized_serial)
  end

  # @!attribute [r] secret
  # @return [String] hexified secret
  attr_reader :secret

  # @!attribute [r] restorecode
  # @return [String] restoration code
  def restorecode
    restorecode_bin = Digest::SHA1.digest(@normalized_serial + [secret].pack('H*'))
    self.class.encode_restorecode(restorecode_bin.split(//).last(10).join)
  end

  # @!attribute [r] region
  # @return [Symbol] region
  def region
    self.class.extract_region(@normalized_serial)
  end

  # Create a new authenticator with given serial and secret
  # @param serial [String]
  # @param secret [String]
  def initialize(serial, secret)
    raise BadInputError.new("bad serial #{serial}") unless self.class.is_valid_serial?(serial)
    raise BadInputError.new("bad secret #{secret}") unless self.class.is_valid_secret?(secret)

    @normalized_serial = self.class.normalize_serial(serial)
    @secret = secret
  end

  # Request a new authenticator from server
  # @param region [Symbol]
  # @return [Bnet::Authenticator]
  def self.request_authenticator(region)
    region = region.to_s.upcase.to_sym
    raise BadInputError.new("bad region #{region}") unless is_valid_region?(region)

    k = create_one_time_pad(37)
    model = ("\0" * (16 - CLIENT_MODEL.length) + CLIENT_MODEL)[0, 16]

    payload_plain = "\1" + k + region.to_s + model
    e = rsa_encrypt_bin(payload_plain)

    response_body = request_for('new serial', region, ENROLLMENT_REQUEST_PATH, e)

    decrypted = decrypt_response(response_body[8, 37], k)

    Authenticator.new(decrypted[20, 17], decrypted[0, 20].unpack('H*')[0])
  end

  # Restore an authenticator from server
  # @param serial [String]
  # @param restorecode [String]
  # @return [Bnet::Authenticator]
  def self.restore_authenticator(serial, restorecode)
    raise BadInputError.new("bad serial #{serial}") unless is_valid_serial?(serial)
    raise BadInputError.new("bad restoration code #{restorecode}") unless is_valid_restorecode?(restorecode)

    normalized_serial = normalize_serial(serial)
    region = extract_region(normalized_serial)

    # stage 1
    challenge = request_for('restore (stage 1)', region, RESTORE_INIT_REQUEST_PATH, normalized_serial)

    # stage 2
    key = create_one_time_pad(20)

    digest = Digest::HMAC.digest(normalized_serial + challenge,
                                 decode_restorecode(restorecode),
                                 Digest::SHA1)

    payload = normalized_serial + rsa_encrypt_bin(digest + key)

    response_body = request_for('restore (stage 2)', region, RESTORE_VALIDATE_REQUEST_PATH, payload)

    Authenticator.new(prettify_serial(normalized_serial), decrypt_response(response_body, key).unpack('H*')[0])
  end

  # Get server's time
  # @param region [Symbol]
  # @return [Integer] server timestamp in seconds
  def self.request_server_time(region)
    raise BadInputError.new("bad region #{region}") unless is_valid_region?(region)

    server_time_big_endian = request_for('server time', region, TIME_REQUEST_PATH)

    (0...4).map do |i|
      server_time_big_endian.bytes[i * 2, 2].map do |c|
        c.chr
      end.join.unpack('S>')[0] * 2 ** (16 * (3 - i))
    end.reduce(:+) / 1000
  end

  # Get token from given secret and timestamp
  # @param secret [String] hexified secret
  # @param timestamp [Integer] UNIX timestamp in seconds,
  #   defaults to current time
  # @return [String, Integer] token and the next timestamp token to change
  def self.get_token(secret, timestamp = nil)
    raise BadInputError.new("bad seret #{secret}") unless is_valid_secret?(secret)

    current = ((timestamp || Time.now.getutc.to_i) / 30).to_i
    digest = Digest::HMAC.digest("\0\0\0\0" + [current].pack('L>'), [secret].pack('H*'), Digest::SHA1)
    start_position = digest[19].unpack('C')[0] & 0xf

    token = digest[start_position, 4].bytes.each_with_index.map do |v, index|
      v * 2 ** (8 * (3 - index))
    end.reduce(:+) & 0x7fffffff

    return sprintf('%08d', token % 100000000), (current + 1) * 30
  end

  # Get authenticator's token from given timestamp
  # @param timestamp [Integer] UNIX timestamp in seconds,
  #   defaults to current time
  # @return [String, Integer] token and the next timestamp token to change
  def get_token(timestamp = nil)
    self.class.get_token(@secret, timestamp)
  end

  # Hash representation of this authenticator
  # @return [Hash]
  def to_hash
    {
      :serial => serial,
      :secret => secret,
      :restorecode => restorecode,
      :region => region,
    }
  end

  # String representation of this authenticator
  # @return [String]
  def to_s
    to_hash.to_s
  end

end
