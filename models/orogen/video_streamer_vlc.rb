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
                config.config.fps = 15
                config.config.frame_width = srv.model.dynamic_service_options[:width]
                config.config.frame_height = srv.model.dynamic_service_options[:height]
                config.config.vcodec = "MJPG"
                config.config.mux = "mpjpeg"
                dst = "192.168.128.50:#{srv.model.dynamic_service_options[:port]}"
                config.config.dst= dst
                
                filename = "/mnt/logs/#{Time.new}-#{srv.name}.mp4"
                file_config = "std{access=file, mux=mp4, dst=#{filename}}" ##working
                stream = "rtp{mux=ts,dst=239.255.12.44,port=7775,ttl=500}" 
                preconfig = "#transcode{vcodec=mjpg,scale=0.5,vb=100,threads=4}"
                if(srv.name.include?("front"))
                    stream = "rtp{mux=ts,dst=239.255.12.40,ttl=100,port=8080}" 
                elsif (srv.name.include?("blue"))
                    stream = "rtp{mux=ts,dst=239.255.12.42,ttl=100,port=8080}" 
                else
                    stream = "rtp{mux=ts,dst=239.255.12.41,ttl=100,port=8080}" 
                end

                file = "std{access=file, mux=mp4, dst=#{filename}}"
                #stream = "std{access=http{mime=multipart/x-mixed-replace;boundary=--7b3cc56e5f51db803f790dad720ed50a},mux=mpjpeg,dst=#{dst}}"


                config.config.raw_config = "#{preconfig}:duplicate{dst=#{file},dst=#{stream}}"
#                if(srv.name.include?("front"))
#                    c_config = "transcode{vcodec=MJPG, vb=500, width = 2400, height = 1200}"
#                    file_config = "transcode{vcodec=mp4, vb=500, width = 2400, height = 1200}"
#                elsif (srv.name.include?("blue"))
#                    c_config = "transcode{vcodec=MJPG, vb=500, width = 256, height = 336}"
#                    file_config = "transcode{vcodec=mp4, vb=500, width = 256, height = 336}"
#                else
#                    c_config = "transcode{vcodec=MJPG, vb=500, width = 640, height = 480}"
#                    file_config = "transcode{vcodec=mp4, vb=500, width = 640, height = 480}"
#                end
                #config.config.raw_config = '#duplicate{dst="#{file_config}:#{file}",dst=#{c_config}:#{stream}'
                #config.config.raw_config = "#{c_config}:duplicate{dst=#{file},dst=#{stream}}"
                #config.config.raw_config = "#{c_config}:#{file}"
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

