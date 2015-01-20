require 'utilrb/kernel/options'

# Implementation of the state machine that does a pan/tilt automatic scan
#
# It takes into account the actual position readings as well as the sonar output
# to decide when to increment the angles
class AutoscanStateMachine < Qt::Object
    Range = Struct.new :start, :end, :step

    attr_reader :position_reached_tolerance
    attr_reader :position_reached_timeout
    attr_reader :full_scans_per_position
    attr_reader :run_timer

    # @option options [Float] :position_reached_tolerance (3 degrees) Tolerance
    #   to decide whether a target position has been reached, in radians.
    # @option options [Float] :position_reached_timeout (2) the PTU must have
    #   reached a stable position within position_reached_tolerance of the goal
    #   position for that many seconds before the code decides that it is indeed
    #   on the goal.
    # @option options [Integer] :full_scans_per_position (2) the number of full
    #   sonar scans we want per PTU position
    def initialize(pan_range, tilt_range, options = Hash.new)
        @pan_range, @tilt_range = pan_range, tilt_range
        options = Kernel.validate_options options,
            position_reached_tolerance: 3 * Math::PI / 180,
            position_reached_timeout:   2,
            full_scans_per_position:    2

        @position_reached_tolerance, @position_reached_timeout, @full_scans_per_position =
            options.values_at(:position_reached_tolerance, :position_reached_timeout, :full_scans_per_position)

        super()
        @received_scans = 0
        @moved = false
    end

    # Can be :wait_for_position, :wait_for_scan
    attr_reader :state

    attr_reader :position_reached_start

    attr_reader :cmd_pan,  :pan,  :last_pan,  :pan_range
    attr_reader :cmd_tilt, :tilt, :last_tilt, :tilt_range

    def update_position(pan, tilt)
        @moved ||= (@pan != pan || @tilt != tilt)
        @pan, @tilt = pan, tilt
    end

    def received_scan
        @received_scans += 1
    end

    def target_position_reached?
        (cmd_pan - pan).abs <= position_reached_tolerance &&
            (cmd_tilt - tilt).abs <= position_reached_tolerance
    end

    def moved?
        result, @moved = @moved, false
        result
    end

    def wait_for_position
        if !target_position_reached? || moved?
            @position_reached_start = nil
            return
        end

        @position_reached_start ||= Time.now
        if (Time.now - position_reached_start) > position_reached_timeout
            true
        end
    end

    def wait_for_scan
        # We need one more scan than expected to account for a partial scan
        # taken while moving the pan unit
        @received_scans > full_scans_per_position
    end

    def increment_position
        cmd_pan  = @cmd_pan + pan_range.step
        cmd_tilt = @cmd_tilt
        if cmd_pan > pan_range.end
            cmd_pan  = pan_range.start
            cmd_tilt = @cmd_tilt + tilt_range.step
            if cmd_tilt > tilt_range.end
                return false
            end
        end

        move(cmd_pan, cmd_tilt)
        true
    end

    def wait_for_position_reading
        @pan && @tilt
    end

    def process
        if state == :wait_for_position_reading
            puts "wait_for_position_reading"
            if wait_for_position_reading
                @moved = false
                wait_for_position
                return :wait_for_position
            else return :wait_for_position_reading
            end
        elsif state == :wait_for_position
            puts "wait_for_position #{target_position_reached?} #{cmd_pan} #{pan} #{cmd_tilt} #{tilt} #{moved?} #{position_reached_start}"
            if wait_for_position
                @received_scans = 0
                return :wait_for_scan
            else
                return :wait_for_position
            end
        elsif state == :wait_for_scan
            if wait_for_scan
                if increment_position
                    @position_reached_start = nil
                    return :wait_for_position
                else
                    # Finished !
                    return
                end
            else
                return :wait_for_scan
            end
        end
    end

    def update
        @state = process
    end

    def move(pan, tilt)
        @cmd_pan, @cmd_tilt = pan, tilt
        emit moveJoints(cmd_pan, cmd_tilt)
    end

    def start
        move(pan_range.start, tilt_range.start)
        @state = :wait_for_position_reading
    end

    def run(period)
        start
        @run_timer = Qt::Timer.new
        run_timer.connect SIGNAL('timeout()') do |flag|
            state = update
            puts "in state #{state.inspect}"
            if !state
                stop
            end
        end
        run_timer.start(Integer(period * 1000))
    end

    def stop
        run_timer.stop
    end

    def self.run(period, pan_range, tilt_range)
        machine = new(pan_range, tilt_range)
        machine.run(period)
        machine
    end

    slots 'update_position(double, double)'
    slots 'received_scan()'
    signals 'moveJoints(double,double)'
end

