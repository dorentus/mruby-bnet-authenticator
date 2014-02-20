require 'test/unit'
require 'battlenet_authenticator'

class BattlenetAuthenticatorTest < Test::Unit::TestCase
  DEFAULT_SERIAL = 'CN-1402-1943-1283'
  DEFAULT_SECRET = '4202aa2182640745d8a807e0fe7e34b30c1edb23'
  DEFAULT_RSCODE = '4CKBN08QEB'
  DEFAULT_REGION = :CN

  def test_load
    authenticator = BattlenetAuthenticator.new(:serial => DEFAULT_SERIAL, :secret => DEFAULT_SECRET)
    is_default_authenticator authenticator
  end

  def test_request_new_serial
    authenticator = BattlenetAuthenticator.new(:region => :US)
    assert_equal :US, authenticator.region
    assert_not_nil authenticator.serial
    assert_not_nil authenticator.secret
    assert_not_nil authenticator.restorecode
  end

  def test_restore
    authenticator = BattlenetAuthenticator.new(:serial => DEFAULT_SERIAL, :restorecode => DEFAULT_RSCODE)
    is_default_authenticator authenticator
  end

  def test_request_server_time
    assert_nothing_raised do
      BattlenetAuthenticator.request_server_time :EU
    end
  end

  private

  def is_default_authenticator(authenticator)
    assert_equal DEFAULT_REGION, authenticator.region
    assert_equal DEFAULT_SERIAL, authenticator.serial
    assert_equal DEFAULT_SECRET, authenticator.secret
    assert_equal DEFAULT_RSCODE, authenticator.restorecode
    assert_equal ['61459300', 1347279360], authenticator.caculate_token(1347279358)
    assert_equal ['61459300', 1347279360], authenticator.caculate_token(1347279359)
    assert_equal ['23423634', 1347279390], authenticator.caculate_token(1347279360)
  end
end