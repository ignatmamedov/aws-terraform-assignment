FROM node:20-alpine

WORKDIR /client
COPY . /client/

RUN npm install
CMD ["npm", "run", "dev", "--", "--host"]
