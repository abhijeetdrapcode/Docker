# Use Node.js base image
FROM node:18

# Install PM2 globally
RUN npm install pm2 -g

# Set working directory
WORKDIR /app

# Install necessary tools and download code from S3
RUN apt-get update && apt-get install -y curl unzip && \
  curl -o /tmp/code.zip "https://abhijeettestingbucket22.s3.ap-south-1.amazonaws.com/learning-management-system2241.zip?response-content-disposition=inline&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Security-Token=IQoJb3JpZ2luX2VjECsaCmFwLXNvdXRoLTEiSDBGAiEA2fJOUop%2F6CW2%2F502Hpw97YL2NnzG%2B5N%2BPYngaOgFYroCIQD01GKkO%2BfEtf2GDF8KouE2Z2MqAKE%2FfPKcpySl5%2Baf5yrgAwgUEAEaDDUxNDgwMjE3NDk2NSIMgxAqULvwFci94y%2B3Kr0D5XtxJHDmKVndClJylR8AOf1Or1vJIWTv4g1hdMQKdK716sdIaxGh2B4aHZ%2FkQ8XX2t6M4vUGvHNlMi%2FaezMhyPEOKag%2BLnPMk%2BGLabKOjURcujL%2B7yJjHI%2BNTT0iyfnn69Culvm3CiGjRYb6CCny14Ww5jLnBV36p1rZX2gzqVo362Zbk26T45hXSwQ4pgivguwYApiau9BWVM0yHCspqwc4RgALPmazVQ32zdX9n6s0AwmVf5ams9QiY3Ez6geG7wG%2BCUqoTvLiQprpVnCQNvkxh6xSnj69e6aC4BoOxeOTq4jwzCmMnnArjnznkAq9AztVjYTnRhKEhCYRfvDmSezjZtTiVSuomaTn8YjxjncqTw2DZcPD7W2tXbC%2BcNUbri%2BFTx8rpjuSXuAk3G6gItWNHuGhezpQCXVQb2nHyM0rzjR%2FqpRZ%2FofyjmONSrG3%2BlG3nJMBoh2ch%2FNO4PrRgi87lQ4K674LhObHN9zwYLAXIXXmK63iWPywKiq6jwRHWYo6%2BGOK6fG6q%2BdxXGRwlOYFXutpk%2FnSFeW62cE5gonpRWu%2FSF2yaCbbpg2MmcVU%2F5IzJzObNo%2FmbiaBbDDZleS7BjrjAn0lkNrGvee2vckpk%2BDIVLhXsrrSGNx8x%2BawykCRg5icR22byp%2BBlQHY2Qbi%2F2t7i4%2Fn6z8yad0VKaXzxYiVfs0esX3p9pyNcyHrEgkQvFssZ%2BEF6pbhWr3IjY%2BKII21c3pZngbIbUg6HVkUfOMHHSNCQ8kbcl5JrQ2XASGSWOdX%2BYxipSyV1LTzvpp%2FPbJRu9BJiwrKK6YyKQadaTx5Pzu%2Fjmz19I%2FIHMQ94vyoZxm7Y2Ir8w5AB%2F%2B8QNrldwRY3OiuZ0HE%2BBzI3JD6BLb6vRqUgHLt1oUrZDP7r7TLKiKida4Jr8bDfTviej2DtSbhZZb2QM9m62jVaA3o6ocvOBdqRs3vmTOuR7nHEDcIDBysa%2FIi7j5oep5Mxi8r9QMKPgwDxQL2IpU2KpHR6ikQSyirMEHLrkFFDY2zTwbfS39AN7lBcVD5bypLAunIGt2CJ4UWNLN07n%2FVF%2BMZFc64ACOqXTk%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIAXPXEZZP2754MOKLM%2F20250104%2Fap-south-1%2Fs3%2Faws4_request&X-Amz-Date=20250104T103701Z&X-Amz-Expires=43200&X-Amz-SignedHeaders=host&X-Amz-Signature=4632cc8b47a6a5afdb7d139f6fe43873034ce707ec418c3fad0fe2ad1cf2bf5d" && \
  unzip /tmp/code.zip -d /app && \
  rm /tmp/code.zip

# Create a startup script
RUN echo '#!/bin/bash\n\
  set -e\n\
  \n\
  redis_password="your_redis_password_here"\n\
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
