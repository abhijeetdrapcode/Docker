# Use Node.js base image
FROM node:18

# Install PM2 globally
RUN npm install pm2 -g

# Set working directory
WORKDIR /app

# Install necessary tools and download code from S3
RUN apt-get update && apt-get install -y curl unzip && \
  curl -o /tmp/code.zip "https://abhijeettestingbucket22.s3.ap-south-1.amazonaws.com/loan-management-system3443.zip?response-content-disposition=inline&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEPz%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaCmFwLXNvdXRoLTEiRjBEAiBABV4uAhG%2BqRX7ISlm2hiF%2BKzA%2F%2FPMu1NkJytV%2BYn2TAIgTGDF5gGooJaJao5kRf5e6zhtcT4CxB9pn8QfOFaKyyEq6QMI1f%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FARABGgw1MTQ4MDIxNzQ5NjUiDOoX2LOXy5BwVXVWTyq9A%2B4rL27%2FYx%2BbEErzc3aCEEaXyJN0xM%2Fv%2B1Neol7DysmZygSHNCfI%2BZQTHlkhPJfWiQi90UB6mQWQpcuHN1oGPghUtQCRv5Xzgy3BJyhFUJLbfSRZ8kkloCdkdkWazCT4RaQgH6BYJ9hl0FitbhcwisLi79t9%2FN3pelffdBdhLYUZRXxL0dQMtXTndpIHK390oVoDJTEpBPB%2F6IMABMa2InNZGh7qPPPjTt4W5hY0epX9ApzNL16ay6Rf9U6WDval%2ByCywB9zI6DUQQI5I3ZGmHwgHO8ruF7kGjBnEJlGRaMQzRSNx7DnSX2i%2FEjjGGg3AjNW1zBwFfVTtDxNTeU5GrGz1HYcdx1GJ9lJXGmnPctr5pWo3oiTOy8QmlRxGbKVzcUrPLhauRRQvutAIzhT%2FKa%2F393HhaGbksdOuz5z1j5qg2mWGcFrUZeD7iWUrOQbDltj9%2BtIe2fVlZL7CTeKKjvXSYVZyreaOVm3KPqf%2Fkz1jvbLVN5JCcJNSeOvWHiik8KZCATYIM61FBdsTKDFgGfX8HMrlvM7MVnxp6QfPA%2FU7j%2B5B9RX4RuWJSohM69ic0YFoLUxqkmg%2Be5mnLYwqYPZuwY65QJoxvHgEpaTr34gEsRFqP%2BelrHSOdoVjytouUPyYjhRCuQYQDRHhZKkJl6u6neDqlh67gXFXyvbeWBGr6mzAg22Fjxc8zMOX2J30Xg59riDlB%2BZp6GNUhcjmB2JO9ul%2FMWi1ZmaBw%2FHWw%2By%2FZfrkhcHi8yskb3EfV7sAQ9nAzzVJ3ns8qZ5ku9mZTVuNCjO6Xpcc%2F3WnMT0CKKKehODb48FolXkwWsEHiquUlI6GylKFbGXfFatlE%2FBu2yQsb7ivad%2BXHnbpJKowDTnJ39j1InraBDhNZhpzWcauFIx9atE%2F5MNlc%2Bs1lI7Le4EFI11XZH%2FHdWFroxy%2FOodajeKhuvEITDFFVtYeW%2FnQ6XimAfYSSz1ePR91p1GJCCiO2TIbnb4owpM%2FFdqs6WVVQWbSYXDcsPecyQRzUXjohTi5%2FTB1xc0jfnhQTFwk5%2FmhD8I7nsM6z40erypeBOODWGYYYrHcKyFBuQ%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIAXPXEZZP2VYYZOF5N%2F20250102%2Fap-south-1%2Fs3%2Faws4_request&X-Amz-Date=20250102T122045Z&X-Amz-Expires=43200&X-Amz-SignedHeaders=host&X-Amz-Signature=e6e095840dbb4f07402dcaef3985b44e1455125ddd561fb6542d9024d2e4d400" && \
  unzip /tmp/code.zip -d /app && \
  rm /tmp/code.zip

# Create a startup script
RUN echo '#!/bin/bash\n\
  set -e\n\
  \n\
  redis_password="nextDefault"\n\
  \n\
  # Navigate to the only folder in /app directory\n\
  folder=$(find /app -mindepth 1 -maxdepth 1 -type d | head -n 1)\n\
  cd "$folder" || exit 1\n\
  \n\
  # Print the current working directory\n\
  echo "Current working directory: $(pwd)"\n\
  \n\
  # Function to update .env files\n\
  update_env_file() {\n\
  local env_file=$1\n\
  sed -i "s|REDIS_HOST=.*|REDIS_HOST=127.0.0.1|" "$env_file"\n\
  sed -i "s|REDIS_PORT=.*|REDIS_PORT=6379|" "$env_file"\n\
  sed -i "s|REDIS_PASSWORD=.*|REDIS_PASSWORD=$redis_password|" "$env_file"\n\
  sed -i "s|BUILD_FOLDER=.*|BUILD_FOLDER=$folder/|" "$env_file"\n\
  }\n\
  \n\
  # Update .env for exchange-engine before installation\n\
  if [ -d "./exchange-engine" ]; then\n\
  if [ -f "./exchange-engine/.env" ]; then\n\
  echo "Updating .env for exchange-engine..."\n\
  update_env_file "./exchange-engine/.env"\n\
  else\n\
  echo "Warning: .env file not found in exchange-engine directory."\n\
  fi\n\
  \n\
  cd exchange-engine\n\
  echo "Installing and building exchange-engine..."\n\
  npm install && npm run build\n\
  pm2 start ecosystem.config.js || echo "PM2 start failed for exchange-engine"\n\
  cd ..\n\
  else\n\
  echo "Warning: exchange-engine directory not found!"\n\
  fi\n\
  \n\
  # Update .env for exchange-surface before installation\n\
  if [ -d "./exchange-surface" ]; then\n\
  if [ -f "./exchange-surface/.env" ]; then\n\
  echo "Updating .env for exchange-surface..."\n\
  update_env_file "./exchange-surface/.env"\n\
  else\n\
  echo "Warning: .env file not found in exchange-surface directory."\n\
  fi\n\
  \n\
  cd exchange-surface\n\
  echo "Installing and building exchange-surface..."\n\
  npm install && npm run publish\n\
  pm2 start ecosystem.config.js || echo "PM2 start failed for exchange-surface"\n\
  cd ..\n\
  else\n\
  echo "Warning: exchange-surface directory not found!"\n\
  fi\n\
  \n\
  # Show logs\n\
  pm2 logs' > /app/start-apps.sh

# Make the script executable
RUN chmod +x /app/start-apps.sh

# Expose necessary ports
EXPOSE 8080 5000

# Set the entry point to the shell script
CMD ["/bin/bash", "/app/start-apps.sh"]
