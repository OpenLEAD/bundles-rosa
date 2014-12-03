require 'rock/bundles'
require 'orocos'
require 'readline'
#library for displaying data
require 'vizkit'


# You need to initialize before you can use the transformer
include Bundles
Bundles.initialize
Bundles.transformer.load_conf('config/transforms.rb')
Bundles.run 'rosa_localization::Task' => 'rosa_localization' do
    rosa_localization = Orocos.name_service.get 'rosa_localization'

    #Open the log of the components necessary to run the localizartion
    #It is assumed that the script is going to be run on the log folder 
    #of the FILTERED logs
    sonar_log = Orocos::Log::Replay.open("../logs/20141106-1455-Micron180to0aprox6.3m/micron.0.log")
    ptu_log =  Orocos::Log::Replay.open("../logs/20141106-1455-Micron180to0aprox6.3m/ptu.0.log")

    #
    sonar = sonar_log.micron
    ptu = ptu_log.ptu
    
    ## Create a sample writer for the pressure sensor port ##
    depth_samples_port = rosa_localization.depth.writer

    #Create a sample 
    depth_sample = depth_samples_port.new_sample
    depth_sample.position[0] = 0
    depth_sample.position[1] = 0
    #Try to match the value from the current log
    depth_sample.position[2] = 6.0

    depth_sample.orientation = Eigen::Quaternion.Identity

    # Tell in which frames is the data expressed. These are not
    # arbitrary anymore: they MUST match the frame names listed
    # in the transformer's

    #The log is not allowed to have this proprety set.
    #sonar.sonar_beam.frame = 'sonar'

    # Properly setup frame names. These are not arbitrary anymore:
    # they MUST match the frame names listed in the transformer's
    # configuration files
    rosa_localization.body_frame = "body"
    depth_samples_port.frame = "depth"

    #The ptu frames are already set as the default values in the log
    #ptu.base_frame = "ptu_kongsberg_base"
    #ptu.moving_frame = "ptu_kongsberg_moving"
 
    sonar.sonar_beam.connect_to(rosa_localization.sonarBeams)
    
    # Finalize transformer configuration (see below for explanations)
    # For static transformations the task should not not yet be configured
    Orocos.transformer.setup(rosa_localization,ptu,sonar,depth_samples_port)

    rosa_localization.configure

    #open control widget and start replay
    Vizkit.control sonar_log
    Vizkit.control ptu_log
    Vizkit.exec

    rosa_localization.start
    #To run all the replays at once with normal speed
    #replay.run
    

  
    Readline::readline("Press ENTER to exit\n") do
    end 

    # Wait for ENTER on input
    STDIN.readline
end
