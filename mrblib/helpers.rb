module Bnet

  class Authenticator

      # helper methods
      class << self

        def is_valid_serial?(serial)
          normalized_serial = normalize_serial(serial)
          normalized_serial =~ Regexp.new("^(#{Bnet::AUTHENTICATOR_HOSTS.keys.join('|')})\\d{12}$") && is_valid_region?(extract_region(normalized_serial))
        end

        def normalize_serial(serial)
          serial.upcase.gsub(/-/, '')
        end

        def extract_region(serial)
          serial[0, 2].upcase.to_sym
        end

        def prettify_serial(serial)
          "#{serial[0, 2]}-" + serial[2, 12].scan(/.{4}/).join('-')
        end

        def is_valid_secret?(secret)
          secret =~ /[0-9a-f]{40}/i
        end

        def is_valid_region?(region)
          Bnet::AUTHENTICATOR_HOSTS.has_key? region
        end

        def is_valid_restorecode?(restorecode)
          restorecode =~ /[0-9A-Z]{10}/
        end

        def encode_restorecode(bin)
          bin.bytes.map do |v|
            Bnet::RESTORECODE_MAP[v & 0x1f]
          end.pack('C*')
        end

        def decode_restorecode(str)
          str.bytes.map do |c|
            Bnet::RESTORECODE_MAP_INVERSE[c]
          end.pack('C*')
        end

        def create_one_time_pad(length)
          (0..1.0/0.0).reduce('') do |memo, i|
            break memo if memo.length >= length
            memo << Digest::SHA1.digest(rand().to_s)
          end[0, length]
        end

        def decrypt_response(text, key)
          text.bytes.zip(key.bytes).reduce('') do |memo, pair|
            memo + (pair[0] ^ pair[1]).chr
          end
        end

        def rsa_encrypt_bin(bin)
          # TODO: fix this
          i = bin.unpack('H*')[0].to_i(16)  # bin to i
          v = i ** Bnet::RSA_KEY % Bnet::RSA_MOD # RSA
          v.to_s(16).scan(/.{2}/).map {|s| s.to_i(16)}.pack('C*') # i to bin
        end

        def request_for(label, region, path, body = nil)
          host = Bnet::AUTHENTICATOR_HOSTS[region]
          method = body.nil? ? 'GET' : 'POST'

          headers = [
            "Host: #{host}",
            "User-Agent: mruby-bnet-authenticator",
            "Accept: */*",
            "Content-type: application/octet-stream",
          ]
          headers.push("Content-Length: #{body.to_s.length}") unless body.nil?
          q = "#{method} #{path} HTTP/1.0\r\n#{headers.join("\r\n")}\r\n\r\n#{body.to_s}"

          socket = TCPSocket.new(host, 80)
          socket.write(q)
          response_text = ''
          while ( t = socket.read(1024) )
            response_text << t
          end
          socket.close

          response_header, response_body = response_text.split("\r\n\r\n", 2)

          response_code = response_header.split("\r\n")[0].split(" ", 3)[1].to_i
          if response_code != 200
            raise RequestFailedError.new("Error requesting #{label}: #{response_code}")
          end

          response_body
        end

      end

  end

end
