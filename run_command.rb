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
    PTY.spawn('ssh', device) do |ssh_out, ssh_in, _pid|

      puts 'Logging in...'

      ssh_out.expect(/user name:/i) do
        ssh_in.print "#{options[:user]}\n"
      end

      ssh_out.expect(/password:/i) do
        ssh_in.printf "#{password}\n"
      end

      puts 'Gaining enable mode...'

      ssh_out.expect(/^[a-zA-Z0-9-]+>/) do
        ssh_in.printf "enable\n"
        nil
      end

      ssh_out.expect(/password:/i) do
        ssh_in.printf "#{enable_password}\n"
        nil
      end

      ssh_out.expect(/^[a-zA-Z0-9-]+#/) do
        ssh_in.printf "#{command}\n"
        nil
      end

      ssh_out.each do |line|
        puts line
        ssh_out.expect(/(more: <space>|^[a-zA-Z0-9-]+#)/i) do |_r, match|
          ssh_in.printf ' ' if match =~ /more: <space>/i
        end
        ssh_in.printf("exit\n")
      end
    end
  rescue Errno::EIO
    nil
  end
end
