/* Amplify Params - DO NOT EDIT
	API_SEEFORYOUAWS_GRAPHQLAPIENDPOINTOUTPUT
	API_SEEFORYOUAWS_GRAPHQLAPIIDOUTPUT
	ENV
	REGION
Amplify Params - DO NOT EDIT */const aws = require('aws-sdk');

const cognitoidentityserviceprovider = new aws.CognitoIdentityServiceProvider({
  apiVersion: '2016-04-18',
});

// NEW: Create a DynamoDB DocumentClient
const docClient = new aws.DynamoDB.DocumentClient();

/**
 * @type {import('@types/aws-lambda').PostConfirmationTriggerHandler}
 */
exports.handler = async (event) => {
  console.log('PostConfirmation trigger fired:', event);

  // Task 1: Add the user to the "Volunteers" group
  const addUserParams = {
    GroupName: 'Volunteers',
    UserPoolId: event.userPoolId,
    Username: event.userName,
  };

  // Task 2: Create the user's profile in the DynamoDB table
  // Get the table name from the environment variables provided by Amplify
  const tableName = process.env.API_SEEFORYOUAWS_VOLUNTEERTABLE_NAME;

  // Get user attributes from the Cognito event
  const userAttributes = event.request.userAttributes;

  const item = {
    id: userAttributes.sub, // The user's unique Cognito ID
   owner: event.userName, // 🔥 Change from userAttributes.sub to event.userName // For the @auth rule
    name: userAttributes.name,
    email: userAttributes.email,
    gender: userAttributes.gender,
    isAvailableNow: false, // Default availability to false
    availabilitySchedule: null, // No schedule set yet
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };

  const createVolunteerParams = {
    TableName: tableName,
    Item: item,
  };

  try {
    // Run both tasks at the same time for efficiency
    await Promise.all([
      cognitoidentityserviceprovider.adminAddUserToGroup(addUserParams).promise(),
      docClient.put(createVolunteerParams).promise(),
    ]);
    console.log(`SUCCESS: User ${event.userName} added to group and profile created.`);
  } catch (error) {
    console.log(`ERROR: Could not process user ${event.userName}`, error);
  }

  return event; // Always return the event
};