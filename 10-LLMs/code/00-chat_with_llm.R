#!

###
# chat with LLMs in the cloud
# 260304
###

if (!require("pacman")) install.packages("pacman"); library("pacman")
p_load(ellmer)
p_load(jsonlite)

# set up the API key

# chat with the LLM
chat = chat_openrouter(api_key = api_key,
                model = "qwen/qwen3.5-flash-02-23")

chat$chat("Hello, how are you? What is your name? What can you do?")

chat$chat("What did I ask before?")

# something more useful: structured input
system_prompt = "You are a monetary policy expert. You only respond to the exact question I ask and your response is valid JSON."

chat_ecb = chat_openrouter(api_key = api_key,
                model = "qwen/qwen3.5-flash-02-23",
                system_prompt = system_prompt)

response_ecb = chat_ecb$chat("What is the current interest rate set by the ECB?")

# parse the response as JSON
response_ecb_json = fromJSON(response_ecb)
str(response_ecb_json)


# something even more useful: structured output with a schema
system_prompt2 = "You are a monetary policy expert. You only respond to the exact question I ask and your response is valid JSON. The JSON response should have the following schema: { 'institution': [string], 'date': [string], 'interest_rate': [number] }."

chat_ecb2 = chat_openrouter(api_key = api_key,
                model = "google/gemini-3.1-flash-lite-preview", #"qwen/qwen3.5-flash-02-23",
                system_prompt = system_prompt2)

response_ecb2 = chat_ecb2$chat("What was the interest rate set by the ECB at the beginning of the years 2016 to 2026?")

# parse the response as JSON
response_ecb2_json = fromJSON(response_ecb2)
str(response_ecb2_json)

# evaluate ECB speeches on hawkish or dovish stance
# ...

# ecb_speeches = fread(....)..
system_prompt3 = "You are a monetary policy expert. You only respond to the exact question I ask and your response is valid JSON. The JSON response should have the following schema: { 'institution': [string], 'date': [string], 'dovishness': [-10 to +10] EXAMPLE: "..."}."

chat_ecb3 = chat_openrouter(api_key = api_key,
                model = "google/gemini-3.1-flash-lite-preview", #"qwen/qwen3.5-flash-02-23",
                system_prompt = system_prompt3)

data = list()
for (speech in ecb_speeches) {
  response_ecb3 = chat_ecb3$chat(paste0("Evaluate the following ECB speech on a scale from -10 (very dovish) to +10 (very hawkish): ", speech))
  # parse the response as JSON
  response_ecb3_json = fromJSON(response_ecb3)
  # store the response in a data frame
  # ...
    data = c(data, list(response_ecb3_json))
}
