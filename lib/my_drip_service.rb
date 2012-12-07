# -*- coding: utf-8 -*-
require 'drb/drb'
require 'drip'
require 'fileutils'

uri = ARGV[0]
ro = DRbObject.new_with_uri(uri)

begin
  ro.older(nil) #ping
  exit
rescue
end

dir = File.expand_path('~/.drip')
FileUtils.mkdir_p(dir)
FileUtils.cd(dir)

drip = Drip.new('drip')
def drip.quit
  Thread.new do
    synchronize do |key|
      exit(0)
    end
  end
end

DRb.start_service(uri, drip)
File.open('pid', 'w') {|fp| fp.puts($$)}

DRb.thread.join
