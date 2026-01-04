# VIBEanalyzer

VIBEanalyzer is an AI-powered workspace that allows users to upload datasets (Excel/CSV), analyze them using Claude AI, and generate comprehensive reports.

## Project Structure

- `backend/`: Ruby on Rails API (Containerized)
- `frontend/`: React + TypeScript + Vite

## Prerequisites

- [Docker](https://www.docker.com/get-started) and Docker Compose
- [Node.js](https://nodejs.org/) (v18+ recommended) for local frontend development
- An [Anthropic API Key](https://console.anthropic.com/) (Claude)

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/Samer-Os/VibeAnalyzer-Notebooklm.git
cd VibeAnalyzer-Notebooklm
```

### 2. Backend Setup

The backend runs in a Docker container. You need to configure the environment variables before starting it.

1.  **Configure Environment Variables:**

    Open `docker-compose.yml` and locate the `backend` service. You need to provide your Anthropic API Key.

    You can either set it directly in the `docker-compose.yml` (not recommended for public repos) or create a `.env` file in the root directory and reference it.

    **Option A (Recommended): Create a `.env` file**

    Create a file named `.env` in the root directory:

    ```env
    ANTHROPIC_API_KEY=your_actual_api_key_here
    ```

    Then update `docker-compose.yml` to use this variable:

    ```yaml
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
    ```

    **Option B (Quick Start):**

    Replace the placeholder in `docker-compose.yml` directly:

    ```yaml
    environment:
      ANTHROPIC_API_KEY: sk-ant-api03-...
    ```

2.  **Build and Start the Backend:**

    ```bash
    docker-compose up --build
    ```

    The backend API will be available at `http://localhost:3000`.

3.  **Initialize the Database:**

    Open a new terminal window and run:

    ```bash
    docker-compose run backend rails db:create db:migrate
    ```

### 3. Frontend Setup

The frontend is a React application built with Vite.

1.  **Navigate to the frontend directory:**

    ```bash
    cd frontend
    ```

2.  **Install Dependencies:**

    ```bash
    npm install
    ```

3.  **Start the Development Server:**

    ```bash
    npm run dev
    ```

    The frontend will be available at `http://localhost:5173`.

## Usage

1.  Open your browser and go to `http://localhost:5173`.
2.  **Sign Up** for a new account.
3.  **Create a Project** from the dashboard.
4.  **Upload a Dataset** (Excel or CSV format).
5.  **Chat** with your data or generate a **Report**.

## Troubleshooting

- **Database Connection Issues:** Ensure the `db` service in Docker is healthy. You can check logs with `docker-compose logs db`.
- **API Key Errors:** If you see errors related to the Claude API, verify that your `ANTHROPIC_API_KEY` is correct and has credits.
- **CORS Errors:** Ensure the backend is running on port 3000 and the frontend on port 5173.

## License

[MIT](LICENSE)

2. Run the frontend:
   ```bash
   npm run dev
   ```
