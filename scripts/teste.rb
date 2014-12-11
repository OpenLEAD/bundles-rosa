class  FilterConfig
    def initialize seed = 42
        @seed = seed
	@config = {}
    end

    def getSeed
      @seed
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

c =  FilterConfig.new 
c = @config[:rosa]
puts c.getSeed


