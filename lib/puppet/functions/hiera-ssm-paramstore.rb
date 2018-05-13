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
    result = paramstore_get(key, context, options)
    value = result.parameters[0].value
    if value.nil?
      context.not_found
    else
      return value
    end
  end

  def paramstore_get(key, context, options)
    key_path = context.interpolate(options['uri']) + key

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

      describe = ssm.describe_parameters({filters: [{key: "Name", values: [key_path]},],})

      if describe.parameters[0].nil?
        context.not_found
      else
        begin
          resp = ssm.get_parameters({
            names: [key_path],
            with_decryption: true
          })
          context.cache(key_path, resp)
          return resp
        rescue Aws::SSM::Errors::ServiceError => e
          raise Puppet::DataBinding::LookupError, "AWS SSM Service error #{e.message}"
        end
      end
    end
  end
end
