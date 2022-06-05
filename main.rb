# frozen_string_literal: true

require 'discorb'
require './ec2'

client = Discorb::Client.new

client.once :ready do
  puts "Logged in as #{client.user}"
end

client.on :message do |message|
  next if message.author.bot?

  ec2 = Ec2.new

  case message.content
  when '/hello'
    message.channel.post('Hello, Discord')
  when '/status_app'
    status_message = ec2.status_app
    message.channel.post(status_message)
  when '/status_bench'
    status_message = ec2.status_bench
    message.channel.post(status_message)
  when '/start_app'
    log = ec2.start_app
    message.channel.post(log)
  when '/start_bench'
    log = ec2.start_bench
    message.channel.post(log)
  when '/stop_app'
    log = ec2.stop_app
    message.channel.post(log)
  when '/stop_bench'
    log = ec2.stop_bench
    message.channel.post(log)
  end
end

client.run(ENV['BOT_TOKEN'])
