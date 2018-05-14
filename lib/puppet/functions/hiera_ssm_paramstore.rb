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
    result = paramstore_get(key, options, context)
  end

  def paramstore_get(key, options, context)
    key_path = context.interpolate(options['uri'] + key)

    if context.cache_has_key(key_path)
      context.explain { "Returning cached value for #{key_path}" }
      return context.cached_value(key_path)
    else
      context.explain {"Looking for #{key_path}"}

      if options['region'].nil?
        ssm = Aws::SSM::Client.new()
      else
        ssm = Aws::SSM::Client.new(region: options['region'])
      end

      begin
        describe = ssm.describe_parameters({filters: [{key: "Name", values: [key_path]},],})
        if describe.parameters[0].nil?
          return context.not_found
        else
          begin
            resp = ssm.get_parameters({
              names: [key_path],
              with_decryption: true
            })
            value = resp.parameters[0].value
            context.cache(key_path, value)
            return value
          rescue Aws::SSM::Errors::ServiceError => e
            raise Puppet::DataBinding::LookupError, "AWS SSM Service error #{e.message}"
          end
        end
      rescue Aws::SSM::Errors::ServiceError => e
        raise Puppet::DataBinding::LookupError, "AWS SSM Service error #{e.message}"
      end
    end
  end
end
