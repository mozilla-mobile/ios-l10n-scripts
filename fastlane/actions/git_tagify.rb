module Fastlane
  module Actions
    module SharedValues
      CONFIGURE_GIT_TAGIFY_CUSTOM_VALUE = :CONFIGURE_GIT_TAGIFY_CUSTOM_VALUE
    end

    class GitTagifyAction < Action
      def self.run(params)
        # Remember which branch we started from
        old_branch = sh("git rev-parse --abbrev-ref HEAD")

        # Create a temp branch to add our files to
        sh("git checkout -b temp_#{params[:tag_name]}")

        # Force add our Carthage dependencies
        sh("git add -f Carthage")

        # Add everything else
        sh("git add .")

        sh("git commit -m '#{params[:tag_name]} Release Snapshot'")

        # Tag everything up
        sh("git tag #{params[:tag_name]}")

        # Restore original branch
        sh("git checkout #{old_branch}")

        # Push newly created tag
        sh("git push origin #{params[:tag_name]}")
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Checks out a temporary branch, adds all unchecked files and produces a tag to push to Github."
      end

      def self.details
        "This action will checkout a new branch named after the tag, add all uncommited files to Git, then produce "\
        "a tag which is pushed to Github. Afterwards, the branch is deleted and the user is restored to the original "\
        "branch they were on. This allows tags to contains a snapshot of all dependencies for a particular build without "
        "producing commits on release branches with the additional work done by Fastlane."
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :tag_name,
                                       env_name: "FL_GIT_TAGIFY_TAG_NAME",
                                       description: "Name of tag to create and push to Github",
                                       is_string: true,
                                       optional: false
                                       )
        ]
      end

      def self.output
      end

      def self.return_value
      end

      def self.authors
        ["mozilla"]
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
