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
  when '/status_app', '/app_status'
    status_message = ec2.instance_status(:app)
    message.channel.post(status_message)
  when '/status_app2', '/app_status2'
    status_message = ec2.instance_status(:app2)
    message.channel.post(status_message)
  when '/status_bench', '/bench_status'
    status_message = ec2.instance_status(:bench)
    message.channel.post(status_message)
  when '/start_app', '/app_start'
    log = ec2.instance_start(:app)
    message.channel.post(log)
  when '/start_app2', '/app_start2'
    log = ec2.instance_start(:app2)
    message.channel.post(log)
  when '/start_bench', '/bench_start'
    log = ec2.instance_start(:bench)
    message.channel.post(log)
  when '/stop_app', 'app_stop'
    log = ec2.instance_stop(:app)
    message.channel.post(log)
  when '/stop_app2', 'app_stop2'
    log = ec2.instance_stop(:app2)
    message.channel.post(log)
  when '/stop_bench', '/bench_stop'
    log = ec2.instance_stop(:bench)
    message.channel.post(log)
  when '/ip_app', '/app_ip'
    res = ec2.instance_public_ip(:app)
    message.channel.post(res)
  when '/ip_app2', '/app_ip2'
    res = ec2.instance_public_ip(:app2)
    message.channel.post(res)
  when '/ip_bench', '/bench_ip'
    res = ec2.instance_public_ip(:bench)
    message.channel.post(res)
  end
end

client.run(ENV['BOT_TOKEN'])
