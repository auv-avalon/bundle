#! /usr/bin/env ruby

# Each team will produce a log file of the mission within around 10 minutes of the end of the run. The format of the log file will be a comma separated ASCII file of the format: Time, position, action, a comment between simple quotes.
# (SSSSS,XXX.x,YYY.y,ZZZ.z,AA.aa). Logged data will be plotted by plotting routine written by the organising committee. This will be used to score the log file. For ASV tracking task the additional file of range and bearing data from the AUV to the pinger will need to be provided.

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

#TODO coords and time always with max. number of chars?
s1 = LogSample.new(00000, 0, 0, -1.0, "STARTING", "Nice comment")
s2 = LogSample.new(00012, 2, 55, -1.5, "WORKING", "Even nicer comment")
s3 = LogSample.new(01234, 034, 0, -1.0, "DONE", "Final comment")

#puts LogConverter.new.convertSamples([s1,s2,s3])

##### DEBUG!!!
#Process.exit()

def usage
    puts "Usage: ruby log_converter.rb <path> {<model>}"
    puts "Example with two models: ruby log_converter log/avalon-events.0.log AvalonControl::MotionControlTask Sonardetector"
end

case ARGV.size
    when 0
	puts "Please submit event log file"
    when 1
	puts "Please submit at least one desired model"
end

puts "***** ARGV = #{ARGV}"

input_logfile = ARGV.shift
all = []
log_converter = LogConverter.new


# Get tasks of all desired models
ARGV.each do |arg|

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
    
symbol_width = all.map(&:symbol).map(&:to_s).map(&:size).max

all.sort_by { |ev| ev.time }.each do |ev|
    
    #puts "%s   %-#{symbol_width}s   %s" % [Roby.format_time(ev.time), ev.symbol, ev.task]
    #puts ev.symbol
    #puts (Roby.format_time ev.time)

    time = (ev.time - all[0].time).to_s.split('.').first.rjust(5, '0')
    action = (((ev.task.to_s.split ":0").first.split "::").drop 2).join "::"
    log_converter.addSample(LogSample.new(time,"XXX.x","YYY.y","ZZZ.z","#{action}.#{ev.symbol}","heading = <HEADING>; fancy comment"))
end

puts log_converter.convertSamples

### TODO: get heading, depth
#file = Pocolog::Logfiles.open(filename)
#stream = file.stream('orientation.orientation_samples')
#
#stream.seek(time)
#time, _, data = stream.next
