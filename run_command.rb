#!/usr/bin/env ruby

require 'pty'
require 'expect'
require 'highline/import'

$expect_verbose=true
switch = ARGV[0]
user = ask("Enter username: ") { |x| x.echo = true }
password = ask("Enter password: ") { |x| x.echo = "*" }
enable_password = ask("Enter enable password: ") { |x| x.echo = "*" }
command = ask("Enter command: ") { |x| x.echo = true }

begin
  PTY.spawn("ssh", switch) do |ssh_out, ssh_in, pid|
    ssh_out.expect(/user name:/i) do
      ssh_in.print "#{user}\n"
    end
    ssh_out.expect(/password:/i) do
      ssh_in.printf "#{password}\n"
    end
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
    end
    ssh_out.each do | line |
      puts line
      ssh_out.expect(/(more: <space>|^[a-zA-Z0-9-]+#)/i) do |r,match|
        if match =~ /more: <space>/i
          ssh_in.printf " "
        else
          ssh_in.printf("exit\n")
        end
      end
    end
  end
rescue Errno::EIO
  nil
end
