module Bnet

  module Util

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
            memo << Digest::SHA1.hexdigest(rand().to_s)
          end[0, length]
        end

        def decrypt_response(text, key)
          text.bytes.each_with_index.reduce('') do |memo, pair|
            memo + (pair[0] ^ key.bytes[pair[1]]).chr
          end
        end

        def rsa_encrypt_bin(bin)
          result_hex = mod_exp bin.unpack('H*')[0], Bnet::RSA_KEY_HEX, Bnet::RSA_MOD_HEX
          [result_hex].pack('H*')
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
            raise Bnet::RequestFailedError.new("Error requesting #{label}: #{response_code}")
          end

          response_body
        end

      end

  end

end
