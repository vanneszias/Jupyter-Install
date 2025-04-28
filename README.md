# 🚀 Jupyter Notebook Docker Environment

A streamlined solution for running Jupyter Lab in Docker with secure authentication, customizable configuration, and persistent storage.

## ✨ Features

- 🔐 **Secure Access**: Password-protected Jupyter Lab interface
- 👤 **Custom User**: Configurable username for the Jupyter environment
- 📁 **Persistent Storage**: Mount local directories to preserve your notebooks
- 🔌 **Port Flexibility**: Configurable port mapping for access
- 🐳 **Docker Compose**: Simple container management and configuration
- 🔄 **Auto-Restart**: Container automatically restarts unless explicitly stopped
- 📊 **JupyterLab Interface**: Modern, flexible interface for your notebooks

## 🔧 Prerequisites

- Docker Engine installed and running
- Python 3.x and pip
- Docker Compose (built-in with recent Docker Desktop, or installed separately)
- Basic terminal/command-line knowledge

## 🚀 Quick Start

1. **Clone or download this repository**
   ```bash
   git clone <repository-url>
   cd jupyter
   ```

2. **Make the script executable**
   ```bash
   chmod +x install.sh
   ```

3. **Run the setup script**
   ```bash
   ./install.sh
   ```

4. **Follow the interactive prompts**
   - Container name (default: jupyter-notebook)
   - Username (required)
   - Password (required, will be securely hashed)
   - Local notebooks directory (default: ./notebooks)
   - Port number (default: 8888)

## 📝 Configuration Details

### Container Configuration
The script generates two key files:

#### 🐳 Dockerfile
```dockerfile
FROM quay.io/jupyter/base-notebook:latest
```

#### 🔧 docker-compose.yml
Contains configurations for:
- Container name and restart policy
- Port mapping
- Volume mounting
- User settings
- Authentication
- Working directory

### 🔒 Security Features
- Password authentication required
- Secure password hashing using Jupyter's built-in mechanisms
- Custom username support
- Isolated Docker container environment

### 📂 Data Persistence
- Notebooks are stored in your specified local directory
- Data persists across container restarts
- Easy backup and version control of notebooks

## 🔍 Usage

1. **Access Jupyter Lab**
   - Open your browser and navigate to `http://localhost:<your-port>`
   - Enter your configured password

2. **Managing the Container**
   ```bash
   # Stop the container
   docker compose down

   # Start the container
   docker compose up -d

   # View logs
   docker logs jupyter-notebook

   # Restart the container
   docker compose restart
   ```

## 🛠️ Troubleshooting

### Common Issues and Solutions

1. **Port Conflicts**
   - Error: "Port is already in use"
   - Solution: Choose a different port during setup or manually edit docker-compose.yml

2. **Permission Issues**
   - Error: "Permission denied" for notebook directory
   - Solution: Ensure your user has write permissions to the mounted directory

3. **Container Not Starting**
   - Check logs: `docker logs jupyter-notebook`
   - Verify Docker daemon is running: `docker info`
   - Ensure ports are available: `nc -z localhost <port>`

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests.

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Based on the official Jupyter Docker Stacks
- Uses JupyterLab for an enhanced notebook experience

---
Made with ❤️ by [@vanneszias](https://github.com/vanneszias)
