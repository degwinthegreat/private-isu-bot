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
    status_message = ec2.instance_status(:app)
    message.channel.post(status_message)
  when '/status_bench'
    status_message = ec2.instance_status(:bench)
    message.channel.post(status_message)
  when '/start_app'
    log = ec2.instance_start(:app)
    message.channel.post(log)
  when '/start_bench'
    log = ec2.instance_start(:bench)
    message.channel.post(log)
  when '/stop_app'
    log = ec2.instance_stop(:app)
    message.channel.post(log)
  when '/stop_bench'
    log = ec2.instance_stop(:bench)
    message.channel.post(log)
  when '/ip_app'
    res = ec2.public_ip_address(:app)
    message.channel.post(res)
  when '/ip_bench'
    res = ec2.public_ip_address(:bench)
    message.channel.post(res)
  end
end

client.run(ENV['BOT_TOKEN'])
