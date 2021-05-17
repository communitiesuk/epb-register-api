describe "OpenDataExportOptOuts" do
  subject(:task) { get_task("open_data_export_opt_out") }
  context "We invoke the Open Data Communities export Rake directly" do
    before do
      EnvironmentStub.all
      HttpStub.s3_put_csv(
        "open_data_export_opt_outs_#{DateTime.now.strftime('%F')}.csv",
      )
    end

    it "initialises the storage gateway with task parameters" do
      task.invoke
      expect(WebMock).to have_requested(
        :put,
        "#{HttpStub::S3_BUCKET_URI}open_data_export_opt_outs_#{DateTime.now.strftime('%F')}.csv",
      ).with(headers: { "Host" => "s3.eu-west-2.amazonaws.com" })
    end
  end

  context "when bucket_name or instance_name is not provided to the export task" do
    before { allow(ENV).to receive(:[]) }

    it "fails to run with the relevant message" do
      expect { task.invoke }.to output(/A required argument is missing/)
        .to_stderr
    end
  end
end
