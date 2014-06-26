require "models/blueprints/avalon"
require "models/blueprints/sensors"


module VideoStreamerVlc
    class Task
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
        add VideoStreamerVlc::Task, :as => "vlc"
    end

    def self.stream(camera, width, height, port)
        model = VideoStreamerVlc::Task.specialize
        model.require_dynamic_service('dispatch', :as => camera.name, :width => width, :height => height, :port => port)

        Composition.new_submodel do
            overload 'vlc', model
            add camera, :as => "camera"
            camera_child.connect_to vlc_child
        end
    end
end

