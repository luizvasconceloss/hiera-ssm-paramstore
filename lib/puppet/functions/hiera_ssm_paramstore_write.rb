Puppet::Functions.create_function(:hiera_ssm_paramstore_write) do
  begin
    require 'aws-sdk-ssm'
  rescue LoadError
    raise Puppet::DataBinding::LookupError, 'Must install gem aws-sdk-ssm to use hiera_ssm_paramstore'
  end

  dispatch :write_key do
    param 'Variant[String, Numeric]', :key
    param 'Variant[String, Numeric]', :value
    param 'Hash', :options
  end

  def write_key(key, value, options)
    key_path = options['uri'] + key.gsub('::', '/')

    put_parameter(key_path, value, options)
    # Fetch the newly created item. This both tests the creation and yields the result
    # in the expected format.
    result = get_parameter(key_path, options)
    return result
  end

  def ssm_get_connection(options)
    if options['region'].nil?
      Aws::SSM::Client.new
    else
      Aws::SSM::Client.new(region: options['region'])
    end
  rescue Aws::SSM::Errors::ServiceError => e
    raise Puppet::DataBinding::LookupError, "Fail to connect to aws ssm #{e.message}"
  end

  def put_parameter(key_path, value, options)
    ssmclient = ssm_get_connection(options)
    put_options = { name: key_path,
                    description: 'Added by hiera_ssm_paramstore_write',
                    value: value,
                    tags: [
                      {
                        key: "CreatedBy",
                        value: "puppet",
                      },
                    ],
    }
    put_options = put_options.merge(options['put']) if options['put']

    begin
      resp = ssmclient.put_parameter(put_options)
    rescue Aws::SSM::Errors::ServiceError => e
      raise Puppet::DataBinding::LookupError, "AWS SSM Service error #{e.message}"
    end
  end

  def get_parameter(key_path, options)
    ssmclient = ssm_get_connection(options)

    begin
      resp = ssmclient.get_parameters(names: [key_path],
                                      with_decryption: true)
      if !resp.parameters.empty?
        value = resp.parameters[0].value
        return value
      else
        return nil
      end
    rescue Aws::SSM::Errors::ServiceError => e
      raise Puppet::DataBinding::LookupError, "AWS SSM Service error #{e.message}"
    end
  end
end
