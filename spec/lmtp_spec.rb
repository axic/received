require 'spec_helper'
require 'logger'

describe Received::LMTP do
  before :each do
    @mock = mock 'conn'
    @mock.should_receive(:send_data).with("220 localhost LMTP server ready\r\n")
    @mock.stub!(:logger).and_return(Logger.new($stderr))
    @mock.logger.debug "*** Starting test ***"
    @proto = Received::LMTP.new(@mock)
  end

  it "does full receive flow" do
    @mock.should_receive(:send_data).with("250-localhost\r\n")
    @mock.should_receive(:send_data).with("250 OK\r\n").exactly(3).times
    @mock.should_receive(:send_data).with("354 Start mail input; end with <CRLF>.<CRLF>\r\n")
    @mock.should_receive(:send_data).with("250 OK\r\n")
    @mock.should_receive(:send_data).with("452 localhost closing connection\r\n")
    body = "Subject: spec\r\nspec\r\n"
    @mock.should_receive(:mail_received).with({
      :from => 'spec1@example.com',
      :rcpt => ['spec2@example.com', 'spec3@example.com'],
      :body => body
    })
    @mock.should_receive(:close_connection).with(true)

    ["LHLO", "MAIL FROM:<spec1@example.com>", "RCPT TO:<spec2@example.com>",
      "RCPT TO:<spec3@example.com>", "DATA", "#{body}.", "QUIT"].each do |line|
      @mock.logger.debug "client: #{line}"
      @proto.on_data(line + "\r\n")
    end

  end

  it "parses multiline" do
    @mock.should_receive(:send_data).with("250-localhost\r\n")
    @mock.should_receive(:send_data).with("250 OK\r\n")
    @proto.on_data("LHLO\r\nMAIL FROM:<spec@example.com>\r\n")
  end

  it "buffers commands up to CR/LF" do
    @mock.should_receive(:send_data).with("250-localhost\r\n")
    @mock.should_receive(:send_data).with("250 OK\r\n")
    @proto.on_data("LHLO\r\nMAIL FROM")
    @proto.on_data(":<spec@example.com>\r\n")
  end
end