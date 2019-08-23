#
# ping
#
resource "aws_api_gateway_model" "ping_request_model" {
  rest_api_id  = "${aws_api_gateway_rest_api.gw_api.id}"
  name = "PingRequest"
  description  = "ping request model"
  content_type = "application/json"

  schema = <<EOF
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "title": "PingRequest",
  "type": "object",
  "properties": {
    "preamble": {
      "type": "object",
      "properties": {
        "transactionUuid": {
          "description": "client generated transaction UUID",
          "type": "string",
          "format": "uuid"
        },
        "messageVersion": {
          "description": "defined by URL",
          "type": "integer"
        },
        "messageType": {
          "description": "defined by URL",
          "type": "string"
        }
      },
      "required": ["transactionUuid"]
    },
    "pingState": {"type": "boolean"}
  },
  "required": ["preamble", "pingState"]
}
EOF
}

resource "aws_api_gateway_model" "ping_response_model" {
  rest_api_id  = "${aws_api_gateway_rest_api.gw_api.id}"
  name = "PingResponse"
  description  = "ping response model"
  content_type = "application/json"

  schema = <<EOF
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "title": "PingResponse",
  "type": "object",
  "properties": {
    "preamble": {
      "type": "object",
      "properties": {
        "transactionUuid": {
          "description": "client generated transaction UUID",
          "type": "string",
          "format": "uuid"
        },
        "messageVersion": {
          "description": "defined by URL",
          "type": "integer"
        },
        "messageType": {
          "description": "defined by URL",
          "type": "string"
        }
      },
      "required": ["transactionUuid"]
    },
    "pingState": {"type": "boolean"}
  },
  "required": ["preamble", "pingState"]
}
EOF
}

resource "aws_api_gateway_resource" "ping_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.gw_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.gw_api.root_resource_id}"
  path_part   = "ping"
}

#######################
# Method Request
#######################

resource "aws_api_gateway_request_validator" "ping_validator" {
  name = "Ping Validator"
  rest_api_id = "${aws_api_gateway_rest_api.gw_api.id}"
  validate_request_body = true
  validate_request_parameters = true
}

resource "aws_api_gateway_method" "ping_post" {
  rest_api_id = "${aws_api_gateway_rest_api.gw_api.id}"
  resource_id = "${aws_api_gateway_resource.ping_resource.id}"
  http_method = "POST"
  authorization = "NONE"

  request_models = {"application/json" = "PingRequest"}
  request_validator_id = "${aws_api_gateway_request_validator.ping_validator.id}"
  depends_on = ["aws_api_gateway_model.ping_request_model"]
}

#######################
# Integration Request
#######################

resource "aws_api_gateway_integration" "ping_integration" {
  rest_api_id = "${aws_api_gateway_rest_api.gw_api.id}"
  resource_id = "${aws_api_gateway_method.ping_post.id}"
  http_method = "${aws_api_gateway_method.ping_post.http_method}"
  integration_http_method = "POST"
#  type = "AWS_PROXY"
  type = "AWS"
#  type = "MOCK"
  passthrough_behavior = "NEVER"
#  uri = "${aws_lambda_function.ping_lambda.invoke_arn}"
  uri = "arn:aws:apigateway:us-west-2:lambda:path/2015-03-31/functions/${aws_lambda_function.ping_lambda.arn}/invocations"

# xform tweak me
  request_templates = {
    "application/json" = <<EOF
{
  "statusCode": 200
}
EOF
  }

  depends_on = ["aws_api_gateway_method.ping_post"]
}

#######################
# Integration Response
#######################

#resource "aws_api_gateway_integration_response" "ping_integration_response" {
#  rest_api_id = "${aws_api_gateway_rest_api.gw_api.id}"
#  resource_id = "${aws_api_gateway_resource.ping_resource.id}"
#  http_method = "${aws_api_gateway_method.ping_post.http_method}"
#  status_code = "${aws_api_gateway_method_response.response_200.status_code}"

##  response_templates {
##    application/json = <<EOF
##"transactionUuid": "$input.params('transactionUuid')",
##"httpMethod": "$context.httpMethod",
##"deployStage": "$context.stage",
##"sourceIpAddress": "$context.identity.sourceIp",
##"resourcePath": "$context.resourcePath"
##EOF
##
##  response_templates = {
##    "application/json" = file("ping_response.template")
##  }
##}
#}

#######################
# Method Response
#######################

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = "${aws_api_gateway_rest_api.gw_api.id}"
  resource_id = "${aws_api_gateway_resource.ping_resource.id}"
  http_method = "${aws_api_gateway_method.ping_post.http_method}"
  status_code = "200"

  response_models = {"application/json" = "Empty"}
}

########

resource "aws_api_gateway_deployment" "gw_deploy" {
  rest_api_id = "${aws_api_gateway_rest_api.gw_api.id}"
  stage_name = "v01"

  depends_on = ["aws_api_gateway_integration.ping_integration"]
}

resource "aws_lambda_permission" "api-gateway-invoke-ping-lambda" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ping_lambda.arn
  principal = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  #source_arn = "${aws_api_gateway_deployment.gw_deploy.execution_arn}/stage/*/*"
  source_arn = "arn:aws:lambda:us-west-2:386926984321:function:pingx/*/*/*"


}

########

#resource "aws_lambda_permission" "ping_lambda_invoke" {
#  statement_id = "AllowAPIGatewayInvoke"
#  action = "lambda:InvokeFunction"
#  function_name = "${aws_lambda_function.ping_lambda.arn}"
#  principal = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
#  source_arn = "${aws_api_gateway_deployment.gw_deploy.execution_arn}/stage/*/*"
#}

###########

#resource "aws_lambda_permission" "api-gateway-invoke-ping-lambda" {
#  statement_id  = "AllowAPIGatewayInvoke"
#  action        = "lambda:InvokeFunction"
#  function_name = aws_lambda_function.ping_lambda.arn
#  principal     = "apigateway.amazonaws.com"
#
  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
#  source_arn = "${aws_api_gateway_deployment.gw_deploy.execution_arn}/stage/*/*"
#}