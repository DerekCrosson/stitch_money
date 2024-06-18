require 'faraday'
require 'faraday/typhoeus'
require 'json'

module StitchMoney
  class Client
    API_BASE_URL = 'https://api.stitch.money/graphql'

    def initialize(api_key)
      @api_key = api_key
      @connection = Faraday.new(url: API_BASE_URL) do |faraday|
        faraday.adapter :typhoeus
        faraday.headers['Authorization'] = "Bearer #{@api_key}"
        faraday.headers['Content-Type'] = 'application/json'
      end
    end

    def get_payment_request_status(payment_request_id)
      query = <<~GRAPHQL
        query GetPaymentRequestStatus($paymentRequestId: ID!) {
          node(id: $paymentRequestId) {
            ... on PaymentInitiationRequest {
              id
              payerReference
              beneficiaryReference
              url
              state {
                __typename
                ... on PaymentInitiationRequestCompleted {
                  date
                  amount {
                    quantity
                    currency
                  }
                  payer {
                    ... on PaymentInitiationBankAccountPayer {
                      accountNumber
                      bankId
                    }
                  }
                }
                ... on PaymentInitiationRequestCancelled {
                  date
                  reason
                }
                ... on PaymentInitiationRequestPending {
                  __typename
                  paymentInitiationRequest {
                    id
                  }
                }
                ... on PaymentInitiationRequestExpired {
                  __typename
                  date
                }
              }
            }
          }
        }
      GRAPHQL

      variables = { paymentRequestId: payment_request_id }
      graphql_query(query, variables)
    end

    def graphql_query(query, variables = {})
      response = @connection.post do |req|
        req.url API_BASE_URL
        req.headers['Content-Type'] = 'application/json'
        req.body = { query: query, variables: variables }.to_json
      end
      parse_response(response)
    end

    private

    def parse_response(response)
      case response.status
      when 200..299
        JSON.parse(response.body)
      else
        { error: response.reason_phrase, code: response.status }
      end
    end
  end
end
