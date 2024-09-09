import { DynamoDBClient, ScanCommand } from '@aws-sdk/client-dynamodb'
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb'
import { unmarshall } from '@aws-sdk/util-dynamodb'

const client = new DynamoDBClient({})
const doClient = DynamoDBDocumentClient.from(client)

export const handler = async (event) => {
  const params = {
    TableName: 'movies',
  }

  try {
    const { Items } = await doClient.send(new ScanCommand(params))

    const movies = Items.map((item) => unmarshall(item))

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(movies),
    }
  } catch (error) {
    console.log('Error Fetching Movies: ', error)
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ error: 'Unable to fetch movies' }),
    }
  }
}
