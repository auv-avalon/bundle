class UwParticleLocalization::Task
    def configure
        super

        autoproj = ENV['AUTOPROJ_PROJECT_BASE']

        map = "studiobad.yml"

        orogen_task.yaml_map = File.join(autoproj, "supervision", "maps", map)
    end
end
