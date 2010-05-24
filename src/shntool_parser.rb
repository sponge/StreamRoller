#!/usr/bin/env ruby

require 'stringio'

def shntool_parse(s)
  sio = StringIO.new(s)
  params = {}
  (1..5).each do |x|
    cur = sio.readline()
    next if cur.index(":").nil?
    cur.chomp!
    a = cur.partition(":")
    params[a[0]] = a[2].lstrip
  end
  
  return params
end
