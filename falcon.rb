#!/usr/bin/env -S falcon host
# frozen_string_literal: true

load :rack, :lets_encrypt_tls, :supervisor

hostname = File.basename(__dir__)
rack hostname do
	# cache true
  endpoint(
    Async::HTTP::Endpoint
      .parse('http://0.0.0.0:9090')
      .with(protocol: Async::HTTP::Protocol::HTTP11)
  )
end

supervisor
