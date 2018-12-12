require 'cocoapods-amimono/command'
require 'cocoapods-amimono/build_phases_updater'


module Pod
  class Podfile

    module DSL
      def amimono_ignore(name = nil)
        if name.nil?
            return @amimono_ignored
        end

        unless instance_variable_defined? :@amimono_ignored
            @amimono_ignored = []
        end
        @amimono_ignored.push(name)
      end

    end 
  end
end

podfile = nil
Pod::HooksManager.register('cocoapods-amimono', :pre_install) do |installer_context|
  podfile = installer_context.podfile
end

Pod::HooksManager.register('cocoapods-amimono', :post_install) do |installer_context|
  # We exclude all targets that contain `Test`, which might not work for some test targets
  # that doesn't include that word
  pods_targets = installer_context.umbrella_targets.reject { |target| target.cocoapods_target_label.include? 'Test' }
    .reject { |target| podfile.amimono_ignore.include? target.cocoapods_target_label }

  updater = Amimono::BuildPhasesUpdater.new
  updater.update_build_phases(installer_context, pods_targets)
end
