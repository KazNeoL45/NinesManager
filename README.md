# Nines Manager

A collaborative workspace and project management application offering powerful features with a focus on affordability and control. Built with Ruby on Rails 7.1 and Tailwind CSS.

## Features

- **Task Management** - Create, assign, prioritize, and track individual and recurring tasks
- **Kanban Boards** - Visual workflow management with drag-and-drop functionality
- **Document/Wiki** - Rich-text editor for creating project documentation and knowledge bases
- **User/Access Control** - Role-based permissions (Admin, Editor, Viewer)
- **Self-Hosting** - Clean deployment package for easy private installation

## Tech Stack

- Ruby 3.3.0
- Rails 7.1.6
- Tailwind CSS 4.1.16
- SQLite3 (development)
- Devise (authentication)
- Pundit (authorization)
- Hotwire (Turbo + Stimulus)

## Getting Started

### Prerequisites

- Ruby 3.3.0
- Bundler
- Node.js (for asset compilation)

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd ninesManager
```

2. Install dependencies
```bash
bundle install
```

3. Set up the database
```bash
bin/rails db:migrate
bin/rails db:seed
```

4. Start the development server
```bash
bin/dev
```

The application will be available at `http://localhost:3000`

### Test Users

After running `db:seed`, you can log in with these test accounts:

- **Admin**: admin@ninesmanager.com / password123
- **Editor**: editor@ninesmanager.com / password123
- **Viewer**: viewer@ninesmanager.com / password123

## User Roles

- **Admin** - Full access to create, edit, and delete projects, tasks, and documents
- **Editor** - Can create and edit projects, tasks, and documents
- **Viewer** - Read-only access to projects and resources

## Key Features

### Projects
- Create and manage multiple projects
- Add project members with specific roles
- Track project progress with tasks, boards, and documents

### Tasks
- Create tasks with priorities (Low, Medium, High, Urgent)
- Assign tasks to team members
- Set due dates
- Support for recurring tasks

### Kanban Boards
- Drag-and-drop task management
- Customizable columns
- Visual workflow tracking
- Automatically created with new projects (To Do, In Progress, Done)

### Documents
- Create and edit project documentation
- Markdown-style formatting
- Track document authors and timestamps

## Deployment

### Using Docker

A Dockerfile is included for containerized deployment:

```bash
docker build -t nines-manager .
docker run -p 3000:3000 nines-manager
```

### Standard Rails Deployment

The application can be deployed to any platform that supports Rails 7.1:

- Heroku
- AWS
- DigitalOcean
- Your own server

For production, consider:
- Switching from SQLite to PostgreSQL
- Setting up Redis for Action Cable
- Configuring environment variables via Rails credentials
- Setting up a proper web server (Nginx + Puma)

## Development

### Running Tests

```bash
bin/rails test
bin/rails test:system
```

### Code Style

The application follows Rails best practices with:
- No comments in code (self-documenting code preferred)
- Tailwind CSS for all styling
- Minimalist and intuitive UI design

## License

This project is available for use under standard software licensing terms.

## Support

For issues, questions, or contributions, please open an issue in the repository.
