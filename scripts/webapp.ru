require 'orocos'
require 'rock/webapp/tasks'

Faye::WebSocket.load_adapter('thin')
EM.next_tick { Rock::WebApp::Tasks.install_event_loop }

Orocos::CORBA.name_service.ip = 'localhost'
Orocos.initialize

class API < Grape::API
    resource 'tasks' do
        mount Rock::WebApp::Tasks::Root
    end
end

map '/api' do
    run API
end

