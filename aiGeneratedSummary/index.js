import { DynamoDBClient } from '@aws-sdk/client-dynamodb'
import { DynamoDBDocumentClient, QueryCommand } from '@aws-sdk/lib-dynamodb'
import { GoogleGenerativeAI } from '@google/generative-ai'

const client = new DynamoDBClient({})
const doClient = DynamoDBDocumentClient.from(client)
const genAI = new GoogleGenerativeAI(process.env.API_KEY)

export const handler = async (event) => {
  if (!event.pathParameters || !event.pathParameters.movieName) {
    console.log('Missing movie name parameter')
    return {
      statusCode: 400,
      body: JSON.stringify({ message: 'Missing parameter' }),
    }
  }
  const movieName = decodeURIComponent(event.pathParameters.movieName)

  // Query the dynamoDb Table
  const params = {
    TableName: 'movies',
    IndexName: 'title-index',
    KeyConditionExpression: 'title = :title',
    ExpressionAttributeValues: {
      ':title': movieName,
    },
  }

  try {
    const { Items } = await doClient.send(new QueryCommand(params))

    if (Items.length === 0) {
      return {
        statusCode: 404,
        body: JSON.stringify({ message: 'Movie not found' }),
      }
    }

    const movie = Items[0]
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' })

    const prompt = `Generate a breif summary for the movie titled ${movie.title}, released in ${movie.releaseYear}.`

    const result = await model.generateContent(prompt)

    const summary = await result.response.text()

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        ...movie,
        generatedSummary: summary,
      }),
    }
  } catch (error) {
    console.log('Error Generation summary', error)
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Internal Server Error' }),
    }
  }
}
