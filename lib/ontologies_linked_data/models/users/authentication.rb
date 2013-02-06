require 'gdbm'
require 'bcrypt'
require 'digest'
require 'openssl'
require 'base64'

module LinkedData
  module Models
    module Users
      module Authentication

        def valid_legacy_password?(pass, hash)
          return false if pass.nil? || hash.nil?

          # Work with bytes (8-bit signed integers to match Java)
          pass = pass.unpack('c*')

          # Decoding the hash using base64 and unpacking the bytes to 8-bit signed integers to match Java
          old_pass = Base64.decode64(hash).unpack('c*')

          # salt is the first 16 bytes of the old decoded hash
          salt = old_pass[0..15]

          sha256 = OpenSSL::Digest::SHA256.new
          sha256.update(salt.pack('c*'))
          sha256.update(pass.pack('c*'))
          digest = sha256.digest

          # 100000 iterations where we keep digesting the encrypted (follows Java default)
          iterations = 100000

          # Java method removes one iteration, not sure why
          (iterations - 1).times do
            sha256.reset
            digest = sha256.digest(digest)
          end

          # Combine two arrays with the undigested salt plus the digested salt+password
          encrypted_pass = (salt + digest.unpack('c*'))
          old_pass == encrypted_pass
        end

      end
    end
  end
end
