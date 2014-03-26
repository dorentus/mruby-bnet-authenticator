assert('Bnet::Authenticator#intialize') do
  authenticator = Bnet::Authenticator.new 'CN-1402-1943-1283', '4202aa2182640745d8a807e0fe7e34b30c1edb23'
  assert_equal '4CKBN08QEB', authenticator.restorecode
  assert_equal :CN, authenticator.region
  assert_equal ['61459300', 1347279360], authenticator.get_token(1347279358)
  assert_equal ['75939986', 1347279390], authenticator.get_token(1347279360)
end

begin
  authenticator_new = Bnet::Authenticator.request_authenticator :US
rescue Bnet::RequestFailedError => e
  authenticator_new = nil
  puts e
end

begin
  authenticator_res = Bnet::Authenticator.restore_authenticator 'CN-1402-1943-1283', '4CKBN08QEB'
rescue Bnet::RequestFailedError => e
  authenticator_res = nil
  puts e
end

assert('Bnet::Authenticator#request_authenticator') do
  skip if authenticator_new.nil?
  assert_equal :US, authenticator_new.region
end

assert('Bnet::Authenticator#restore_authenticator') do
  skip if authenticator_res.nil?
  assert_equal '4202aa2182640745d8a807e0fe7e34b30c1edb23', authenticator_res.secret
  assert_equal :CN, authenticator_res.region
  assert_equal ['61459300', 1347279360], authenticator_res.get_token(1347279358)
  assert_equal ['75939986', 1347279390], authenticator_res.get_token(1347279360)
end
