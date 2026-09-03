FROM denoland/deno:2.9.5

WORKDIR /app

# Copy toan bo deploy_deno folder
COPY deploy_deno/ ./

# Cache dependencies
RUN deno cache main.ts

# Railway se set PORT tu dong
ENV PORT=8080

EXPOSE 8080

CMD ["deno", "run", "--allow-net", "--allow-env", "--allow-read", "main.ts"]
