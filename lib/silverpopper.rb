# Silverpopper; the ruby silverpop api wrapper!
module Silverpopper; end;

# dependencies
require 'builder'
require 'httparty'
require 'rexml/document'
require 'active_support/core_ext'
require 'net/sftp'
require 'csv'
require 'tempfile'

# core files
require 'common.rb'
require 'transact_api.rb'
require 'xml_api.rb'
require 'ftp_api.rb'
require 'client.rb'
