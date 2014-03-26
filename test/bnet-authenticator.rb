assert('Bnet::Authenticator#intialize') do
  authenticator = Bnet::Authenticator.new 'CN-1402-1943-1283', '4202aa2182640745d8a807e0fe7e34b30c1edb23'
  assert_equal '4CKBN08QEB', authenticator.restorecode
  assert_equal :CN, authenticator.region
  assert_equal ['61459300', 1347279360], authenticator.get_token(1347279358)
  assert_equal ['75939986', 1347279390], authenticator.get_token(1347279360)
end

assert('Bnet::Authenticator#request_authenticator') do
  authenticator = Bnet::Authenticator.request_authenticator :US
  assert_equal :US, authenticator.region
end

assert('Bnet::Authenticator#restore_authenticator') do
  authenticator = Bnet::Authenticator.restore_authenticator 'CN-1402-1943-1283', '4CKBN08QEB'
  assert_equal '4202aa2182640745d8a807e0fe7e34b30c1edb23', authenticator.secret
  assert_equal :CN, authenticator.region
  assert_equal ['61459300', 1347279360], authenticator.get_token(1347279358)
  assert_equal ['75939986', 1347279390], authenticator.get_token(1347279360)
end
