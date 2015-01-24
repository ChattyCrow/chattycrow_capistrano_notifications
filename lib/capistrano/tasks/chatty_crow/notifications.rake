require 'chattycrow'

module Capistrano
  module ChattyCrow
    module Notifications
      class << self
        attr_accessor :options

        def deploy_started
          send_cc "deploy"
        end

        def deploy_completed
          send_cc "deploy", true
        end

        def rollback_started
          send_cc "deploy:rollback"
        end

        def rollback_completed
          send_cc "deploy:rollback", true
        end

        private

        def git_log_revisions
          current, real = options[:current_revision][0,7], options[:previous_revision]

          if current == real
            "GIT: No changes ..."
          else
            if (diff = `git log #{real}..#{current} --pretty=format:"%h%x09%an%x09%ad%x09%s"`) != ""
              diff = "  " << diff.gsub("\n", "\n    ") << "\n"
            else
              "GIT: Git-log problem ..."
            end
          end
        end

        def normal_log(action, completed)
          msg = []
          msg << "#{completed ? 'Completed' : 'Started'} #{action} on #{options[:stage]} by #{username}"
          msg << "Time: #{Time.now.to_s}"
          msg << "Application: #{options[:application]}"
          msg << "Branch: #{options[:branch]}"
          msg << "\nGit changes:\n" + git_log_revisions if options[:source].to_sym == :git
          msg.join("\r\n")
        end

        def create_message(action, completed, type, settings)
          case type
          when :slack
            if action.to_sym == :deploy
              color = completed ? :good : :warning
            else
              color = :danger
            end

            # Return
            payload = {
              icon: ':floppy_disk:',
              body: "#{completed ? 'Completed' : 'Started'} #{action} #{options[:application]} on #{options[:stage]}:",
              attachments: [
                color: color,
                fallback: "Author: #{username}, Branch: #{options[:branch]}, Time: #{Time.now.to_s}",
                fields: [
                  { title: 'Author', value: username, short: true },
                  { title: 'Branch', value: options[:branch], short: true },
                  { title: 'Time', value: Time.now.to_s, short: true },
                  { title: 'Stage', value: options[:stage], short: true },
                  { title: 'Changes', value: git_log_revisions }
                ]
              ]
            }
            settings.dup.merge(payload)
          when :hipchat
            if action.to_sym == :deploy
              color = completed ? :green : :yellow
            else
              color = :red
            end

            payload = {
              body: normal_log(action, completed),
              notify: true,
              color: color
            }
            settings.dup.merge(payload)
          else
            normal_log(action, completed)
          end
        end

        def send_cc(action, completed = false)
          # Prepare batches
          ::ChattyCrow.configure do |config|
            config.host = options[:host]
            config.token = options[:token]
          end

          # Create batch
          batch = ::ChattyCrow.create_batch(options[:token])

          # Iterate over services
          options[:services].each do |type, settings|
            message = create_message(action, completed, type, settings)

            if message.is_a?(String)
              batch.send("add_#{type}", message, settings.dup)
            else
              batch.send("add_#{type}", message)
            end
          end

          # Execute!
          response = batch.execute!

          puts "REsponse: #{response.channels}"
          true
        end

        def username
          @username ||= [`whoami`, `hostname`].map(&:strip).join('@')
        end
      end
    end
  end
end

set :current_revision, lambda { `git rev-parse #{fetch :branch}`.chomp }

namespace :deploy do
  namespace :chatty_crow do
    %w(deploy_started deploy_completed rollback_started rollback_completed).each do |m|


      task m.to_sym do
        # Run only once!
        unless fetch(:revision)
          on roles(:app, :web) do |host|
            within current_path do
              set :revision, capture(:cat, "REVISION")
            end
          end
        end

        Capistrano::ChattyCrow::Notifications.options = {
          host:     fetch(:chattycrow_host),
          token:     fetch(:chattycrow_token),
          services: fetch(:chattycrow_services),
          action: m.to_sym,
          branch: fetch(:branch),
          application: fetch(:application),
          stage: fetch(:stage),
          source: fetch(:scm),
          current_revision: fetch(:current_revision),
          previous_revision: fetch(:revision)
        }

        Capistrano::ChattyCrow::Notifications.send m
      end
    end
  end

  # Deploy tasks
  before 'deploy', 'deploy:chatty_crow:deploy_started'
  after  'deploy', 'deploy:chatty_crow:deploy_completed'
  before 'deploy:rollback', 'deploy:chatty_crow:rollback_started'
  after  'deploy:rollback', 'deploy:chatty_crow:rollback_completed'
end

