3. Error Handling opeai
In a production gem, you should consider a few "pro" additions:

Retry Logic: OpenAI occasionally has 500 errors.

Batching: If a user sends 1,000 sentences, you might hit an API limit. For a "small" gem, we can start with a single call, but document the limit.

Timeouts: Adding http.open_timeout and http.read_timeout prevents your gem from hanging the user's entire application if OpenAI is slow.

Next Step
Now that the adapter is solid, would you like to implement the Buffer Window?

This is the technique where we don't just compare Sentence A to Sentence B. Instead, we compare a "context window" of sentences to the next group. It significantly reduces "false positives" (splits that happen because a sentence is too short to have strong meaning). Should we add that logic to the Chunker?