# frozen_string_literal: true

# 每個 SOAP 操作的 spec 都要一組設定好的 Cetustek.config 加上被攔下來的 Savon
# client — 測試若打到真的沙盒就不叫單元測試了。
RSpec.shared_context 'a stubbed SOAP client' do
  let(:client) { instance_double(Savon::Client) }
  let(:response) { double('response') }

  before do
    Cetustek.configure do |c|
      c.environment = :sandbox
      c.site_id = 'SITE'
      c.username = 'USER'
      c.password = 'PASS'
    end
    allow(Savon).to receive(:client).and_return(client)
    allow(client).to receive(:call).and_return(response)
  end

  # 回一個只帶 result code 的 body，開立/作廢類操作用得到。
  def stub_return(key, value)
    allow(client).to receive(:call).and_return(double('response', body: { key => { return: value } }))
  end
end
