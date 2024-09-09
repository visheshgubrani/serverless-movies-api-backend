import { DynamoDBClient } from '@aws-sdk/client-dynamodb'
import { DynamoDBDocumentClient, QueryCommand } from '@aws-sdk/lib-dynamodb'

const client = new DynamoDBClient({})
const doClient = DynamoDBDocumentClient.from(client)

export const handler = async (event) => {
  if (!event.pathParameters || !event.pathParameters.year) {
    console.log('Missing movie year')
    return {
      statusCode: 400,
      body: JSON.stringify({ message: 'Missing parameter' }),
    }
  }
  const year = decodeURIComponent(event.pathParameters.year)

  const params = {
    TableName: 'movies',
    IndexName: 'releaseYear-index',
    KeyConditionExpression: 'releaseYear = :releaseYear',
    ExpressionAttributeValues: {
      ':releaseYear': year,
    },
  }

  try {
    const { Items } = await doClient.send(new QueryCommand(params))

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(Items),
    }
  } catch (error) {
    console.log('Error fetching movies by year: ', error)
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Error fetching movies' }),
    }
  }
}
