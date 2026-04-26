# Callagent - A project at the Hackerton Kassel 2026
Callagent is an ai agent for olderly person which need help in their houshold using their conventional phone and a phonecall with speach.
An internal monitoring via the frontend is for administration.




## Installation guide
The project has an architecture depending on code of bot and frontend and external services. Install this folder bot and frontend.


## Running with Docker

The Installation depends on docker-container which are in the folders frontend, api and agent.

After installation bot and frontend, set environment variables and run:
copy the `.env.example` file and edit it for convenience.
For bot:
- Large-Language-Model: LLM is based on Google API
- Speech to text is provided bz Deepgram api key
- Text to Speech is provided by cartisan api key
- For twilio configuration, we provide twilio account sid and twilio auth token


## Running Database / PostgreSQL Mode

 Install and runn via docker compose file.

## Version Control

For developing and version control we used GIT

## Testing

Using GIT Actions for Testing.


## Deploy

There is a CI/CD Pipeline width Jenkins to run till diployment automatically. Use Jenkins-File in main folder.


## Accessibility

BCAG criteria will be checked in frontend (not finished)


## Data Privacy

The Phonecall asks the user before phonecoll for a commitment to record the call (not finished) 
