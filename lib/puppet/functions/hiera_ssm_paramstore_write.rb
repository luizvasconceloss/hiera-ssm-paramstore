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
    ssmclient = ssm_get_connection(options)

    put_parameter(key_path, value, options, ssmclient)
    # Fetch the newly created item. This both tests the creation and yields the result
    # in the expected format.
    get_parameter(key_path, ssmclient)
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

  def put_parameter(key_path, value, options, ssmclient)
    put_options = { name: key_path,
                    description: 'Added by hiera_ssm_paramstore_write',
                    value: value,
                    type: 'String',
                    tags: [
                      {
                        key: 'CreatedBy',
                        value: 'puppet',
                      },
                    ] }
    put_options = put_options.merge(options['put']) if options['put']

    begin
      ssmclient.put_parameter(put_options)
    rescue Aws::SSM::Errors::ServiceError => e
      raise Puppet::DataBinding::LookupError, "AWS SSM Service error #{e.message}"
    end
  end

  def get_parameter(key_path, ssmclient)
    resp = ssmclient.get_parameters(names: [key_path],
                                    with_decryption: true)

    return nil if resp.parameters.empty?
    resp.parameters[0].value
  rescue Aws::SSM::Errors::ServiceError => e
    raise Puppet::DataBinding::LookupError, "AWS SSM Service error #{e.message}"
  end
end
