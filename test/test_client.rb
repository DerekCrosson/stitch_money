require "minitest/autorun"
require "webmock/minitest"
require "stitch_money/client"

class TestStitchMoneyClient < Minitest::Test
  def setup
    @client = StitchMoney::Client.new("fake_api_key")
  end

  def test_get_payment_request_status
    payment_request_id = "cGF5cmVxL2Q5M2ZhODRlLTQ0YTgtNGY5MC1hODMyLTNmMmI1NWUyZDkyZg=="

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

    stub_get_payment_request_status(query, payment_request_id)

    response = @client.graphql_query(query.strip, { paymentRequestId: payment_request_id })

    assert_equal payment_request_id, response["data"]["node"]["id"]
    assert_equal "KombuchaFizz", response["data"]["node"]["payerReference"]
    assert_equal "Joe-Fizz-01", response["data"]["node"]["beneficiaryReference"]
    assert_equal "https://secure.stitch.money/connect/payment-request/d93fa84e-44a8-4f90-a832-3f2b55e2d92f", response["data"]["node"]["url"]
    assert_equal "PaymentInitiationRequestCompleted", response["data"]["node"]["state"]["__typename"]
    assert_equal "2022-05-20T12:20:02.217Z", response["data"]["node"]["state"]["date"]
    assert_equal "1", response["data"]["node"]["state"]["amount"]["quantity"]
    assert_equal "ZAR", response["data"]["node"]["state"]["amount"]["currency"]
    assert_equal "62425239471", response["data"]["node"]["state"]["payer"]["accountNumber"]
    assert_equal "fnb", response["data"]["node"]["state"]["payer"]["bankId"]
  end

  private

  def stub_get_payment_request_status(query, payment_request_id)
    stub_request(:post, "https://api.stitch.money/graphql")
      .with(
        body: { query: query.strip, variables: { paymentRequestId: payment_request_id } }.to_json,
        headers: {
          'Authorization' => 'Bearer fake_api_key',
          'Content-Type' => 'application/json'
        }
      )
      .to_return(
        status: 200,
        body: <<~JSON
          {
            "data": {
              "node": {
                "id": "#{payment_request_id}",
                "payerReference": "KombuchaFizz",
                "beneficiaryReference": "Joe-Fizz-01",
                "url": "https://secure.stitch.money/connect/payment-request/d93fa84e-44a8-4f90-a832-3f2b55e2d92f",
                "state": {
                  "__typename": "PaymentInitiationRequestCompleted",
                  "date": "2022-05-20T12:20:02.217Z",
                  "amount": {
                    "quantity": "1",
                    "currency": "ZAR"
                  },
                  "payer": {
                    "accountNumber": "62425239471",
                    "bankId": "fnb"
                  }
                }
              }
            }
          }
        JSON
    )
  end
end
