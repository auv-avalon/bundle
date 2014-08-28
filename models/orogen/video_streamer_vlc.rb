require "models/blueprints/auv"
require "models/blueprints/sensors"


module VideoStreamerVlc
    
    class Streamer
        dynamic_service Base::ImageConsumerSrv, :as => "dispatch" do
            provides Base::ImageConsumerSrv, :as => name, 'frame' => "frame_#{name}"
        end

        def configure 
            super
            each_data_service do |srv|
                config = Types::VideoStreamerVlc::PortConfig.new
                config.port_name = "frame_#{srv.name}" 
                config.config.fps = 30
                config.config.frame_width = srv.model.dynamic_service_options[:width]
                config.config.frame_height = srv.model.dynamic_service_options[:height]
                #config.config.vcodec = "MJPG"
                #config.config.mux = "mpjpeg"
                #config.config.dst= "192.168.128.50:#{srv.model.dynamic_service_options[:port]}/video.mjpg"
                config.config.raw_config = "#transcode{vcodec=mjpg,scale=0.5,vb=100,threads=4}:rtp{mux=ts,dst=239.255.12.42,port=#{srv.model.dynamic_service_options[:port]},ttl=30}"
                orocos_task.createInput(config)
            end
        end
    end

#    class Test < Syskit::Composition
#        add Streamer, :as => "fusel"
#    end
    Model = VideoStreamerVlc::Streamer.specialize

#    class Composition < Syskit::Composition
#        add VideoStreamerVlc::Streamer, :as => "vlc"
#    end

    def self.stream(camera, width, height, port)
        VideoStreamerVlc::Streamer.require_dynamic_service('dispatch', :as => camera.name, :width => width, :height => height, :port => port, :name => "#{camera.name}_fusel")

        Syskit::Composition.new_submodel(:name => "#{camera.name}_cmp") do
            add VideoStreamerVlc::Streamer, :as => "vlc"

            add camera, :as => "camera"
            camera_child.connect_to vlc_child.find_input_port("frame_" + camera.name)
        end
    end

end

