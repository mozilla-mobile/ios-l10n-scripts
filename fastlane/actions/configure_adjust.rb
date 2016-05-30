module Fastlane
  module Actions
    module SharedValues
      CONFIGURE_ADJUST_CUSTOM_VALUE = :CONFIGURE_ADJUST_CUSTOM_VALUE
    end

    # To share this integration with the other fastlane users:
    # - Fork https://github.com/fastlane/fastlane
    # - Clone the forked repository
    # - Move this integration into lib/fastlane/actions
    # - Commit, push and submit the pull request

    class ConfigureAdjustAction < Action
      def self.run(params)
        Helper.log.info "Configuring Adjust for:"
        Helper.log.info "  Config:      #{params[:config]} "
        Helper.log.info "  Environment: #{params[:environment]} "
        Helper.log.info "  App Token:   #{params[:app_token]} "

        environmentKey = "ADJUST_ENVIRONMENT"
        appTokenKey = "ADJUST_APP_TOKEN"

        # TODO(sleroux):  Ugh, regex. Replace with .xcconfig file parser if I can find one.
        environmentRegex = "\\(^#{environmentKey}.*\\)"
        appTokenRegex = "\\(^#{appTokenKey}.*\\)"

        xcconfigFilename = "Client/Configuration/#{params[:config]}.xcconfig"

        sh("sed -i '' 's/#{environmentRegex}/#{environmentKey} = #{params[:environment]}/g' #{xcconfigFilename}")
        sh("sed -i '' 's/#{appTokenRegex}/#{appTokenKey} = #{params[:app_token]}/g' #{xcconfigFilename}")
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Updates the provided .xcconfig file with the Adjust environment and API credentials"
      end

      def self.details
        "Updates the provided .xcconfig file with the Adjust environment and API credentials. For example,"\
        "when configuring Adjust for production builds you will want to use the Firefox.xcconfig with"\
        "environment set to production and the associated API key"
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :config,
                                       env_name: "FL_CONFIGURE_ADJUST_CONFIG_NAME", # The name of the environment variable
                                       description: "Name of the .xcconfig to configure Adjust with", # a short description of this parameter),
                                       is_string: true,
                                       optional: false
                                       ),
          FastlaneCore::ConfigItem.new(key: :environment,
                                       env_name: "FL_CONFIGURE_ADJUST_ENVIRONMENT_NAME",
                                       description: "The Adjust environment to set. Either sandbox or production",
                                       is_string: true, # true: verifies the input is a string, false: every kind of value
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :app_token,
                                       env_name: "FL_CONFIGURE_ADJUST_APP_TOKEN",
                                       description: "The Adjust App Token",
                                       is_string: true, # true: verifies the input is a string, false: every kind of value
                                       optional: false)
        ]
      end

      def self.output
      end

      def self.return_value
        # If you method provides a return value, you can describe here what it does
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["mozilla"]
      end

      def self.is_supported?(platform)
        # you can do things like
        #
        #  true
        #
        #  platform == :ios
        #
        #  [:ios, :mac].include?(platform)
        #

        platform == :ios
      end
    end
  end
end
