# -*- coding: utf-8 -*-
require 'drb/drb'

DripUri = 'druby://localhost:12345'
MyDrip = DRbObject.new_with_uri(DripUri)

def MyDrip.invoke
    exec_dir = File.expand_path(File.dirname(__FILE__))
    service_file = File.join(exec_dir, 'my_drip_service.rb')
    pid = Process.spawn("ruby #{service_file} #{DripUri}")

  Thread.new do
    Process.waitpid(pid)
  end
end

def MyDrip.inspect
  "<MyDrip: #{@uri}>"
end

class DripCursor
  def initialize(drip, bufsiz=10, at_least=10)
    @drip = drip
    @cur = nil
    @bufsiz = bufsiz
    @at_least = at_least
  end
  attr_accessor :cur

  def now
    @cur ? @drip.key_to_time(@cur) : nil
  end

  def seek_at(time)
    @cur = @drip.time_to_key(time)
  end

  def past_each(tag=nil)
    while kv = @drip.older(@cur, tag)
      @cur, value = kv
      yield(value)
    end
  end
end

