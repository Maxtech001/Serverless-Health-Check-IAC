// Enable JavaScript strict mode for safer code execution
'use strict';

// Import AWS SDK and create a DynamoDB DocumentClient instance
const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

// Read DynamoDB table name from Lambda environment variables
const tableName = process.env.DDB_TABLE_NAME;

// Lambda entry point invoked by API Gateway
exports.handler = async (event) => {

  // Log the incoming request to CloudWatch for monitoring and troubleshooting
  console.log("Incoming event:", JSON.stringify(event));

  // Initialize an object to hold the parsed request body
  let bodyObj = {};

  // Parse the JSON request body if one is provided
  if (event.body) {
    try {
      bodyObj = JSON.parse(event.body);
    } catch (e) {

      // Return HTTP 400 if the request body contains invalid JSON
      return {
        statusCode: 400,
        body: JSON.stringify({ error: "Invalid JSON body" })
      };
    }
  }

  // Validate that the required "payload" field exists in the request
  if (!bodyObj.payload) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: "Missing required key: payload" })
    };
  }

  // Create the DynamoDB item containing request details
  const item = {
    id: Date.now().toString(),
    payload: bodyObj.payload,
    timestamp: new Date().toISOString()
  };

  // Save the request data into DynamoDB
  await dynamodb.put({
    TableName: tableName,
    Item: item
  }).promise();

  // Return a successful health check response to API Gateway
  return {
    statusCode: 200,
    body: JSON.stringify({
      status: "healthy",
      message: "Request processed and saved."
    })
  };
};
