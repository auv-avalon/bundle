class UwParticleLocalization::Task
#    provides Srv::PoseEstimator
    provides Srv::Pose

    def configure
        super

        autoproj = ENV['AUTOPROJ_CURRENT_ROOT']

        map = "nurc.yml"

        orogen_task.yaml_map = File.join(autoproj, "supervision", "maps", map)
    end
end
