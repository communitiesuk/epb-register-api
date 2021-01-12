class TogglesStub
  def self.enable(features)
    WebMock.enable!
    WebMock.reset!

    WebMock.stub_request(:post, "#{ENV['EPB_UNLEASH_URI']}/client/register")
           .to_return(status: 200, body: "", headers: {})

    WebMock.stub_request(:get, "#{ENV['EPB_UNLEASH_URI']}/client/features")
           .to_return(status: 200, body: JSON.generate({
             version: 1,
             features: features.enum_for(:each_with_index).map do |feature|
                         {
                           name: feature[0],
                           description: "Test feature #{feature[0]}",
                           enabled: feature[1],
                           strategies: [{ name: "default" }],
                           variants: nil,
                           createdAt: "2019-11-14T14:24:44.277Z",
                         }
                       end,
           }))
  end

  def self.disable
    WebMock.disable!
  end
end
