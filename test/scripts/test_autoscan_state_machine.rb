require 'Qt4'
require './scripts/autoscan_state_machine'
require 'minitest/autorun'
require 'minitest/spec'
require 'flexmock/test_unit'

class Minitest::Test
    include FlexMock::ArgumentTypes
    include FlexMock::MockContainer
end

describe AutoscanStateMachine do
    attr_reader :pan_range, :tilt_range, :machine
    before do
        @pan_range = AutoscanStateMachine::Range.new(
            10, 100, 5)
        @tilt_range = AutoscanStateMachine::Range.new(
            10, 100, 5)
        @machine = AutoscanStateMachine.new(pan_range, tilt_range)
    end

    after do
        flexmock_teardown
    end

    def assert_sends_signal(signal, expected_args)
        received = nil
        machine.connect SIGNAL(signal) do |*args|
            received = args
        end
        yield
        assert_equal expected_args, received
    end

    def mock_time(current)
        if !@__time_mocked
            flexmock(Time).should_receive(:now).and_return { @mocked_time }
            @__time_mocked = true
        end
        @mocked_time = current
    end

    describe "#start" do
        it "sends the first command to be the start positions" do
            assert_sends_signal 'moveJoints(double,double)', [10, 10] do
                machine.start
            end
        end
        it "sets the state to :wait_for_position" do
            machine.start
            assert_equal :wait_for_position_reading, machine.state
        end
    end

    describe "#wait_for_position_reading" do
        it "returns false initially" do
            assert !machine.wait_for_position_reading
        end
        it "returns true if both pan and tilt are set" do
            machine.update_position(10, 20)
            assert machine.wait_for_position_reading
        end
    end

    describe "#wait_for_position" do
        before do
            machine.start
            machine.update_position(10, 10)
        end

        it "starts counting as soon as the position is reached and the ptu did not move for one cycle" do
            mock_time(Time.now)
            machine.wait_for_position
            machine.wait_for_position
            assert_equal Time.now, machine.position_reached_start
        end

        describe "when it resets the start time" do
            before do
                mock_time(Time.now)
                machine.wait_for_position
                machine.wait_for_position
            end

            it "resets the start time if the PTU moves" do
                machine.update_position(11, 10)
                machine.wait_for_position
                assert !machine.position_reached_start
            end

            it "resets the start time if the pan angle is outside the range" do
                machine.move(20, 10)
                machine.wait_for_position
                assert !machine.position_reached_start
            end

            it "resets the start time if the tilt angle is outside the range" do
                machine.move(10, 20)
                machine.wait_for_position
                assert !machine.position_reached_start
            end
        end
    end

    describe "#wait_for_scan" do
        it "returns true if the number of received scans is bigger than the threshold" do
            machine.full_scans_per_position.times do
                assert !machine.wait_for_scan
                machine.received_scan
            end
            assert !machine.wait_for_scan
            machine.received_scan
        end
    end

    describe "#update" do
        before do
            machine.start
        end
        it "stays in :wait_for_position_reading if no position has been read" do
            assert_equal :wait_for_position_reading, machine.update
            assert_equal :wait_for_position_reading, machine.state
        end
        it "transitions to :wait_for_position if it got position" do
            machine.update_position 0, 0
            assert_equal :wait_for_position, machine.update
            assert_equal :wait_for_position, machine.state
        end
        it "stays in :wait_for_position if the target position is not reached" do
            machine.update_position 0, 0
            assert_equal :wait_for_position, machine.update
            assert_equal :wait_for_position, machine.update
            assert_equal :wait_for_position, machine.state
        end
        it "transitions to :wait_for_scan if the target position is reached and stable" do
            mock_time(Time.now)
            machine.update_position 10, 10
            assert_equal :wait_for_position, machine.update
            mock_time(Time.now + 10)
            assert_equal :wait_for_scan, machine.update
            assert_equal :wait_for_scan, machine.state
        end
        it "stays in :wait_for_scan until the required number of scans has been reached" do
            mock_time(Time.now)
            machine.update_position 10, 10
            assert_equal :wait_for_position, machine.update
            mock_time(Time.now + 10)
            assert_equal :wait_for_scan, machine.update
            machine.received_scan
            assert_equal :wait_for_scan, machine.update
            machine.received_scan
            assert_equal :wait_for_scan, machine.update
            machine.received_scan
            assert_equal :wait_for_position, machine.update
        end
        it "increments the target position when transition from wait_for_scan to wait_for_position" do
            mock_time(Time.now)
            machine.update_position 10, 10
            machine.update
            mock_time(Time.now + 10)
            machine.update
            machine.received_scan
            machine.received_scan
            machine.received_scan
            flexmock(machine).should_receive(:increment_position).once.
                and_return(true)
            machine.update
        end
        it "transitions to nil if increment_position indicates that the target position is reached" do
            mock_time(Time.now)
            machine.update_position 10, 10
            machine.update
            mock_time(Time.now + 10)
            machine.update
            flexmock(machine).should_receive(:wait_for_scan).once.
                and_return(true)
            flexmock(machine).should_receive(:increment_position).once.
                and_return(false)
            assert !machine.update
            assert !machine.state
        end
    end

    describe "#increment_position" do
        before do
            machine.start
        end

        def assert_position_command_changes(pan, tilt)
            assert_sends_signal 'moveJoints(double,double)', [pan,tilt] do
                yield
            end
            assert_equal pan, machine.cmd_pan
            assert_equal tilt, machine.cmd_tilt
        end

        it "increments the pan position first" do
            assert_position_command_changes 15, 10 do
                machine.increment_position
            end
        end

        it "increments the pan position first" do
            assert_position_command_changes 15, 10 do
                assert machine.increment_position
            end
        end

        it "resets the pan to start position and increments tilt if the pan end angle is reached" do
            machine.move 96, 10
            assert_position_command_changes 10, 15 do
                assert machine.increment_position
            end
        end

        it "does not send any command and returns nil if both tilt and pan are end-of-range" do
            machine.move 96, 96
            assert_sends_signal 'moveJoints(double,double)', nil do
                assert !machine.increment_position
            end
        end
    end
end
