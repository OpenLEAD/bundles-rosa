! /usr/bin/env ruby

require 'rock/bundles'
require 'orocos/async'

Bundles.initialize

def connect_device_to_bus(bus, task)
    task_name = task.basename
    task.io_port = ""
    bus.port(task_name).connect_to task.io_raw_in, :type => :buffer, :size => 50
    task.io_raw_out.connect_to bus.port("w#{task_name}"), :type => :buffer, :size => 50
end

def restart_on_exception(task)
    task.to_async.on_state_change do |state|
        if !task.runtime_state?(state)
            begin
                if task.exception_state?(state)
                    task.reset_exception
                    task.configure
                    task.start
                elsif task.rtt_state == :PRE_OPERATIONAL
                    task.configure
                    task.start
                elsif task.rtt_state == :STOPPED
                    task.start
                end
            rescue Orocos::StateTransitionFailed
            end
        end
    end
end


Bundles.run \
    'busses',
    'inclinometer::Task' => 'inclination_body',
    'pressure_velki::Task' => 'pressure' do

    bus1 = Bundles.get 'bus1'
    Orocos.conf.apply bus1, ['default', 'standard']
    
    bus1.configure
    Orocos.log_all
    bus1.start

    #inclination_body = Bundles.get 'inclination_body'
    #bus1.inclination_body.
	#connect_to inclination_body.analog_input
    #inclination_body.direction_flag = true
    #inclination_body.configure
    #inclination_body.start

    pressure = Bundles.get 'pressure'
    restart_on_exception(pressure)
    connect_device_to_bus(bus1, pressure)
    pressure.configure
    pressure.start

    Bundles.watch(
        bus1, pressure) do #, inclination_body
	# Workaround bug in orocos.rb to get the on_state_change in restart_on_exception working
	Orocos::Async.event_loop.step
    end
end




