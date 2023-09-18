# frozen_string_literal: true

require 'bbb_lti_broker/helpers'

namespace :db do
  namespace :tenants do
    namespace :settings do
      desc 'Show all settings for a tenant. If no id is specified, settings for all tenants will be shown'
      task :showall, [:uid] => :environment do |_t, args|
        tenant_id = args[:uid] || ''

        if tenant_id.present?
          tenant = RailsLti2Provider::Tenant.find_by(uid: tenant_id)
          if tenant.nil?
            puts("Tenant '#{tenant_id}' does not exist.")
            exit(1)
          end

          puts("Settings for tenant #{tenant_id}: \n #{tenant.settings}")
        else
          tenants = RailsLti2Provider::Tenant.all
          tenants_list = tenants.map do |t|
            {
              tenant: t.uid,
              settings: t.settings,
            }
          end
          puts(tenants_list)
        end
      end

      desc 'Add a new tenant setting'
      task :upsert, [:uid, :key, :value] => :environment do |_t, args|
        tenant_id = args[:uid] || ''
        key = args[:key]
        value = args[:value]

        unless key.present? && value.present?
          puts('Error: key and value are required to create a tenant setting')
          exit(1)
        end

        tenant = RailsLti2Provider::Tenant.find_by(uid: tenant_id)
        if tenant.nil?
          puts("Tenant '#{tenant_id}' does not exist.")
          exit(1)
        end

        # Add the setting
        tenant.settings[key] = value
        tenant.save!

        puts("Added setting #{key}=#{value} to tenant #{tenant_id}")
      rescue StandardError => e
        puts(e.backtrace)
        exit(1)
      end

      desc 'Delete a setting'
      task :delete, [:uid, :key] => :environment do |_t, args|
        tenant_id = args[:uid] || ''
        key = args[:key]

        if key.blank?
          puts('Error: The setting key is required to delete a tenant setting')
          exit(1)
        end

        tenant = RailsLti2Provider::Tenant.find_by(uid: tenant_id)
        if tenant.nil?
          puts("Tenant '#{tenant_id}' does not exist.")
          exit(1)
        end

        puts("Key '#{key}' not found for tenant #{tenant}") unless tenant.settings[key]

        tenant.settings.delete(key)
        tenant.save!

        puts("Setting #{key} for tenant '#{tenant_id}' has been deleted")
      rescue StandardError => e
        puts(e.backtrace)
        exit(1)
      end

      desc 'Add BBB credentials'
      task :add_bbb_credentials, [:uid, :bigbluebutton_url, :bigbluebutton_secret] => :environment do |_t, args|
        tenant_id = args[:uid] || ''
        bigbluebutton_url = args[:bigbluebutton_url]
        bigbluebutton_secret = args[:bigbluebutton_secret]

        if bigbluebutton_url.blank? || bigbluebutton_secret.blank?
          puts('Error: Both bigbluebutton url and secret are required')
          exit(1)
        end

        tenant = RailsLti2Provider::Tenant.find_by(uid: tenant_id)

        if tenant.nil?
          puts("Tenant '#{tenant_id}' does not exist.")
          exit(1)
        end

        tenant.settings['bigbluebutton_url'] = bigbluebutton_url
        tenant.settings['bigbluebutton_secret'] = bigbluebutton_secret
        tenant.save!

        puts("Added the following BBB credentials to tenant #{tenant_id}:")
        puts("bigbluebutton_url = #{bigbluebutton_url}")
        puts("bigbluebutton_secret = #{bigbluebutton_secret}")
      rescue StandardError => e
        puts(e.backtrace)
        exit(1)
      end

      desc 'Add params to forward to BBB on create'
      task :forward_param_create, [:uid, :param] => :environment do |_t, args|
        tenant_id = args[:uid] || ''
        param = args[:param]

        if param.blank?
          puts('Please specify a parameter')
          exit(1)
        end

        tenant = RailsLti2Provider::Tenant.find_by(uid: tenant_id)

        if tenant.nil?
          puts("Tenant '#{tenant_id}' does not exist.")
          exit(1)
        end

        forward_params_key = 'forward_params_create'

        if tenant.settings.key?(forward_params_key)
          tenant.settings[forward_params_key] << param unless tenant.settings[forward_params_key].include?(param)
        else
          tenant.settings[forward_params_key] = [param]
        end

        tenant.save!

        puts("Params to be forwarded for tenant on create #{tenant_id}:")
        puts(tenant.settings[forward_params_key])
      rescue StandardError => e
        puts(e.backtrace)
        exit(1)
      end

      desc 'Add params to forward to BBB on join'
      task :forward_param_join, [:uid, :param] => :environment do |_t, args|
        tenant_id = args[:uid] || ''
        param = args[:param]

        if param.blank?
          puts('Please specify a parameter')
          exit(1)
        end

        tenant = RailsLti2Provider::Tenant.find_by(uid: tenant_id)

        if tenant.nil?
          puts("Tenant '#{tenant_id}' does not exist.")
          exit(1)
        end

        forward_params_key = 'forward_params_join'

        if tenant.settings.key?(forward_params_key)
          tenant.settings[forward_params_key] << param unless tenant.settings[forward_params_key].include?(param)
        else
          tenant.settings[forward_params_key] = [param]
        end

        tenant.save!

        puts("Params to be forwarded for tenant on join #{tenant_id}:")
        puts(tenant.settings[forward_params_key])
      rescue StandardError => e
        puts(e.backtrace)
        exit(1)
      end

      desc 'Delete a param that is forwarded on create'
      task :delete_forward_param_create, [:uid, :param] => :environment do |_t, args|
        tenant_id = args[:uid] || ''
        param = args[:param]

        if param.blank?
          puts('Please specify a parameter')
          exit(1)
        end

        tenant = RailsLti2Provider::Tenant.find_by(uid: tenant_id)

        if tenant.nil?
          puts("Tenant '#{tenant_id}' does not exist.")
          exit(1)
        end

        forward_params_key = 'forward_params_create'

        if !tenant.settings.key?(forward_params_key) || !tenant.settings[forward_params_key].include?(param)
          puts("Param does not exist for tenant #{tenant_id}")
          exit(1)
        else
          tenant.settings[forward_params_key].delete(param)
        end

        tenant.save!

        puts("Successfully deleted param '#{param}' for tenant #{tenant_id}:")
        puts(tenant.settings[forward_params_key])
      rescue StandardError => e
        puts(e.backtrace)
        exit(1)
      end

      desc 'Delete a param that is forwarded on join'
      task :delete_forward_param_join, [:uid, :param] => :environment do |_t, args|
        tenant_id = args[:uid] || ''
        param = args[:param]

        if param.blank?
          puts('Please specify a parameter')
          exit(1)
        end

        tenant = RailsLti2Provider::Tenant.find_by(uid: tenant_id)

        if tenant.nil?
          puts("Tenant '#{tenant_id}' does not exist.")
          exit(1)
        end

        forward_params_key = 'forward_params_join'

        if !tenant.settings.key?(forward_params_key) || !tenant.settings[forward_params_key].include?(param)
          puts("Param does not exist for tenant #{tenant_id}")
          exit(1)
        else
          tenant.settings[forward_params_key].delete(param)
        end

        tenant.save!

        puts("Successfully deleted param '#{param}' for tenant #{tenant_id}:")
        puts(tenant.settings[forward_params_key])
      rescue StandardError => e
        puts(e.backtrace)
        exit(1)
      end
    end
  end
end
