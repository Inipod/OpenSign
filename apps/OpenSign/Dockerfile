FROM node:22.14.0

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm ci

COPY . .

ENV NODE_ENV=production
ENV GENERATE_SOURCEMAP=false

RUN npm run build \
  && sed -i '/<head>/a\<script src="/env.js"></script>' build/index.html \
  && chmod +x entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["./entrypoint.sh"]
CMD ["npm", "start"]
