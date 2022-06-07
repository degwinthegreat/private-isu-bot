# frozen_string_literal: true

require 'aws-sdk-ec2'

class Ec2
  def initialize
    @ec2 = Aws::EC2::Client.new(
      access_key_id: ENV['ACCESS_KEY'],
      secret_access_key: ENV['SECRET_KEY'],
      region: ENV['REGION']
    )
  end

  attr_reader :ec2

  def instance_status(type)
    status = []
    instance_id = type == :app ? app_instance_id : bench_instance_id
    res = ec2.describe_instance_status(instance_ids: [instance_id])
    if res.instance_statuses[0]
      if res.instance_statuses[0][:instance_status].empty?
        status << 'stopped'
        message = "#{type} instance has stopped"
      else
        res.instance_statuses.map do |s|
          sys_status = s.respond_to?(:system_status) ? s.system_status.details[0].status : nil
          ins_status = s.respond_to?(:instance_status) ? s.instance_status.details[0].status : nil
          status << sys_status << ins_status
        end
        message = if status.include?('passed')
                    "#{type} instance is running"
                  elsif status.include?('initializing')
                    "#{type} instance is starting"
                  else
                    "#{type} instance is unknown status"
                  end
      end
    else
      status << 'terminated'
      message = "#{type} instance has already terminated"
    end
    message
  end

  def instance_start(type)
    instance_id = type == :app ? app_instance_id : bench_instance_id
    res = ec2.describe_instance_status(instance_ids: [instance_id])

    message = if res.instance_statuses.count.positive?
                state = res.instance_statuses[0].instance_state.name
                case state
                when 'pending'
                  return "Error starting instance: #{type} instance is pending. Try again later."
                when 'running'
                  return "#{type} instance is already running."
                when 'terminated'
                  return 'Error starting instance: ' \
                              "#{type} the instance is terminated, so you cannot start it."
                end
              end
    return message if message

    ec2.start_instances(instance_ids: [instance_id])
    ec2.wait_until(:instance_running, instance_ids: [instance_id])
    "#{type} Instance started."
  rescue StandardError => e
    "Error starting instance: #{e.message}"
  end

  def instance_stop(type)
    instance_id = type == :app ? app_instance_id : bench_instance_id
    res = ec2.describe_instance_status(instance_ids: [instance_id])

    message = if res.instance_statuses.count.positive?
                state = res.instance_statuses[0].instance_state.name
                case state
                when 'stopping'
                  return "#{type} instance is already stopping."
                when 'stopped'
                  return "#{type} instance is already stopped."
                when 'terminated'
                  return 'Error stopping instance: ' \
                          "#{type} instance is terminated, so you cannot stop it."
                end
              end
    return message if message

    ec2.stop_instances(instance_ids: [instance_id])
    ec2.wait_until(:instance_stopped, instance_ids: [instance_id])
    "#{type} Instance stopped."
  rescue StandardError => e
    "Error stopping instance: #{e.message}"
  end

  def instance_public_ip(type)
    instance_id = type == :app ? app_instance_id : bench_instance_id
    res = ec2.describe_instances(instance_ids: [instance_id])
    ip = res.reservations[0]&.instances[0]&.public_ip_address
    return 'error!' unless ip

    "#{type} public ip address: #{ip}"
  end

  private

  def app_instance_id
    ENV['APP_INSTANCE_ID']
  end

  def bench_instance_id
    ENV['BENCH_INSTANCE_ID']
  end
end
