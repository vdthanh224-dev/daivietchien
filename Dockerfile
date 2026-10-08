FROM denoland/deno:latest

WORKDIR /app

# Copy server code
COPY server/ .

# Cache entry point
RUN deno cache main.ts

USER deno

# Render will provide the PORT env var; default to 10000
ENV PORT=10000
EXPOSE 10000

CMD ["run", "--allow-net", "--allow-env", "--allow-read", "main.ts"]
