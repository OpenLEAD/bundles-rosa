#! /usr/bin/env ruby
#
# Merge sets of scans (as generated by split_autoscan) in a way that can be used by build_mls_from_logs
#
# It expects
# - a list of datasets (directories). The directory basename is used
#   as the dataset name
# - a transformer file which provides a list of static transformations
#   dataset_name => 'reference'
# 
# It then generates a dataset where all the scans logfiles are concatenated AND
# a new scan_aligner log contains the transformation info as a 'scan_ref' ->
# 'surface_center' transformation in the /scan_aligner.dynamic_transformations
# stream

require 'orocos'
require 'pocolog'
require 'transformer'

output_dir = nil
scans_transforms = nil
option_parser = OptionParser.new do |opt|
    opt.on '--output=DIR', String do |arg|
        arg = Pathname.new(arg)
        if arg.exist?
            STDERR.puts "output directory #{arg} already exists"
            exit 1
        end
        output_dir = arg
    end
    opt.on '--scan-transforms=FILE', String do |arg|
        conf = Transformer::Configuration.new
        conf.load(arg)
        scans_transforms = conf
    end
end

log_dirs = option_parser.parse(ARGV).map do |path|
    Pathname.new(path)
end
if !output_dir
    STDERR.puts "no output directory given with --output"
    exit 1
end

Orocos.load_typekit 'base'

output_dir.mkpath

output_files = Hash.new
if scans_transforms
    scan_aligner_log = Pocolog::Logfiles.create(output_dir + 'scan_aligner')
    scan_aligner_stream = scan_aligner_log.create_stream '/scan_aligner.dynamic_transformations',
        Types::Base::Samples::RigidBodyState
end
    

log_dirs.each do |log_dir|
    log_files = Pathname.glob(log_dir + "*.log").map do |log_file_path|
        [Pocolog::Logfiles.open(log_file_path), log_file_path]
    end

    if scans_transforms
        start_time = log_files.flat_map do |log_file, _|
            log_file.streams.map { |s| s.time_interval.first }
        end.min

        puts "start time: #{start_time}"

        if log_dir.basename.to_s =~ /(\d{6})$/
            frame_name = $1
        else raise ArgumentError, "invalid log dir pattern, expected it to finish with the timestamp as HHMMSS"
        end

        scan_transform = scans_transforms.transformation_for(frame_name, 'reference')
        scan_rbs = Types::Base::Samples::RigidBodyState.Invalid
        scan_rbs.time = start_time
        scan_rbs.sourceFrame = 'scan_ref'
        scan_rbs.targetFrame = 'surface_center'
        scan_rbs.position = scan_transform.translation
        scan_rbs.orientation = scan_transform.rotation
        scan_aligner_stream.write scan_rbs.time, scan_rbs.time, scan_rbs
    end

    log_files.each do |infile, log_file_path|
        log_name = log_file_path.basename('.0.log').to_s

        puts "processing #{log_name} (#{log_file_path})"

        if !(outfile = output_files[log_name])
            outfile = output_files[log_name] =
                Pocolog::Logfiles.create(output_dir + log_name)
        end

        if log_name == 'ptu'
            ref_stream = infile.stream '/ptu.transformation_samples'
            ref_stream.samples.raw_each do |time, _, _|
                scan_rbs.time = time
                scan_aligner_stream.write time, time, scan_rbs
            end
        end

        infile.streams.each do |instream|
            outstream =
                if !outfile.has_stream?(instream.name)
                    outfile.create_stream instream.name, instream.type
                else
                    outfile.stream(instream.name)
                end

            instream.samples.raw_each do |rt, lg, sample|
                outstream.write rt, lg, sample
            end
        end
    end
end

