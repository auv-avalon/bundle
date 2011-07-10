#! /usr/bin/env ruby

# Each team will produce a log file of the mission within around 10 minutes of the end of the run. The format of the log file will be a comma separated ASCII file of the format: Time, position, action, a comment between simple quotes.
# (SSSSS,XXX.x,YYY.y,ZZZ.z,AA.aa). Logged data will be plotted by plotting routine written by the organising committee. This will be used to score the log file. For ASV tracking task the additional file of range and bearing data from the AUV to the pinger will need to be provided.

require 'eigen'
require 'roby/standalone'
require 'roby/log/event_stream'
require 'roby/log/plan_rebuilder'
require 'pocolog'

class LogSample
    attr_accessor :seconds
    attr_accessor :x
    attr_accessor :y
    attr_accessor :z
    attr_accessor :action
    attr_accessor :comment

    def initialize(seconds, x, y, z, action, comment)
	@seconds = seconds
	@x = x
	@y = y
	@z = z
	@action = action
	@comment = comment
    end

end

class LogConverter

    :output
    :samples

    def initialize
        @output = ""
        @samples = []
    end

    def addSample(sample)
        @samples << sample
    end

    def getLastSample
        return @samples.last
    end

    def convertSamples
        @samples.each do |sample|
            @output << convertToCsv(sample) + "\n"
        end
        return @output
    end

    def convertToCsv(sample)
        if not sample.is_a? LogSample
            puts "Incorrect input, need log sample."
            Process.exit()
        end
        return "#{sample.seconds},#{sample.x},#{sample.y},#{sample.z},#{sample.action},'#{sample.comment}'"
    end
end

def usage
    puts "Usage: ruby log_converter.rb <path to event log>}"
    puts "Example with two models: ruby log_converter log/avalon-events.0.log AvalonControl::MotionControlTask Sonardetector"
end

case ARGV.size
    when 0
	puts "Please submit event log file"
    #when 1
    #	puts "Please submit at least one desired model"
end

desired_models = [
    'Orocos::RobyPlugin::OffshorePipelineDetector::Task',
    'Orocos::RobyPlugin::Compositions::ControlLoop',
    'Orocos::RobyPlugin::BuoyDetector::Task'
]

OUTPUT_LOGFILE_NAME = "DFKI-Bremen_AVALON.txt"

input_logfile = ARGV.shift
all = []
log_converter = LogConverter.new
depth = 0
heading = 0
x_speed = 0
y_speed = 0
last_time = 0
position_estimate = Eigen::Vector3.new
position_estimate[0] = 0
position_estimate[1] = 0
position_estimate[2] = 0

pos_output_file = File.new("position.txt","w")
log_output_file = File.new(OUTPUT_LOGFILE_NAME,"w")

# TODO usability
puts "#~#~#~#~#~# IMPORTANT: You have to run this script out of the log folder!!! #~#~#~#~#~#"

#Get stream for orientation logfile
orientation_logfile = Pocolog::Logfiles.open('orientation_estimator.0.log') #TODO add constant
orientation_stream = orientation_logfile.stream('orientation_estimator.orientation_samples')
relpos_logfile = Pocolog::Logfiles.open('auv_rel_pos_controller.0.log')
relpos_stream = relpos_logfile.stream('auv_rel_pos_controller.motion_command')


# Get tasks of all desired models
desired_models.each do |arg|

    puts "*********** Working #{arg}"

    stream = Roby::LogReplay::EventFileStream.open(input_logfile)
    rebuilder = Roby::LogReplay::PlanRebuilder.new

    model_name = arg

    state = Hash.new
    model = rebuilder.find_model(stream, /#{model_name}/i)

    #puts "********** Model" + model.to_a

    all_tasks = ValueSet.new
    rebuilder.analyze_stream(stream) do
        tasks = rebuilder.plan.find_tasks(model).to_a
        all_tasks.merge(tasks.to_value_set)
	false
    end

    all_tasks.each do |p|
        p.history.each do |ev|
            all << ev
	    #puts "********** Event is of type " << ev.class.to_s
        end
    end

end #while

#symbol_width = all.map(&:symbol).map(&:to_s).map(&:size).max

all.sort_by { |ev| ev.time }.each do |ev|

    #puts "%s   %-#{symbol_width}s   %s" % [Roby.format_time(ev.time), ev.symbol, ev.task]
    #puts ev.symbol
    #puts (Roby.format_time ev.time)

    time = (ev.time - all[0].time).to_s.split('.').first.rjust(5, '0')
    action = (((ev.task.to_s.split ":0").first.split "::").drop 2).join "::"
    #puts "********** Sample time: " << ev.time.to_s

    #puts "********** Time interval array size:" << orientation_stream.time_interval.size.to_s

    if(ev.time <= orientation_stream.time_interval[1])
	orientation_stream.seek(ev.time)
	sample = orientation_stream.next[2]

	depth = sample.position[2]
	headingRad = sample.orientation.yaw
	heading = (180 / Math::PI) * headingRad

	relpos = relpos_stream.next[2]

	world_speed = sample.orientation * Eigen::Vector3.new(relpos.x_speed,relpos.y_speed,0)
	#puts "************************ World Speed type: " << world_speed.class.to_s


	# delta t
	time_offset = ev.time - last_time
	last_time = ev.time

	# delta p
	world_pos_offset = world_speed * time_offset

	# update position
	position_estimate[0] += position_estimate[0] + world_pos_offset[0]
	position_estimate[1] += position_estimate[1] + world_pos_offset[1]
	position_estimate[2] += depth

	pos_output_file.puts "#{position_estimate[0]} #{position_estimate[1]}"
	# call gnuplot with
	# echo "plot 'position.txt' using 1:2 with lines " | gnuplot -persist

    else
        puts "WARNING: Some events happened after last orientation sample."
    end

    log_converter.addSample(LogSample.new(time,"#{position_estimate[0]}","#{position_estimate[1]}","#{depth.to_s.rjust(5, '0')}","#{action}.#{ev.symbol}","heading = #{heading}"))

end

log_output_file.puts log_converter.convertSamples
puts "Logs converted to CSV into file " << OUTPUT_LOGFILE_NAME
