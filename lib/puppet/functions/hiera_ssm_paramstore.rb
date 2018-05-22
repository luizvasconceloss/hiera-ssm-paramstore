Puppet::Functions.create_function(:hiera_ssm_paramstore) do
  begin
    require 'aws-sdk-ssm'
  rescue LoadError => e
    raise Puppet::DataBinding::LookupError, "Must install gem aws-sdk-ssm to use hiera_ssm_paramstore"
  end

  dispatch :lookup_key do
    param 'Variant[String, Numeric]', :key
    param 'Hash', :options
    param 'Puppet::LookupContext', :context
  end

  def lookup_key(key, options, context)
    ssmclient = ssm_get_connection(options)
    key_path = context.interpolate(options['uri'] + key)

    if options['get_all']
      get_all_parameters(options, context, ssmclient)
      if context.cache_has_key(key)
        context.explain { "Returning value for key #{key}" }
        return context.cached_value(key)
      elsif context.cache_has_key(key_path)
        context.explain { "Returning value for #{key}" }
        return context.cached_value(key_path)
      else
        context.explain { "Key #{key} not found" }
        return context.not_found
      end
    else
      result = paramstore_get(key, options, context, ssmclient)
      return result
    end
  end

  def ssm_get_connection(options)
    begin
      if options['region'].nil?
        Aws::SSM::Client.new()
      else
        Aws::SSM::Client.new(region: options['region'])
      end
    rescue Aws::SSM::Errors::ServiceError => e
      raise Puppet::DataBinding::LookupError, "Fail to connect to aws ssm #{e.message}"
    end
  end

  def get_all_parameters(options, context, ssmclient)
    token = nil
    options['recursive'] ||= false

    loop do
      begin
        context.explain { "Getting keys on #{options['uri']} ..." }
        data = ssmclient.get_parameters_by_path({
          path: options['uri'],
          recursive: options['recursive'],
          with_decryption: true,
          next_token: token
        })
        context.explain { "Adding keys on cache ..." }
        data['parameters'].each do |k|
          context.cache(k['name'], k['value'])
        end

        break if (data.next_token.nil?)
        token = data.next_token
      rescue Aws::SSM::Errors::ServiceError => e
        raise Puppet::DataBinding::LookupError, "AWS SSM Service error #{e.message}"
      end
    end


  end

  def paramstore_get(key, options, context, ssmclient)
    key_path = context.interpolate(options['uri'] + key)

    if context.cache_has_key(key_path)
      context.explain { "Returning cached value for #{key_path}" }
      return context.cached_value(key_path)
    else
      context.explain {"Looking for #{key_path}"}

      begin
        resp = ssmclient.get_parameters({
          names: [key_path],
          with_decryption: true
        })
        if !resp.parameters.empty?
          value = resp.parameters[0].value
          context.cache(key_path, value)
          return value
        else
          context.explain { "Key #{key_path} not found" }
          context.not_found
        end
      rescue Aws::SSM::Errors::ServiceError => e
        raise Puppet::DataBinding::LookupError, "AWS SSM Service error #{e.message}"
      end
    end
  end
end
