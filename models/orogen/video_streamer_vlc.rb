require "models/blueprints/auv"
require "models/blueprints/sensors"


module VideoStreamerVlc
    Model = VideoStreamerVlc::Streamer.specialize
    class Streamer 

        dynamic_service Base::ImageConsumerSrv, :as => "dispatch" do
            component_model.argument "width"
            component_model.argument "height"
            component_model.argument "port"
            provides Base::ImageConsumerSrv, :as => name, 'frame' => "frame_#{name}"
        end

        def configure 
            super
            each_data_service do |srv|
                config = Types::VideoStreamerVlc::PortConfig.new
                config.port_name = "frame"
                config.config.fps = 30
                config.config.frame_width = width
                config.config.frame_height = height
                config.config.vcodec = "MJPG"
                config.config.mux = "mpjpeg"
                config.config.dst= "127.0.0.1:#{port}/video.mjpg"
                task.createInput(config)
            end
        end
    end


    class Composition < Syskit::Composition
        add VideoStreamerVlc::Streamer, :as => "vlc"
    end

    def self.stream(camera, width, height, port)
        Model.require_dynamic_service('dispatch', :as => camera.name, :width => width, :height => height, :port => port)

        Composition.new_submodel do
            overload 'vlc', Model
            add camera, :as => "camera"
            camera_child.connect_to vlc_child.find_input_port("frame_" + camera.name)
        end
    end
end

