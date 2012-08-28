module Silverpopper::Ftp
  def upload_file(file, remotefile)
    Net::SFTP.start(ftp_host, user_name, :keys => [], :password => password) do |sftp|
      sftp.upload!(file, "/upload/#{remotefile}")
    end
  end
end