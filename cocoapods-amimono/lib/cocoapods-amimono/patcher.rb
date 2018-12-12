require 'cocoapods/installer'
require 'cocoapods-amimono/xcconfig_updater'

module Amimono
  # This class will patch your project's copy resources script to match the one that would be
  # generated as if the `use_frameworks!` flag wouldn't be there
  class Patcher

    def self.patch!(installer)
      patch_xcconfig_files(installer)
      patch_copy_resources_script(installer)
      patch_vendored_build_settings(installer)
    end

    private

    def self.patch_xcconfig_files(installer)
      aggregated_targets = installer.aggregate_targets.reject { |target| target.label.include? 'Test' }
        .reject { |target| installer.podfile.amimono_ignore.include? target.label }
      updater = XCConfigUpdater.new(installer)
      aggregated_targets.each do |aggregated_target|
        puts "[Amimono] Pods target found: #{aggregated_target.label}"
        target_support = installer.sandbox.target_support_files_dir(aggregated_target.label)
        updater.update_xcconfigs(aggregated_target, target_support)
        puts "[Amimono] xcconfigs updated with filelist for target #{aggregated_target.label}"
      end
    end

    def self.patch_vendored_build_settings(installer)
      aggregated_targets = installer.aggregate_targets.reject { |target| target.label.include? 'Test' }
        .reject { |target| installer.podfile.amimono_ignore.include? target.label }
      aggregated_targets.each do |aggregated_target|
        path = installer.sandbox.target_support_files_dir aggregated_target.label
        Dir.entries(path).select { |entry| entry.end_with? 'xcconfig' }.each do |entry|
          full_path = path + entry
          xcconfig = Xcodeproj::Config.new full_path
          # Another option would be to inspect installer.analysis_result.result.target_inspections
          # But this also works and it's simpler
          configuration = entry.split('.')[-2]
          pod_targets = aggregated_target.pod_targets_for_build_configuration configuration
          generate_vendored_build_settings(aggregated_target, pod_targets, xcconfig)
          xcconfig.save_as full_path
        end
        puts "[Amimono] Vendored build settings patched for target #{aggregated_target.label}"
      end
    end

    def self.patch_copy_resources_script(installer)
      project = installer.sandbox.project
      aggregated_targets = installer.aggregate_targets.reject { |target| target.label.include? 'Test' }
        .reject { |target| installer.podfile.amimono_ignore.include? target.label }
      aggregated_targets.each do |aggregated_target|
        path = aggregated_target.copy_resources_script_path
        resources = resources_by_config(aggregated_target, project)
        generator = Pod::Generator::CopyResourcesScript.new(resources, aggregated_target.platform)
        generator.save_as(path)
        puts "[Amimono] Copy resources script patched for target #{aggregated_target.label}"
      end
    end

    # Copied over from https://github.com/CocoaPods/CocoaPods/blob/2fa648221b6548e941116f5e146361ba557bbed0/lib/cocoapods/generator/xcconfig/aggregate_xcconfig.rb#L183-L191
    # with some modifications to this particular use case
    def self.generate_vendored_build_settings(aggregated_target, pod_targets, xcconfig)
        targets = pod_targets + aggregated_target.search_paths_aggregate_targets.flat_map(&:pod_targets)

        targets.each do |pod_target|
            Pod::Generator::XCConfig::XCConfigHelper.add_settings_for_file_accessors_of_target(aggregated_target, pod_target, xcconfig)
        end
    end

    # Copied over from https://github.com/CocoaPods/CocoaPods/blob/master/lib/cocoapods/installer/xcode/pods_project_generator/aggregate_target_installer.rb#L115-L131
    # with some modifications to this particular use case
    def self.resources_by_config(aggregated_target, project)
      aggregated_target.user_build_configurations.keys.each_with_object({}) do |config, resources_by_config|
        resources_by_config[config] = aggregated_target.pod_targets.flat_map do |library_target|
          next [] unless library_target.include_in_build_config?(aggregated_target.target_definition, config)
          resource_paths = library_target.file_accessors.flat_map do |accessor|
            accessor.resources.flat_map { |res| res.relative_path_from(project.path.dirname) }
          end
          resource_bundles = library_target.file_accessors.flat_map do |accessor|
            accessor.resource_bundles.keys.map { |name| "#{library_target.configuration_build_dir}/#{name.shellescape}.bundle" }
          end
          # The `bridge_support_file` has been removed from this part
          (resource_paths + resource_bundles).uniq
        end
      end
    end
  end
end
