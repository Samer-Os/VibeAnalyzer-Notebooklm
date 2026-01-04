# VIBEanalyzer MVP

## Project Structure

- `backend/`: Ruby on Rails API
- `frontend/`: React + TypeScript (To be initialized)

## Prerequisites

- Docker and Docker Compose
- Node.js (for frontend)

## Backend Setup (Rails)

Since Ruby is not installed locally, the backend is containerized.

1. **Generate the Rails App:**
   Since the project structure is manual, you need to generate the Rails boilerplate inside the container first.

   ```bash
   docker-compose run backend rails new . --force --database=postgresql --api
   ```

   _Note: This will overwrite the Gemfile. You may need to restore the provided Gemfile content or add the necessary gems back if they are lost._

2. **Build and Start the Backend:**

   ```bash
   docker-compose up --build
   ```

3. **Initialize the Database:**
   Open a new terminal and run:

   ```bash
   docker-compose run backend rails db:create db:migrate
   ```

   _Note: Since the Rails app was created manually, you might need to run `rails app:update:bin` or similar inside the container if startup fails, but the provided configuration should work for a basic API._

## Frontend Setup

1. Initialize the frontend (if not done):

   ```bash
   npm create vite@latest frontend -- --template react-ts
   cd frontend
   npm install
   ```

2. Run the frontend:
   ```bash
   npm run dev
   ```
