class FrameDemultiplexer::FrameDemultiplexerTask
    provides DServ::ImageSource
    provides DServ::LaserImagePairSource

    def configure
	orogen_task.used_sequences = State.config.demultiplexer_drop_rate
    end
end

composition 'laser_image_demultiplexer' do
    add DServ::ImageSource, :as => 'multiplexed_images'
    demultiplexer = add FrameDemultiplexer::FrameDemultiplexerTask, :as => 'demux'
    autoconnect

    export demultiplexer.oframe, :as => 'frame'
    export demultiplexer.oframe_pair, :as => 'laser_frame_pairs'

    provides DServ::ImageSource, :as => 'images'
    provides DServ::LaserImagePairSource, :as => 'laser_images'
end

