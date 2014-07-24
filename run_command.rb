#!/usr/bin/env ruby

require 'optparse'
require 'pty'
require 'expect'
require 'highline/import'

options = {}
option_parser = OptionParser.new do |opts|
  opts.on('-u USER') do |user|
    options[:user] = user
  end
  opts.on('-d DEVICES', '--devices') do |devices|
    options[:devices] = devices.split(',')
  end
end

option_parser.parse!
puts options.inspect

$expect_verbose = true

options[:user] = ask('Enter username: ') { |x| x.echo = true } if options[:user].nil?

password = ask('Enter password: ') { |x| x.echo = '*' }
enable_password = ask('Enter enable password: ') { |x| x.echo = '*' }
command = ask('Enter command: ') { |x| x.echo = true }

options[:devices].each do |device|
  begin
    PTY.spawn('ssh', device) do |r, w, _pid|

      puts 'Logging in...'

      r.expect(/user name:/i) do
        w.print "#{options[:user]}\n"
      end

      r.expect(/password:/i) do
        w.printf "#{password}\n"
      end

      puts 'Gaining enable mode...'

      r.expect(/^[a-zA-Z0-9-]+>/) do
        w.printf "enable\n"
        nil
      end

      r.expect(/password:/i) do
        w.printf "#{enable_password}\n"
        nil
      end

      r.expect(/^[a-zA-Z0-9-]+#/) do
        w.printf "#{command}\n"
        nil
      end

      r.each do |line|
        puts line
        r.expect(/(more: <space>|^[a-zA-Z0-9-]+#)/i) do |_r, match|
          w.printf ' ' if match =~ /more: <space>/i
        end
        w.printf("exit\n")
      end
    end
  rescue Errno::EIO
    nil
  end
end
