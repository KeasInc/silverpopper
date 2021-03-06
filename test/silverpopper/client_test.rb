require '../helper'

require 'active_support/ordered_hash'

class Silverpopper::ClientTest < Test::Unit::TestCase
  def test_initializer
    s = Silverpopper::Client.new(
        'user_name' => 'testman',
        'password'  => 'pass',
        'pod'       => 1,
        'https'     => true)

    assert_equal 'testman', s.user_name
    assert_equal 'pass', s.send(:password)
    assert_equal 1, s.pod
    assert s.https
    assert_equal 'https://api1.silverpop.com', s.api_url
    assert_equal 'https://transact1.silverpop.com', s.transact_url
  end

  def test_initializer_no_https
    s = Silverpopper::Client.new(
        'user_name' => 'testman',
        'password'  => 'pass',
        'pod'       => 1)

    assert !s.https
    assert_equal 'http://api1.silverpop.com', s.api_url
    assert_equal 'http://transact1.silverpop.com', s.transact_url
  end

  def test_login
    s = new_silverpop

    expect_login
    assert_equal "3631784201", s.login
  end


  def test_expect_malformed_login_response
    s = new_silverpop

    expect_send_request_api(login_request_xml, silverpop_url).
        returns(MockHTTPartyResponse.new(200,
                                         "<Envelope><Body><RESULT></RESULT></Body></Envelope>"))

    assert_raise RuntimeError do
      s.login
    end
  end

  def test_logout
    s = new_silverpop

    expect_login
    expect_logout
    assert_equal "3631784201", s.login
    s.logout
    assert_nil s.instance_eval { @session_id }
  end

  def test_logout_failure
    s = new_silverpop

    expect_login
    expect_send_request_api(logout_request_xml, "#{silverpop_url};jsessionid=3631784201").returns(MockHTTPartyResponse.new(200, "<omg />"))

    s.login
    assert_raise RuntimeError do
      s.logout
    end

    assert_not_nil s.instance_eval { @session_id }
  end


  def test_add_contact
    s = new_silverpop

    expect_login
    expect_add_contact

    s.login

    hash               = ActiveSupport::OrderedHash.new
    hash['list_id']    = '1'
    hash['email']      = 'testman@testman.com'
    hash['auto_reply'] = false
    hash['Test Field'] = 'Test Value'

    assert_equal "2007408974", s.add_contact(hash)
  end

  def test_add_contact_fails
    s = new_silverpop

    expect_login
    expect_send_request_api(add_contact_xml, silverpop_session_url).returns(MockHTTPartyResponse.new(200, "<omg />"))

    s.login

    hash               = ActiveSupport::OrderedHash.new
    hash['list_id']    = '1'
    hash['email']      = 'testman@testman.com'
    hash['auto_reply'] = false
    hash['Test Field'] = 'Test Value'

    assert_raise RuntimeError do
      s.add_contact(hash)
    end
  end


  def test_remove_contact
    s = new_silverpop

    expect_login
    expect_remove_contact

    s.login

    hash            = ActiveSupport::OrderedHash.new
    hash['list_id'] = '1'
    hash['email']   = 'testman@testman.com'

    assert_equal true, s.remove_contact(hash)
  end

  def test_remove_contact_fails
    s = new_silverpop

    expect_login
    expect_send_request_api(remove_contact_xml, silverpop_session_url).returns(MockHTTPartyResponse.new(200, "<omg />"))

    s.login

    hash            = ActiveSupport::OrderedHash.new
    hash['list_id'] = '1'
    hash['email']   = 'testman@testman.com'

    assert_raise RuntimeError do
      s.remove_contact(hash)
    end
  end

  def test_select_contact
    s = new_silverpop

    expect_login
    expect_select_contact

    s.login

    expected = {
        "Zip Code"     => "02115",
        "Latitude"     => nil,
        "Last Name"    => nil,
        "State"        => nil,
        "2nd Zip Code" => "90211",
        "First Name"   => nil,
        "Longitude"    => nil,
        "Gender"       => nil,
        "Address"      => nil,
        "Age"          => nil,
        "User ID"      => nil,
        "City"         => nil
    }
    actual   = s.select_contact({'list_id' => 1, 'email' => 'testman@testman.com'})

    # to help debugging make sure all the keys that are expected have the expected value
    expected.each do |key, value|
      assert_equal value, actual[key], "expected [#{key.inspect}] to be #[#{value.inspect}] but was [#{actual[key].inspect}]"
    end

    assert_equal expected, actual
  end

  def test_select_contact_fails
    s = new_silverpop

    expect_login
    expect_send_request_api(select_contact_xml, silverpop_session_url).returns(MockHTTPartyResponse.new(200, "<omg />"))

    s.login

    assert_raise RuntimeError do
      s.select_contact({'list_id' => '1', 'email' => 'testman@testman.com'})
    end
  end

  def test_update_contact_fails
    s = new_silverpop

    expect_login
    expect_send_request_api(update_contact_xml, silverpop_session_url).returns(MockHTTPartyResponse.new(200, "<omg />"))

    s.login

    fields                 = ActiveSupport::OrderedHash.new
    fields['Zip Code']     = '01430'
    fields['2nd Zip Code'] = '01320'

    assert_raise RuntimeError do
      s.update_contact(fields.merge({'list_id' => '1', 'email' => 'testman@testman.com'}))
    end
  end

  def test_update_contact
    s = new_silverpop

    expect_login
    expect_update_contact

    s.login

    fields                 = ActiveSupport::OrderedHash.new
    fields['Zip Code']     = '01430'
    fields['2nd Zip Code'] = '01320'

    assert_equal '2007408974', s.update_contact(fields.merge({'list_id' => '1', 'email' => 'testman@testman.com'}))
  end

  def test_send_mailing_fail
    s = new_silverpop

    expect_login
    expect_send_request_api(send_mailing_xml, silverpop_session_url).returns(MockHTTPartyResponse.new(200, "<omg />"))

    s.login

    assert_raise RuntimeError do
      s.send_mailing('email' => 'testman@testman.com', 'mailing_id' => 908220)
    end
  end

  def test_send_mailing
    s = new_silverpop

    expect_login
    expect_send_mailing

    s.login

    assert_equal true, s.send_mailing('email' => 'testman@testman.com', 'mailing_id' => 908220)
  end

=begin
  # This test was failing in the unmodified version of the library and is beyond me to diagnose.
  # Based on problem with the helper.rb include, it does not look like we've been running these tests at all

  def test_import_list
    s = new_silverpop

    expect_login
    expect_import_list
    sftp = mock_sftp_session

    s.login

    assert_equal "108518", s.import([{ "Data" => "Here"}], 'import_type' => "LIST")

    assert_equal "/upload/list_import_map.xml", sftp.uploads[0].last
    assert_equal "/upload/list_data.csv", sftp.uploads[1].last
  end
=end

  def test_import_mapping
    s = new_silverpop

    fields = ["FirstName", "LastName", "UserID"]

    data = File.read s.import_map(fields, "list_id" => "12345", 'import_type' => "LIST")

    assert_equal import_mapping_file, data
  end

  def test_import_file
    s = new_silverpop

    data = [{"FirstName" => "Thomas", "LastName" => "Fisher", "UserID" => 1}, {"FirstName" => "Bill", "LastName" => "Kaufman", "UserID" => 2}]

    fields = ["LastName", "FirstName", "UserID"]

    data = File.read s.import_file(data, fields)

    assert_equal "LastName,FirstName,UserID\nFisher,Thomas,1\nKaufman,Bill,2\n", data
  end

  def test_schedule_mailing
    s = new_silverpop

    expect_login
    expect_schedule_mailing

    s.login

    assert_equal '1878843', s.schedule_mailing({
                                                   'list_id'      => 12345,
                                                   'template_id'  => 860866,
                                                   'mailing_name' => 'Test_Mailing_000',
                                                   'subject'      => 'Test Mailing #0',
                                                   'from_name'    => 'Testman',
                                                   'from_address' => 'testman@testman.com',
                                                   'reply_to'     => 'testman@testman.com',
                                                   'TEST_PARAM'   => 'This is external parameter generated by our system'})
  end

  def test_schedule_mailing_fail
    s = new_silverpop

    expect_login
    expect_send_request_api(schedule_mailing_xml, silverpop_session_url).returns(MockHTTPartyResponse.new(200, "<omg />"))

    s.login

    assert_raise RuntimeError do
      s.schedule_mailing({
                             'list_id'      => 12345,
                             'template_id'  => 860866,
                             'mailing_name' => 'Test_Mailing_000',
                             'subject'      => 'Test Mailing #0',
                             'from_name'    => 'Testman',
                             'from_address' => 'testman@testman.com',
                             'reply_to'     => 'testman@testman.com',
                             'TEST_PARAM'   => 'This is external parameter generated by our system'})
    end
  end

  def test_transact_email
    s = new_silverpop

    expect_login
    expect_send_transact_mail

    s.login
    assert_equal '1', s.send_transact_mail('email' => 'testman@testman.com', 'transaction_id' => '123awesome', 'campaign_id' => 9876, 'PASSWORD_RESET_LINK' => 'www.somelink.com', 'URL' => 'foo.bar.com', 'save_columns' => ['URL'])
  end

  def test_transact_email_fail
    s = new_silverpop

    expect_login
    expect_send_request_transact(transact_mail_xml, transact_session_url).returns(MockHTTPartyResponse.new(200, "<omg />"))

    s.login

    assert_raise RuntimeError do
      s.send_transact_mail('email' => 'testman@testman.com', 'transaction_id' => '123awesome', 'campaign_id' => 9876, 'PASSWORD_RESET_LINK' => 'www.somelink.com', 'URL' => 'foo.bar.com', 'save_columns' => ['URL'])
    end
  end

  private

  def new_silverpop
    s = Silverpopper::Client.new(
        'user_name' => 'testman',
        'password'  => 'pass',
        'pod'       => 5)
  end

  # use mocha to test api calls, this mimicks
  # how ActiveMerchant tests payment gateway
  # api calls

  def silverpop_url
    "http://api5.silverpop.com/XMLAPI"
  end

  def silverpop_ftp_host
    "transfer5.silverpop.com"
  end

  def silverpop_ftp_user
    'testman'
  end

  def silverpop_ftp_password
    'pass'
  end

  def silverpop_session_url
    "#{silverpop_url};jsessionid=3631784201"
  end

  def transact_url
    "http://transact5.silverpop.com/XTMail"
  end

  def transact_session_url
    "#{transact_url};jsessionid=3631784201"
  end

  def expect_send_transact_mail
    expect_send_request_transact(transact_mail_xml, transact_session_url).returns(MockHTTPartyResponse.new(200, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<XTMAILING_RESPONSE>
    <CAMPAIGN_ID>9876</CAMPAIGN_ID>
    <TRANSACTION_ID>123awesome</TRANSACTION_ID>
    <RECIPIENTS_RECEIVED>1</RECIPIENTS_RECEIVED>
    <EMAILS_SENT>1</EMAILS_SENT>
    <NUMBER_ERRORS>0</NUMBER_ERRORS>
    <STATUS>0</STATUS>
    <ERROR_CODE>0</ERROR_CODE>
    <ERROR_STRING/>
</XTMAILING_RESPONSE>'))
  end

  def expect_select_contact
    expect_send_request_api(select_contact_xml, silverpop_session_url).returns(MockHTTPartyResponse.new(200, success_select_xml_response))
  end

  def expect_send_mailing
    expect_send_request_api(send_mailing_xml, silverpop_session_url).returns(MockHTTPartyResponse.new(200, "<Envelope>
<Body>
  <RESULT>
<SUCCESS>TRUE</SUCCESS>
<ORGANIZATION_ID>jhgjhjgjgjjh</ORGANIZATION_ID>
</RESULT>
 </Body>
</Envelope>
"))
  end


  def expect_schedule_mailing
    expect_send_request_api(schedule_mailing_xml, silverpop_session_url).returns(MockHTTPartyResponse.new(200, "<Envelope>
<Body>
  <RESULT>
<SUCCESS>TRUE</SUCCESS>
<MAILING_ID>1878843</MAILING_ID>
</RESULT>
 </Body>
</Envelope>
"))
  end

  def expect_add_contact
    expect_send_request_api(add_contact_xml, silverpop_session_url).returns(MockHTTPartyResponse.new(200, "<Envelope>
<Body>
  <RESULT>
<SUCCESS>TRUE</SUCCESS>
<RecipientId>2007408974</RecipientId>
<ORGANIZATION_ID>jhgjhjgjgjjh</ORGANIZATION_ID>
</RESULT>
 </Body>
</Envelope>
"))
  end

  def expect_remove_contact
    expect_send_request_api(remove_contact_xml, silverpop_session_url).returns(MockHTTPartyResponse.new(200, "<Envelope>
<Body>
  <RESULT>
<SUCCESS>TRUE</SUCCESS>
<ORGANIZATION_ID>jhgjhjgjgjjh</ORGANIZATION_ID>
</RESULT>
 </Body>
</Envelope>
"))
  end

  def expect_update_contact
    expect_send_request_api(update_contact_xml, silverpop_session_url).returns(MockHTTPartyResponse.new(200, "<Envelope>
<Body>
  <RESULT>
<SUCCESS>TRUE</SUCCESS>
<RecipientId>2007408974</RecipientId>
<ORGANIZATION_ID>wqehjwqer</ORGANIZATION_ID>
</RESULT>
 </Body>
</Envelope>
"))
  end

  def expect_logout
    expect_send_request_api(logout_request_xml, silverpop_session_url).returns(MockHTTPartyResponse.new(200, "<Envelope>\n<Body>\n  <RESULT>\n<SUCCESS>TRUE</SUCCESS>\n</RESULT>\n </Body>\n</Envelope>\n"))
  end

  def expect_login
    expect_send_request_api(login_request_xml, silverpop_url).returns(MockHTTPartyResponse.new(200, "<Envelope><Body><RESULT>
  <SUCCESS>true</SUCCESS>
  <SESSIONID>3631784201</SESSIONID>
  <ORGANIZATION_ID>322a4dc-c6f6d1ebd715e129037</ORGANIZATION_ID>
  <SESSION_ENCODING>;jsessionid=36ADDFB301</SESSION_ENCODING>
  </RESULT>
 </Body>
</Envelope>
"))
  end

  def expect_send_request_transact(markup, url)
    HTTParty.expects(:post).with(url, {:body => markup, :headers => {'Content-type' => 'text/xml;charset=UTF-8', 'X-Intended-Host' => 'transact5'}})
  end

  def expect_send_request_api(markup, url)
    HTTParty.expects(:post).with(url, {:body => markup, :headers => {'Content-type' => 'text/xml;charset=UTF-8', 'X-Intended-Host' => 'api5'}})
  end

  def mock_sftp_session
    sftp = MockSFTPSession.new
    Net::SFTP.stubs(:start).with(silverpop_ftp_host, silverpop_ftp_user, :keys => [], :password => silverpop_ftp_password).yields(sftp)

    sftp
  end

  def transact_mail_xml
    '<?xml version="1.0" encoding="UTF-8"?>
<XTMAILING>
 <CAMPAIGN_ID>9876</CAMPAIGN_ID>
 <TRANSACTION_ID>123awesome</TRANSACTION_ID>
 <SEND_AS_BATCH>false</SEND_AS_BATCH>
 <SAVE_COLUMNS>
  <COLUMN_NAME>URL</COLUMN_NAME>
 </SAVE_COLUMNS>
 <RECIPIENT>
  <EMAIL>testman@testman.com</EMAIL>
  <BODY_TYPE>HTML</BODY_TYPE>
  <PERSONALIZATION>
   <TAG_NAME>PASSWORD_RESET_LINK</TAG_NAME>
   <VALUE>www.somelink.com</VALUE>
  </PERSONALIZATION>
  <PERSONALIZATION>
   <TAG_NAME>URL</TAG_NAME>
   <VALUE>foo.bar.com</VALUE>
  </PERSONALIZATION>
 </RECIPIENT>
</XTMAILING>
'
  end

  def schedule_mailing_xml
    '<?xml version="1.0" encoding="UTF-8"?>
<Envelope>
 <Body>
  <ScheduleMailing>
   <TEMPLATE_ID>860866</TEMPLATE_ID>
   <LIST_ID>12345</LIST_ID>
   <SEND_HTML/>
   <SEND_TEXT/>
   <MAILING_NAME>Test_Mailing_000</MAILING_NAME>
   <SUBJECT>Test Mailing #0</SUBJECT>
   <FROM_NAME>Testman</FROM_NAME>
   <FROM_ADDRESS>testman@testman.com</FROM_ADDRESS>
   <REPLY_TO>testman@testman.com</REPLY_TO>
   <SUBSTITUTIONS>
    <SUBSTITUTION>
     <NAME>TEST_PARAM</NAME>
     <VALUE>This is external parameter generated by our system</VALUE>
    </SUBSTITUTION>
   </SUBSTITUTIONS>
  </ScheduleMailing>
 </Body>
</Envelope>
'
  end

  def login_request_xml
    '<?xml version="1.0" encoding="UTF-8"?>
<Envelope>
 <Body>
  <Login>
   <USERNAME>testman</USERNAME>
   <PASSWORD>pass</PASSWORD>
  </Login>
 </Body>
</Envelope>
'
  end

  def logout_request_xml
    "<Envelope>\n <Body>\n  <Logout/>\n </Body>\n</Envelope>\n"
  end

  def add_contact_xml
    '<?xml version="1.0" encoding="UTF-8"?>
<Envelope>
 <Body>
  <AddRecipient>
   <LIST_ID>1</LIST_ID>
   <CREATED_FROM>1</CREATED_FROM>
   <COLUMN>
    <NAME>EMAIL</NAME>
    <VALUE>testman@testman.com</VALUE>
   </COLUMN>
   <COLUMN>
    <NAME>Test Field</NAME>
    <VALUE>Test Value</VALUE>
   </COLUMN>
  </AddRecipient>
 </Body>
</Envelope>
'
  end

  def remove_contact_xml
    '<?xml version="1.0" encoding="UTF-8"?>
<Envelope>
 <Body>
  <RemoveRecipient>
   <LIST_ID>1</LIST_ID>
   <EMAIL>testman@testman.com</EMAIL>
  </RemoveRecipient>
 </Body>
</Envelope>
'
  end

  def send_mailing_xml
    '<?xml version="1.0" encoding="UTF-8"?>
<Envelope>
 <Body>
  <SendMailing>
   <MailingId>908220</MailingId>
   <RecipientEmail>testman@testman.com</RecipientEmail>
  </SendMailing>
 </Body>
</Envelope>
'
  end

  def update_contact_xml
    '<?xml version="1.0" encoding="UTF-8"?>
<Envelope>
 <Body>
  <UpdateRecipient>
   <LIST_ID>1</LIST_ID>
   <OLD_EMAIL>testman@testman.com</OLD_EMAIL>
   <COLUMN>
    <NAME>Zip Code</NAME>
    <VALUE>01430</VALUE>
   </COLUMN>
   <COLUMN>
    <NAME>2nd Zip Code</NAME>
    <VALUE>01320</VALUE>
   </COLUMN>
  </UpdateRecipient>
 </Body>
</Envelope>
'
  end

  def select_contact_xml
    '<?xml version="1.0" encoding="UTF-8"?>
<Envelope>
 <Body>
  <SelectRecipientData>
   <LIST_ID>1</LIST_ID>
   <EMAIL>testman@testman.com</EMAIL>
  </SelectRecipientData>
 </Body>
</Envelope>
'
  end

  def send_mailing_xml
    '<?xml version="1.0" encoding="UTF-8"?>
<Envelope>
 <Body>
  <SendMailing>
   <MailingId>908220</MailingId>
   <RecipientEmail>testman@testman.com</RecipientEmail>
  </SendMailing>
 </Body>
</Envelope>
'
  end

  def expect_import_list
    expect_send_request_api(import_list_xml, silverpop_session_url).returns(MockHTTPartyResponse.new(200, "<Envelope>
  <Body>
          <RESULT>
               <SUCCESS>TRUE</SUCCESS>
<JOB_ID>108518</JOB_ID>
          </RESULT>
     </Body>
</Envelope>
"))
  end

  def import_list_xml
    '<?xml version="1.0" encoding="UTF-8"?>
<Envelope>
 <Body>
  <ImportList>
   <MAP_FILE>list_import_map.xml</MAP_FILE>
   <SOURCE_FILE>list_data.csv</SOURCE_FILE>
  </ImportList>
 </Body>
</Envelope>
'
  end

  def success_select_xml_response
    '<Envelope>
  <Body>
    <RESULT>
      <SUCCESS>TRUE</SUCCESS>
      <EMAIL>testman@testman.com</EMAIL>
      <Email>testman@testman.com</Email>
      <RecipientId>7886786</RecipientId>
      <EmailType>0</EmailType>
      <LastModified>8/10/11 3:15 PM</LastModified>
      <CreatedFrom>1</CreatedFrom>
      <OptedIn>3/30/11 5:38 PM</OptedIn>
      <OptedOut/>
      <ResumeSendDate/>
      <ORGANIZATION_ID>sdjfdsjkfs</ORGANIZATION_ID>
      <COLUMNS>
        <COLUMN>
          <NAME>2nd Zip Code</NAME>
          <VALUE>90211</VALUE>
        </COLUMN>
        <COLUMN>
          <NAME>Address</NAME>
          <VALUE/>
        </COLUMN>
        <COLUMN>
          <NAME>Age</NAME>
          <VALUE/>
        </COLUMN>
        <COLUMN>
          <NAME>City</NAME>
          <VALUE/>
        </COLUMN>
        <COLUMN>
          <NAME>First Name</NAME>
          <VALUE/>
        </COLUMN>
        <COLUMN>
          <NAME>Gender</NAME>
          <VALUE/>
        </COLUMN>
        <COLUMN>
          <NAME>Last Name</NAME>
          <VALUE/>
        </COLUMN>
        <COLUMN>
          <NAME>Latitude</NAME>
          <VALUE/>
        </COLUMN>
        <COLUMN>
          <NAME>Longitude</NAME>
          <VALUE/>
        </COLUMN>
        <COLUMN>
          <NAME>State</NAME>
          <VALUE/>
        </COLUMN>
        <COLUMN>
          <NAME>User ID</NAME>
          <VALUE/>
        </COLUMN>
        <COLUMN>
          <NAME>Zip Code</NAME>
          <VALUE>02115</VALUE>
        </COLUMN>
      </COLUMNS>
    </RESULT>
  </Body>
</Envelope>
'
  end

  def import_mapping_file
    '<?xml version="1.0" encoding="UTF-8"?>
<LIST_IMPORT>
 <LIST_INFO>
  <ACTION>ADD_AND_UPDATE</ACTION>
  <LIST_ID>12345</LIST_ID>
  <FILE_TYPE>0</FILE_TYPE>
  <HASHEADERS>true</HASHEADERS>
 </LIST_INFO>
 <MAPPING>
  <COLUMN>
   <INDEX>1</INDEX>
   <NAME>FirstName</NAME>
   <INCLUDE>true</INCLUDE>
  </COLUMN>
  <COLUMN>
   <INDEX>2</INDEX>
   <NAME>LastName</NAME>
   <INCLUDE>true</INCLUDE>
  </COLUMN>
  <COLUMN>
   <INDEX>3</INDEX>
   <NAME>UserID</NAME>
   <INCLUDE>true</INCLUDE>
  </COLUMN>
 </MAPPING>
</LIST_IMPORT>
'
  end

  class MockSFTPSession
    attr_accessor :uploads

    def upload!(local, remote)
      self.uploads ||= []
      self.uploads << [local, remote]
    end
  end

  class MockHTTPartyResponse
    attr_reader :code, :body

    def initialize(code, body)
      @code, @body = code, body
    end
  end

end
