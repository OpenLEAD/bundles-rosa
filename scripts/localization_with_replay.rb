class FilterConfig
    def initialize seed = 42
        @seed = seed
	@config = {}
    end

    def localization
        c = @config[:rosa]
        c.seed = @seed
        c.particleCount = 250
        c.minEffective = 50 
        c.initialRotationError = Eigen::Vector3.new(0, 0, 0.1)
        c.initialTranslationError = Eingen::Vector3.new(0.1, 0.1, 1.0)
        c.initialRollError =  0.1 
        c.discountFactor = 0.9 
        c.spreadThreshold = 0.9
        c.spreadTranslationXFactor = 0.1
        c.spreadTranslationYFactor = 0.1
        c.spreadTranslationZFactor 0.1 
        c.maxYawDeviation = 15*M_PI/180.0
        c.measurementThreshold = 0.1, 10*M_PI/180.0 
        c.maxSensorRange = 3.0
        c.logDebug = false 
        c.logParticlePeriod =  100 

        c = @config[:odometry]
        c.seed = @seed
        c.constError.translation = Eigen::Vector3.new( 0.01, 0.01, 0.0 )
        c.constError.yaw = 0.005 
        c.distError.translation = Eigen::Vector3.new( 0.1, 0.5, 0.0 )
        c.distError.yaw = 0.001 
        c.tiltError.translation = Eigen::Vector3.new( 0.01, 0.01, 0.0 )
        c.tiltError.yaw = 0.001
        c.dthetaError.translation = Eigen::Vector3.new( 0.05, 0.01, 0.0 )
        c.dthetaError.yaw = 0.005
    end
end


# You need to initialize before you can use the transformer
Orocos.initialize
Orocos.transformer.load_conf('config/transforms.rb')
Orocos.run ... do
    filter = Orocos.name_service.get 'rosa_localization'

    #Open the log of the components necessary to run the localizartion
    #It is assumed that the script is going to be run on the log folder 
    #of the FILTERED logs
    sonar_log = Orocos::Log::Replay.open("micron.0.log")
    ptu_log =  Orocos::Log::Replay.open("ptu.0.log")
    
    

  # Tell in which frames is the data expressed. These are not
  # arbitrary anymore: they MUST match the frame names listed
  # in the transformer's
  sonar_log.sonar_beam.frame = 'sonar'
  #filter.filtered_samples.frame = ''

  # Properly setup frame names. These are not arbitrary anymore:
  # they MUST match the frame names listed in the transformer's
  # configuration files
  filter.body_frame = "body"
  ptu.base_frame = "ptu_kongsberg_base"
  servo.moving_frame = "ptu_kongsberg_moving"

  sonar_log.micron.sonar_beam.sonar_beam.connect_to(filter.sonarBeams)
  	

  # Finalize transformer configuration (see below for explanations)
  # For static transformations the task should not not yet be configured
  Orocos.transformer.setup(sonar_log, filter, ptu_log)


  filter.rosa_localization_config = Config.new 42
  filter.configure
  filter.start
  
  #open control widget and start replay
  Vizkit.control log
  Vizkit.exec

  
  Readline::readline("Press ENTER to exit\n") do
  end 

  # Wait for ENTER on input
  STDIN.readline
end
