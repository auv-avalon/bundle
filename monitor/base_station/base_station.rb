#!/usr/bin/env ruby

require 'vizkit'
class BaseStation < Qt::Object
    attr_reader :window

    def initialize()
        super

        #define names of devices
        @front_camera = "front_camera"
        @bottom_camera = "bottom_camera"
        @state_estimator = "state_estimator"
        @sonar_rear = "sonar_rear"
        @sonar = "sonar"
        @depth = "depth"
        @hbridge = "hbridge"
        @offshore_pipeline_detector = "pipeline_follower"
        @wall_servoing = "wall_servoing"
        @buoy_detector = "buoy_detector"
	@controlconverter = "controlconverter_movement"
	@sonar_feature_estimator = "sonar_feature_estimator"
	@auv_rel_pos_controller = "auv_rel_pos_controller"

        #load ui file
        @window = Vizkit.load(File.join(File.dirname(__FILE__),'base_station.ui'))

        #display state of some tasks
        @state_layout = Qt::GridLayout.new
        @state_viewer = Vizkit.default_loader.StateViewer
        #@state_viewer.add @front_camera
        #@state_viewer.add @bottom_camera
	@state_viewer.add @sonar
	@state_viewer.add @sonar_feature_estimator
	@state_viewer.add @sonar_rear
        @state_viewer.add @depth
        @state_viewer.add @state_estimator
        @state_viewer.add @hbridge
	@state_viewer.add @controlconverter
	@state_viewer.add @auv_rel_pos_controller
        @state_viewer.add @offshore_pipeline_detector
        @state_viewer.add @buoy_detector
        @state_viewer.add @wall_servoing
        @state_viewer.setParent(@window.top)
        @window.top.layout.insertWidget 0,@state_viewer

     #   @state_layout.addWidget @state_viewer
     #   @window.container_left.setLayout @state_layout
       # @state_viewer.show
        

        #add lines for pipeline overlay
        @line1 = @window.bottom_camera.addLine(0,0,1,Qt::Color.new(0,0,255),0,0);
        @line2 = @window.bottom_camera.addLine(0,0,1,Qt::Color.new(0,0,255),0,0);
        @line3 = @window.bottom_camera.addLine(0,0,1,Qt::Color.new(255,0,0),0,0);
        @line4 = @window.bottom_camera.addLine(0,0,1,Qt::Color.new(255,0,0),0,0);
        @line1.openGL true
        @line2.openGL true
        @line3.openGL true
        @line4.openGL true


        # Disable currently unused widgets
        @window.range_view.set_visible false
        @window.sonar_view.set_visible false

        #conncet ports
        #Vizkit.connect_port_to @profiling, 'Scan', @window.range_view,:pull => true
        #Vizkit.connect_port_to @sonar, 'BaseScan', @window.sonar_view,:pull => true
        Vizkit.connect_port_to @front_camera, 'frame', @window.front_camera,:pull => true
        Vizkit.connect_port_to @bottom_camera, 'frame', @window.bottom_camera,:pull => true
        Vizkit.connect_port_to @state_estimator, 'orientation_samples', @window.orientation

        #    @pen.setColor(Qt::Color.new(255,0,0))
        #    @pen.setWidth(1)
        #    @window.depth_plot.fitPlotToGraph() 
        #    @window.depth_plot.registerCurve(2,@pen,"depth",1)

        Vizkit.connect_port_to @depth,"depth_samples" do |data,_|
            @window.depth.display sprintf("%2.1f",data.position[2]) if data
            data
        end

        Vizkit.connect_port_to @sonar_rear,"ground_distance" do |data,_|
            @window.altitude.display sprintf("%2.1f",data.position[2]) if data
            data
        end

        Vizkit.connect_port_to @controlconverter,"motion_command" do |data,_|
            @window.desired_heading.display sprintf("%2.1f",data.heading/Math::PI*180) if data
            @window.desired_depth.display sprintf("%2.1f",data.z) if data
            data
        end

        @window.front_camera_on.connect(SIGNAL('clicked(bool)')) do |value|
            if value
                Vizkit.connect_port_to @front_camera, 'frame_normalized', @window.front_camera,:pull => true
            else
                Vizkit.disconnect_from @window.front_camera
            end
        end

        @window.bottom_camera_on.connect(SIGNAL('clicked(bool)')) do |value|
            if value
                Vizkit.connect_port_to @bottom_camera, 'frame', @window.bottom_camera,:pull => true
            else
                Vizkit.disconnect_from @window.bottom_camera
            end
        end

        #draw pipeline overlay 
        @window.pipeline_on.connect(SIGNAL('clicked(bool)')) do |value|
            if value

                # Pipeline detector view
                Vizkit.connect_port_to @offshore_pipeline_detector, 'debug_frame', @window.pipeline_view,:pull => true

                # Camera image overlay
                if !@pipeline_connection
                    @pipeline_connection = Vizkit.connect_port_to @offshore_pipeline_detector, 'pipeline', :pull => true do |sample,_|
                        center_x = @window.bottom_camera.getWidth()/2
                        center_y = @window.bottom_camera.getHeight()/2
                        image_height = @window.bottom_camera.getHeight()

                        if sample.accepted
                            #update image overlay
                            x = sample.x + sample.width*Math.cos(sample.angle)*0.5+center_x
                            y = sample.y - sample.width*Math.sin(sample.angle)*0.5+center_y 
                            @line1.setPosX(x - image_height*Math.sin(sample.angle))
                            @line1.setPosY(y - image_height*Math.cos(sample.angle))
                            @line1.setEndX(x + image_height*Math.sin(sample.angle))
                            @line1.setEndY(y + image_height*Math.cos(sample.angle))

                            x = sample.x- sample.width*Math.cos(sample.angle)*0.5+center_x
                            y = sample.y+ sample.width*Math.sin(sample.angle)*0.5+center_y 
                            @line2.setPosX(x + image_height*Math.sin(sample.angle))
                            @line2.setPosY(y + image_height*Math.cos(sample.angle))
                            @line2.setEndX(x - image_height*Math.sin(sample.angle))
                            @line2.setEndY(y - image_height*Math.cos(sample.angle))

                          #  @line4.setPosX(sample.x + center_x)
                          #  @line4.setPosY(sample.y + center_y)
                          #  @line4.setEndX(sample.gap_pos_x + center_x)
                          #  @line4.setEndY(sample.gap_pos_y + center_y)

                            @line3.setPosX(0)
                            @line3.setPosY(0)
                            @line3.setEndX(0)
                            @line3.setEndY(0)
                        else
                            disable_overlay
                        end
                        @window.bottom_camera.update2
                    end
                else
                    @pipeline_connection.reconnect
                end
            else
                # Pipeline detector view
                @window.pipeline_view.disconnect

                # Camera image overlay
                @pipeline_connection.disconnect if @pipeline_connection
                disable_overlay
                @window.bottom_camera.update2
            end
        end
    end

    def disable_overlay
        @line1.setPosX(0)
        @line1.setPosY(0)
        @line1.setEndX(0)
        @line1.setEndY(0)
        @line2.setPosX(0)
        @line2.setPosY(0)
        @line2.setEndX(0)
        @line2.setEndY(0)
        @line3.setPosX(0)
        @line3.setPosY(0)
        @line3.setEndX(0)
        @line3.setEndY(0)
        @line4.setPosX(0)
        @line4.setPosY(0)
        @line4.setEndX(0)
        @line4.setEndY(0)
    end

    def show
        @window.show
    end
end

