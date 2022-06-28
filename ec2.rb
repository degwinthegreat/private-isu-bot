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

  def instance_status(service_name)
    status = []
    instance_id = instance_id_find_by(service_name)
    res = ec2.describe_instance_status(instance_ids: [instance_id])
    if res.instance_statuses[0]
      if res.instance_statuses[0][:instance_status].empty?
        status << 'stopped'
        message = "#{service_name} instance has stopped"
      else
        res.instance_statuses.map do |s|
          sys_status = s.respond_to?(:system_status) ? s.system_status.details[0].status : nil
          ins_status = s.respond_to?(:instance_status) ? s.instance_status.details[0].status : nil
          status << sys_status << ins_status
        end
        message = if status.include?('passed')
                    "#{service_name} instance is running"
                  elsif status.include?('initializing')
                    "#{service_name} instance is starting"
                  else
                    "#{service_name} instance is unknown status"
                  end
      end
    else
      status << 'terminated'
      message = "#{service_name} instance has already terminated"
    end
    message
  end

  def instance_start(service_name)
    instance_id = instance_id_find_by(service_name)
    res = ec2.describe_instance_status(instance_ids: [instance_id])

    message = if res.instance_statuses.count.positive?
                state = res.instance_statuses[0].instance_state.name
                case state
                when 'pending'
                  return "Error starting instance: #{service_name} instance is pending. Try again later."
                when 'running'
                  return "#{service_name} instance is already running."
                when 'terminated'
                  return 'Error starting instance: ' \
                              "#{service_name} the instance is terminated, so you cannot start it."
                end
              end
    return message if message

    ec2.start_instances(instance_ids: [instance_id])
    ec2.wait_until(:instance_running, instance_ids: [instance_id])
    "#{service_name} Instance started."
  rescue StandardError => e
    "Error starting instance: #{e.message}"
  end

  def instance_stop(service_name)
    instance_id = instance_id_find_by(service_name)
    res = ec2.describe_instance_status(instance_ids: [instance_id])

    message = if res.instance_statuses.count.positive?
                state = res.instance_statuses[0].instance_state.name
                case state
                when 'stopping'
                  return "#{service_name} instance is already stopping."
                when 'stopped'
                  return "#{service_name} instance is already stopped."
                when 'terminated'
                  return 'Error stopping instance: ' \
                          "#{service_name} instance is terminated, so you cannot stop it."
                end
              end
    return message if message

    ec2.stop_instances(instance_ids: [instance_id])
    ec2.wait_until(:instance_stopped, instance_ids: [instance_id])
    "#{service_name} Instance stopped."
  rescue StandardError => e
    "Error stopping instance: #{e.message}"
  end

  def instance_public_ip(service_name)
    instance_id = instance_id_find_by(service_name)
    res = ec2.describe_instances(instance_ids: [instance_id])
    ip = res.reservations[0]&.instances[0]&.public_ip_address
    return "#{service_name} instance has already terminated" unless ip

    "#{service_name} public ip address: #{ip}"
  end

  private

  def instance_id_find_by(service_name)
    case service_name
    when :app then app_instance_id
    when :app2 then app2_instance_id
    when :bench then bench_instance_id
    end
  end

  def app_instance_id
    ENV['APP_INSTANCE_ID']
  end

  def app2_instance_id
    ENV['APP2_INSTANCE_ID']
  end

  def bench_instance_id
    ENV['BENCH_INSTANCE_ID']
  end
end
