module Bnet

  # The Battle.net authenticator
  class Authenticator
    # @!attribute [r] serial
    # @return [String] serial
    def serial
      Util.prettify_serial(@normalized_serial)
    end

    # @!attribute [r] secret
    # @return [String] hexified secret
    attr_reader :secret

    # @!attribute [r] restorecode
    # @return [String] restoration code
    def restorecode
      restorecode_bin = Digest::SHA1.digest(@normalized_serial + [secret].pack('H*'))
      Util.encode_restorecode(restorecode_bin.split(//).last(10).join)
    end

    # @!attribute [r] region
    # @return [Symbol] region
    def region
      Util.extract_region(@normalized_serial)
    end

    # Create a new authenticator with given serial and secret
    # @param serial [String]
    # @param secret [String]
    def initialize(serial, secret)
      raise Bnet::BadInputError.new("bad serial #{serial}") unless Util.is_valid_serial?(serial)
      raise Bnet::BadInputError.new("bad secret #{secret}") unless Util.is_valid_secret?(secret)

      @normalized_serial = Util.normalize_serial(serial)
      @secret = secret
    end

    # Request a new authenticator from server
    # @param region [Symbol]
    # @return [Bnet::Authenticator]
    def self.request_authenticator(region)
      region = region.to_s.upcase.to_sym
      raise Bnet::BadInputError.new("bad region #{region}") unless Util.is_valid_region?(region)

      k = Util.create_one_time_pad(37)
      model = ("\0" * (16 - CLIENT_MODEL.length) + CLIENT_MODEL)[0, 16]

      payload_plain = "\1" + k + region.to_s + model
      e = Util.rsa_encrypt_bin(payload_plain)

      response_body = Util.request_for('new serial', region, ENROLLMENT_REQUEST_PATH, e)

      decrypted = Util.decrypt_response(response_body[8, 37], k)

      Authenticator.new(decrypted[20, 17], decrypted[0, 20].unpack('H*')[0])
    end

    # Restore an authenticator from server
    # @param serial [String]
    # @param restorecode [String]
    # @return [Bnet::Authenticator]
    def self.restore_authenticator(serial, restorecode)
      raise Bnet::BadInputError.new("bad serial #{serial}") unless Util.is_valid_serial?(serial)
      raise Bnet::BadInputError.new("bad restoration code #{restorecode}") unless Util.is_valid_restorecode?(restorecode)

      normalized_serial = Util.normalize_serial(serial)
      region = Util.extract_region(normalized_serial)

      # stage 1
      challenge = Util.request_for('restore (stage 1)', region, RESTORE_INIT_REQUEST_PATH, normalized_serial)

      # stage 2
      key = Util.create_one_time_pad(20)

      digest = Digest::HMAC.digest(normalized_serial + challenge,
                                   Util.decode_restorecode(restorecode),
                                   Digest::SHA1)

      payload = normalized_serial + Util.rsa_encrypt_bin(digest + key)

      response_body = Util.request_for('restore (stage 2)', region, RESTORE_VALIDATE_REQUEST_PATH, payload)

      Authenticator.new(Util.prettify_serial(normalized_serial), Util.decrypt_response(response_body, key).unpack('H*')[0])
    end

    # Get server's time
    # @param region [Symbol]
    # @return [Integer] server timestamp in seconds
    def self.request_server_time(region)
      raise Bnet::BadInputError.new("bad region #{region}") unless Util.is_valid_region?(region)

      server_time_big_endian = Util.request_for('server time', region, TIME_REQUEST_PATH)

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
      raise Bnet::BadInputError.new("bad seret #{secret}") unless Util.is_valid_secret?(secret)

      current = ((timestamp || Time.now.getutc.to_i) / 30).to_i
      payload = "\0\0\0\0" + Bnet::Util.unit32_split_to_unit16_be(current).pack('S>S>')

      digest = Digest::HMAC.digest(payload, [secret].pack('H*'), Digest::SHA1)
      start_position = digest[19].unpack('C')[0] & 0xf

      masks = [0x7f, 0xff, 0xff, 0xff]
      token = digest[start_position, 4].bytes.each_with_index.map do |v, index|
        (v & masks[index]) * 2 ** (8 * (3 - index))
      end.reduce(:+)

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

end
