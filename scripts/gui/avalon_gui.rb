#!/usr/bin/env ruby

class AvalonGUI < Qt::Widget
    def initialize(options=default_options, vlc_consumer=nil, parent=nil)
        super parent
        #add layout to the widget
        @layout = Qt::GridLayout.new
        @widget = Vizkit.load File.join(File.dirname(__FILE__),'avalon_gui.ui'), self
        @layout.addWidget(@widget,0,0)
        self.setLayout @layout

        @options = default_options
        set_options(options)
        @async = Orocos::Async
        @vlc_consumer = vlc_consumer
        @front_camera_port = nil
        @bottom_camera_port = nil

        @front_camera_port_listener = nil
        @bottom_camera_port_listener = nil

        @state_viewer = Vizkit.default_loader.StateViewer 
        @state_viewer.options(:max_rows => @options[:state_viewer_max_rows])
        @widget.scrollarea.setWidget @state_viewer

        @widget.button_off.connect(SIGNAL('released()')) do
            if @widget.button_off.isChecked
                #puts 'Not jet implemented.'
                deactivate_cams
            end
        end

        @widget.button_cam_tasks.connect(SIGNAL('released()')) do
            if @widget.button_cam_tasks.isChecked
                show_task_cams
            end
        end

        @widget.button_vlc_task.connect(SIGNAL('released()')) do
            if @widget.button_vlc_task.isChecked
                #puts 'Not jet implemented.'
                show_vlc_cams
            end
        end

        @async.name_service.names.each do |name|
            add_task_to_stateviewer(name)
        end
        @async.name_service.once_on_task_added do |name|
            add_task_to_stateviewer(name)
        end

        @sonar = Orocos::Async.proxy 'sonar'
        @orientation_estimator = Orocos::Async.proxy 'depth_orientation_fusion'
        @imu_sim = Orocos::Async.proxy 'imu'
        @front_camera = Orocos::Async.proxy 'front_camera'
        @bottom_camera = Orocos::Async.proxy 'bottom_camera'

        @orientation_estimator.port("pose_samples").once_on_reachable do
            Vizkit.display @orientation_estimator.port("pose_samples"), :widget => @widget.orientationview
        end

        @imu_sim.port("pose_samples").once_on_reachable do
            Vizkit.display @imu_sim.port("pose_samples"), :widget => @widget.orientationview
        end

        @sonar.port("sonar_beam").once_on_reachable do
            Vizkit.display @sonar.port("sonar_beam"), :widget => @widget.sonarview
        end

        @front_camera.port("frame").once_on_reachable do
            @front_camera_port = @front_camera.port("frame")
        end

        @bottom_camera.port("frame").once_on_reachable do
            @bottom_camera_port = @bottom_camera.port("frame")
        end

    end

    def default_options
        options = Hash.new
        options[:host_address] = "127.0.0.1"
        options[:vlc_server] = "127.0.0.1"
        options[:show_loggers] = false
        options[:state_viewer_max_rows] = 6
        options[:vlc_front_cam_port] = 5005
        options[:vlc_bottom_cam_port] = 5004
        options
    end

    def set_options(hash = Hash.new)
        @options ||= default_options
        @options.merge!(hash)
    end

    def deactivate_cams
        puts 'deactivate_cams'
        if !@front_camera_port_listener.nil?
            @front_camera_port_listener.disconnect 
        end
        if !@bottom_camera_port_listener.nil?
            @bottom_camera_port_listener.disconnect 
        end
    end

    def show_task_cams
        deactivate_cams
        puts 'show_task_cams'
        if !@front_camera_port_listener.nil?
            @front_camera_port_listener.reconnect (@front_camera_port)
        else
            @front_camera_port_listener = Vizkit.display( @front_camera_port, :widget => @widget.imageview_front ).connection_manager unless @front_camera_port.nil?
        end
        if !@bottom_camera_port_listener.nil?
            @bottom_camera_port_listener.reconnect (@bottom_camera_port)
        else
            @bottom_camera_port_listener = Vizkit.display( @bottom_camera_port, :widget => @widget.imageview_bottom ).connection_manager unless @bottom_camera_port.nil?
        end
    end

    def show_vlc_cams   
        deactivate_cams
        puts 'show_vlc_cams'
        if !@vlc_consumer.nil?
            if !@vlc_consumer.running?
                #front_success = @vlc_consumer.createStream("front_cam","rtp://" + @options[:host_address] + ":" + @options[:vlc_front_cam_port]) unless @vlc_consumer.port("front_cam").nil?
                #bottom_success = @vlc_consumer.createStream("bottom_cam","rtp://" + @options[:host_address] + ":" + @options[:vlc_bottom_cam_port]) unless @vlc_consumer.port("bottom_cam").nil?
                front_success = @vlc_consumer.createStream("front_cam","http://" + @options[:vlc_server].to_s + ":" + @options[:vlc_front_cam_port].to_s + "/video.mjpg") unless @vlc_consumer.has_port?("front_cam")
                bottom_success = @vlc_consumer.createStream("bottom_cam","http://" + @options[:vlc_server].to_s + ":" + @options[:vlc_bottom_cam_port].to_s + "/video.mjpg") unless @vlc_consumer.has_port?("bottom_cam")
                if front_success || bottom_success
                    @vlc_consumer.configure
                    @vlc_consumer.start
                end
                if front_success && @vlc_consumer.has_port?("front_cam")
                    @front_camera_port_listener = Vizkit.display( @vlc_consumer.front_cam, :widget => @widget.imageview_front ).connection_manager
                end
                if bottom_success && @vlc_consumer.has_port?("bottom_cam")
                    @bottom_camera_port_listener = Vizkit.display( @vlc_consumer.bottom_cam, :widget => @widget.imageview_bottom ).connection_manager
                end
            else
                if !@front_camera_port_listener.nil?
                    @front_camera_port_listener.reconnect (@vlc_consumer.port("front_cam"))
                end
                if !@bottom_camera_port_listener.nil?
                    @bottom_camera_port_listener.reconnect (@vlc_consumer.port("bottom_cam"))
                end
            end
        end
    end

    def add_task_to_stateviewer(name)
        if @options[:show_loggers] || !name.include?("_Logger")
            task = @async.proxy name
            @state_viewer.add(task)
        end
    end

end
