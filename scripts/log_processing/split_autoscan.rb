#! /usr/bin/env ruby

require 'pocolog'
require 'pathname'
require 'narray'

Typelib.specialize_model '/std/vector</uint32_t>' do
    def from_na(na)
        new.from_na(na)
    end
end

Typelib.specialize '/std/vector</uint32_t>' do
    def to_na
        NArray.to_na(to_byte_array[8..-1], NArray::LINT)
    end

    def from_na(na)
        from_buffer([na.size].pack("Q") + na.to_s)
    end
end

Typelib.specialize_model '/std/vector</double>' do
    def from_na(na)
        new.from_na(na)
    end
end

Typelib.specialize '/std/vector</double>' do
    def to_na
        NArray.to_na(to_byte_array[8..-1], NArray::DFLOAT)
    end

    def from_na(na)
        from_buffer([na.size].pack("Q") + na.to_s)
    end
end

Typelib.specialize_model '/std/vector</float>' do
    def from_na(na)
        new.from_na(na)
    end
end

Typelib.specialize '/std/vector</float>' do
    def to_na
        NArray.to_na(to_byte_array[8..-1], NArray::SFLOAT)
    end

    def from_na(na)
        from_buffer([na.size].pack("Q") + na.to_s)
    end
end

FilteredStream = Struct.new(:file_path, :input_stream, :skip, :output_stream, :pending) do
    def name
        input_stream.name
    end

    def clear_pending
        pending.clear
    end

    def write_pending
        puts "writing #{pending.size} samples on #{output_stream.name} from #{pending.first.first} to #{pending.last.first}"
        pending.each { |rt, lg, sample| output_stream.write(rt, lg, sample) }
        pending.clear
    end
end

def parse_command_line(args)
    annotation_log_path   = Pathname.new(args.shift)
    annotation_log_stream = args.shift
    output_dir = Pathname.new(args.shift)

    annotation_log = Pocolog::Logfiles.open(annotation_log_path)
    annotation_stream = annotation_log.stream(annotation_log_stream)

    to_filter = Array.new
    while !args.empty?
        file_path = args.shift
        next if file_path == "--"
        file = Pocolog::Logfiles.open(file_path)

        skip = 0
        while !args.empty?
            stream_name = args.shift
            if stream_name == '--'
                break
            elsif stream_name == '--skip'
                skip = Integer(args.shift)
                next
            end

            to_filter << FilteredStream.new(Pathname.new(file_path), file.stream(stream_name), skip)
            skip = 0
        end
    end
    return annotation_stream, output_dir, to_filter
end

def create_output(output_dir, streams, laser_stream_name)
    if output_dir.exist?
        raise ArgumentError, "#{output_dir} already exists"
    end
    output_dir.mkpath

    puts "creating output files in #{output_dir}"
    output_files = Hash.new
    consensus_stream, laser_stream = nil
    streams.each do |stream|
        output_file_path = output_dir + stream.file_path.basename(".0.log")
        output_file = (output_files[stream.file_path] ||= Pocolog::Logfiles.create(output_file_path))
        if stream.name == laser_stream_name
            laser_stream = stream
            consensus_stream = output_file.create_stream "/seaking.consensus_scan", stream.input_stream.type
        end
        stream.output_stream = output_file.create_stream(stream.input_stream.name, stream.input_stream.type)
    end
    return consensus_stream
end

def normalize_scans(scans)
    resolution = scans.first.angular_resolution
    start_angle = scans.map do |s|
        s.start_angle
    end.min
    end_angle = scans.map do |s|
        s.start_angle + s.ranges.size * resolution
    end.max
    range_size = ((end_angle - start_angle) / resolution + 1).round

    # Now rebuild all scans to fit the definition
    scans.map do |s|
        s = s.dup
        start = s.start_angle
        offset = ((start - start_angle) / resolution).round
        s.ranges = Array.new(offset, 0) + s.ranges.to_a + Array.new(range_size - offset - s.ranges.size, 0)
        s.start_angle = start_angle
        s
    end
end

def compute_statistics(scans)
    range_size = scans.first.ranges.size
    sum    = NArray.int(range_size)
    sum2   = NArray.int(range_size)
    counts = NArray.int(range_size)

    scans.each do |scan|
        ranges = scan.ranges.to_na

        sum  += ranges
        sum2 += ranges ** 2
        mask = (ranges.ne 0)
        ones = NArray.int(range_size)
        ones[mask] = 1
        counts += ones
    end

    average  = sum.to_type(NArray::DFLOAT) / counts
    average2 = sum2.to_type(NArray::DFLOAT) / counts
    stddev  = NMath.sqrt(average2 - average ** 2)
    return average, stddev
end

def process_consensus_scan(scans)
    average, stddev = compute_statistics(scans)

    # Now rebuild the consensus by filtering points that are outside 2 delta from the mean
    min = average - stddev
    min[min.lt 0] = 0
    max = average + stddev

    range_size = average.size

    consensus = NArray.int(range_size)
    counts = NArray.int(range_size)
    scans.each do |scan|
        ranges = scan.ranges.to_na
        mask = ranges < min || max < ranges
        ranges[mask] = 0
        consensus += ranges

        ones = NArray.int(range_size)
        ones[mask.not] = 1
        counts += ones
    end

    consensus /= counts

    sample = scans.first.dup
    sample.ranges.from_na(consensus)
    sample
end

annotation_stream, output_dir, streams = parse_command_line(ARGV)
streams.each do |s|
    s.pending = Array.new
end
laser_stream = streams.find do |s|
    s.input_stream.type.name == '/base/samples/LaserScan'
end

show_consensus = false

if show_consensus
    require 'vizkit'
    plotter = Vizkit.default_loader.Plot2d
    plotter.show
end


do_log = nil # nil means "not done anything yet". true and false that we have passed a PTU_MOVED or PTU_MOVING annotation
last_pos = nil
streams_info = nil
consensus_stream = nil
replay = Pocolog::StreamAligner.new(false, annotation_stream, *streams.map(&:input_stream))
time, _, _ = annotation_stream.first
replay.seek(time - 1)
while !replay.eof?
    index, time, sample = replay.step
    if index == 0
        if sample.key == "PTU_MOVED"
            if do_log == false # we did get a PTU_MOVED/PTU_MOVING section. 
                laser_stream = streams_info.find do |s|
                    s.name == laser_stream.name
                end
                consensus_scan   = process_consensus_scan(laser_stream.pending.map(&:last))
                consensus_stream.write consensus_scan.time, consensus_scan.time, consensus_scan

                if show_consensus
                    laser_stream.pending.each_with_index do |(_, _, s), i|
                        plotter.update_laser_scan(s, "#{i}")
                    end
                    plotter.update_laser_scan(consensus_scan, "consensus")
                    puts "displayed the new consensus scan, press ENTER to continue"
                    Qt::MessageBox.information(plotter, "split_autoscan", "Close this window to continue")
                end

                streams_info.each do |stream|
                    stream.write_pending
                end
            elsif do_log # Got a PTU_MOVED without PTU_MOVING, ignore
                puts "#{time} dropping PTU_MOVED section without PTU_MOVING end marker at #{last_pos * 180 / Math::PI}"
            end

            pos = sample.value.split(" ").map { |v| Float(v) }[0]
            if !last_pos || (pos < last_pos)
                timestamp = time.strftime("%H%M%S")
                if last_pos
                    puts "#{time} moved back from #{last_pos * 180 / Math::PI} to #{pos * 180 / Math::PI}, assuming start of a new scan at #{timestamp}"
                end
                consensus_stream = create_output output_dir.sub_ext("-#{timestamp}"), streams, laser_stream.name
            end
            streams_info = streams.map(&:dup)
            streams_info.each(&:clear_pending)
            puts "#{time} PTU now at #{pos * 180 / Math::PI}"
            last_pos = pos
            do_log = true
        elsif sample.key == "PTU_MOVING"
            do_log = false
        end
    elsif do_log
        stream = streams_info[index - 1]
        skip = (stream.skip -= 1)
        if skip < 0
            stream.pending << [time, time, sample]
        else
            puts "skipping sample on #{stream.name}"
        end
    end
end

