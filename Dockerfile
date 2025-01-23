# Base Stage
FROM node:20-alpine AS base

WORKDIR /app

# Install required dependencies for Prisma
RUN apk add --no-cache libc6-compat openssl

COPY . .

ARG NEXT_PUBLIC_API_URI

RUN yarn install --network-timeout 1000000
RUN yarn build:shared
RUN yarn workspace @plunk/api build
RUN yarn workspace @plunk/dashboard build

# Generate Prisma Client for API workspace
RUN yarn workspace @plunk/api prisma generate

# Final Stage
FROM node:20-alpine

WORKDIR /app

# Install dependencies required for Prisma and other tools
RUN apk add --no-cache bash nginx libc6-compat openssl

# Copy application files from the base stage
COPY --from=base /app/packages/api/dist /app/packages/api/
COPY --from=base /app/packages/dashboard/.next /app/packages/dashboard/.next
COPY --from=base /app/packages/dashboard/public /app/packages/dashboard/public
COPY --from=base /app/node_modules /app/node_modules
COPY --from=base /app/node_modules/.prisma /app/node_modules/.prisma
COPY --from=base /app/packages/shared /app/packages/shared
COPY --from=base /app/prisma /app/prisma
COPY deployment/nginx.conf /etc/nginx/nginx.conf
COPY deployment/entry.sh deployment/replace-variables.sh /app/

# Ensure the scripts are executable
RUN chmod +x /app/entry.sh /app/replace-variables.sh

# Expose required ports
EXPOSE 3000 4000 5000

# Start the application
CMD ["sh", "/app/entry.sh"]
